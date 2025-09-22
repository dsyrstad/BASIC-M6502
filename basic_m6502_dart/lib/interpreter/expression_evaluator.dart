import 'dart:math' as dart_math;

import '../memory/memory.dart';
import '../memory/variables.dart';
import 'tokenizer.dart';

/// Expression evaluator implementing FRMEVL algorithm from Microsoft BASIC.
///
/// This evaluates arithmetic and string expressions using an operator
/// precedence parser with a stack-based approach. Closely matches the
/// original BASIC implementation.
class ExpressionEvaluator {
  final Memory memory;
  final VariableStorage variables;
  final Tokenizer tokenizer;

  /// Operator precedence table (higher number = higher precedence)
  static const Map<int, int> _operatorPrecedence = {
    Tokenizer.orToken: 1,
    Tokenizer.andToken: 2,
    Tokenizer.notToken: 3,
    Tokenizer.equalToken: 4,
    Tokenizer.lessToken: 4,
    Tokenizer.greaterToken: 4,
    Tokenizer.plusToken: 5,
    Tokenizer.minusToken: 5,
    Tokenizer.multiplyToken: 6,
    Tokenizer.divideToken: 6,
    Tokenizer.powerToken: 7,
  };

  /// Expression evaluation stack
  final List<StackEntry> _stack = [];

  /// Current position in expression
  int _position = 0;

  /// Current expression being evaluated
  List<int> _expression = [];

  ExpressionEvaluator(this.memory, this.variables, this.tokenizer);

  /// Evaluate an expression starting at current position (FRMEVL equivalent)
  ExpressionResult evaluateExpression(List<int> tokens, int startPos) {
    _expression = tokens;
    _position = startPos;
    _stack.clear();

    // Push dummy operator with lowest precedence to start
    _stack.add(StackEntry(type: StackEntryType.operator, precedence: 0));

    // Parse primary expression (number, variable, function, or parenthesized expr)
    _parsePrimary();

    // Continue parsing operators and operands
    while (_position < _expression.length) {
      _skipSpaces();
      if (_position >= _expression.length) break;

      final token = _getCurrentToken();

      // Check if this is an operator
      if (_isOperator(token)) {
        _handleOperator(token);
      } else {
        // Not an operator, end of expression
        break;
      }
    }

    // Apply remaining operators
    while (_stack.length > 2) {
      if (_stack[_stack.length - 2].type == StackEntryType.operator) {
        _applyTopOperator();
      } else {
        break;
      }
    }

    // Result should be the last item on stack (after the dummy operator)
    if (_stack.length < 2 || _stack.last.type != StackEntryType.value) {
      throw ExpressionException('Invalid expression result');
    }

    final result = _stack.last.value!;
    final endPos = _position;

    return ExpressionResult(result, endPos);
  }

  /// Parse primary expression (number, variable, function call, or parentheses)
  void _parsePrimary() {
    _skipSpaces();

    if (_position >= _expression.length) {
      throw ExpressionException('SYNTAX ERROR - Missing operand');
    }

    final token = _getCurrentToken();

    if (token == 40) { // Left parenthesis
      _parseParentheses();
    } else if (_isDigit(token) || token == 46) { // Number (digit or decimal point)
      _parseNumber();
    } else if (token == 34) { // String literal
      _parseStringLiteral();
    } else if (_isLetter(token)) { // Variable or function
      _parseVariableOrFunction();
    } else if (tokenizer.isSingleArgFunction(token)) { // Built-in function
      _parseBuiltinFunction(token);
    } else if (token == Tokenizer.minusToken) { // Unary minus
      _parseUnaryMinus();
    } else if (token == Tokenizer.plusToken) { // Unary plus
      _parseUnaryPlus();
    } else {
      throw ExpressionException('SYNTAX ERROR - Invalid expression');
    }
  }

  /// Parse parenthesized expression
  void _parseParentheses() {
    _advance(); // Skip opening parenthesis

    // Recursively evaluate the sub-expression
    final result = evaluateExpression(_expression, _position);
    _position = result.endPosition;

    _skipSpaces();
    if (_position >= _expression.length || _getCurrentToken() != 41) { // Right parenthesis
      throw ExpressionException('SYNTAX ERROR - Missing )');
    }
    _advance(); // Skip closing parenthesis

    _stack.add(StackEntry(type: StackEntryType.value, value: result.value));
  }

  /// Parse numeric constant
  void _parseNumber() {
    final startPos = _position;
    var hasDecimalPoint = false;

    // Collect consecutive digits and decimal point
    while (_position < _expression.length) {
      final token = _getCurrentToken();
      if (_isDigit(token)) {
        _advance();
      } else if (token == 46 && !hasDecimalPoint) { // Decimal point
        hasDecimalPoint = true;
        _advance();
      } else {
        // Not a digit or decimal point, stop parsing number
        break;
      }
    }

    // Convert collected bytes to string and parse
    final numberBytes = _expression.sublist(startPos, _position);
    final numberStr = String.fromCharCodes(numberBytes);
    final value = double.tryParse(numberStr);

    if (value == null) {
      throw ExpressionException('SYNTAX ERROR - Invalid number: $numberStr');
    }

    _stack.add(StackEntry(type: StackEntryType.value, value: NumericValue(value)));
  }

  /// Parse string literal
  void _parseStringLiteral() {
    _advance(); // Skip opening quote

    final buffer = StringBuffer();
    while (_position < _expression.length) {
      final token = _getCurrentToken();
      if (token == 34) { // Closing quote
        _advance();
        break;
      }
      buffer.writeCharCode(token);
      _advance();
    }

    _stack.add(StackEntry(type: StackEntryType.value, value: StringValue(buffer.toString())));
  }

  /// Parse variable reference or function call
  void _parseVariableOrFunction() {
    final nameStart = _position;

    // Collect variable name (up to 2 characters)
    while (_position < _expression.length &&
           _position - nameStart < 2 &&
           (_isLetter(_getCurrentToken()) || _isDigit(_getCurrentToken()))) {
      _advance();
    }

    // Check for string variable suffix
    if (_position < _expression.length && _getCurrentToken() == 36) { // '$'
      _advance();
    }

    final nameBytes = _expression.sublist(nameStart, _position);
    final varName = String.fromCharCodes(nameBytes);

    // Get variable value
    final value = variables.getVariable(varName);
    _stack.add(StackEntry(type: StackEntryType.value, value: value));
  }

  /// Parse built-in function call
  void _parseBuiltinFunction(int functionToken) {
    _advance(); // Skip function token

    _skipSpaces();
    if (_position >= _expression.length || _getCurrentToken() != 40) { // Left parenthesis
      throw ExpressionException('SYNTAX ERROR - Missing ( after function');
    }

    _advance(); // Skip opening parenthesis

    // Evaluate argument
    final argResult = evaluateExpression(_expression, _position);
    _position = argResult.endPosition;

    _skipSpaces();
    if (_position >= _expression.length || _getCurrentToken() != 41) { // Right parenthesis
      throw ExpressionException('SYNTAX ERROR - Missing ) after function');
    }
    _advance(); // Skip closing parenthesis

    // Apply function
    final result = _applyFunction(functionToken, argResult.value);
    _stack.add(StackEntry(type: StackEntryType.value, value: result));
  }

  /// Parse unary minus
  void _parseUnaryMinus() {
    _advance(); // Skip minus token
    _parsePrimary(); // Parse operand

    if (_stack.isEmpty || _stack.last.type != StackEntryType.value) {
      throw ExpressionException('SYNTAX ERROR - Invalid unary minus');
    }

    final operand = _stack.removeLast().value!;
    if (operand is NumericValue) {
      _stack.add(StackEntry(type: StackEntryType.value, value: NumericValue(-operand.value)));
    } else {
      throw ExpressionException('TYPE MISMATCH - Cannot negate string');
    }
  }

  /// Parse unary plus
  void _parseUnaryPlus() {
    _advance(); // Skip plus token
    _parsePrimary(); // Parse operand

    // Unary plus doesn't change the value, just ensure it's numeric
    if (_stack.isEmpty || _stack.last.type != StackEntryType.value) {
      throw ExpressionException('SYNTAX ERROR - Invalid unary plus');
    }

    final operand = _stack.last.value!;
    if (operand is! NumericValue) {
      throw ExpressionException('TYPE MISMATCH - Cannot apply unary plus to string');
    }
  }

  /// Handle operator token
  void _handleOperator(int operatorToken) {
    final precedence = _operatorPrecedence[operatorToken];
    if (precedence == null) {
      throw ExpressionException('SYNTAX ERROR - Unknown operator: $operatorToken');
    }

    // Apply operators with higher or equal precedence
    while (_stack.length >= 3 &&
           _stack[_stack.length - 2].type == StackEntryType.operator &&
           _stack[_stack.length - 2].precedence >= precedence) {
      _applyTopOperator();
    }

    // Push new operator
    _stack.add(StackEntry(
      type: StackEntryType.operator,
      operator: operatorToken,
      precedence: precedence
    ));

    _advance(); // Skip operator token
    _parsePrimary(); // Parse next operand
  }

  /// Apply the top operator on the stack
  void _applyTopOperator() {
    if (_stack.length < 3) {
      throw ExpressionException('SYNTAX ERROR - Missing operand');
    }

    // Stack should have: value, operator, value (from bottom to top)
    final right = _stack.removeLast();
    final operator = _stack.removeLast();
    final left = _stack.removeLast();

    if (right.type != StackEntryType.value ||
        operator.type != StackEntryType.operator ||
        left.type != StackEntryType.value) {
      throw ExpressionException('SYNTAX ERROR - Invalid stack state');
    }

    final result = _applyBinaryOperator(operator.operator!, left.value!, right.value!);
    _stack.add(StackEntry(type: StackEntryType.value, value: result));
  }

  /// Apply a binary operator to two operands
  VariableValue _applyBinaryOperator(int operator, VariableValue left, VariableValue right) {
    switch (operator) {
      case Tokenizer.plusToken:
        if (left is NumericValue && right is NumericValue) {
          return NumericValue(left.value + right.value);
        } else if (left is StringValue && right is StringValue) {
          return StringValue(left.value + right.value);
        }
        throw ExpressionException('TYPE MISMATCH');

      case Tokenizer.minusToken:
        if (left is NumericValue && right is NumericValue) {
          return NumericValue(left.value - right.value);
        }
        throw ExpressionException('TYPE MISMATCH');

      case Tokenizer.multiplyToken:
        if (left is NumericValue && right is NumericValue) {
          return NumericValue(left.value * right.value);
        }
        throw ExpressionException('TYPE MISMATCH');

      case Tokenizer.divideToken:
        if (left is NumericValue && right is NumericValue) {
          if (right.value == 0) {
            throw ExpressionException('DIVISION BY ZERO');
          }
          return NumericValue(left.value / right.value);
        }
        throw ExpressionException('TYPE MISMATCH');

      case Tokenizer.powerToken:
        if (left is NumericValue && right is NumericValue) {
          return NumericValue(_power(left.value, right.value));
        }
        throw ExpressionException('TYPE MISMATCH');

      case Tokenizer.equalToken:
        return NumericValue(_compare(left, right) == 0 ? 1.0 : 0.0);

      case Tokenizer.lessToken:
        return NumericValue(_compare(left, right) < 0 ? 1.0 : 0.0);

      case Tokenizer.greaterToken:
        return NumericValue(_compare(left, right) > 0 ? 1.0 : 0.0);

      default:
        throw ExpressionException('SYNTAX ERROR - Unknown operator');
    }
  }

  /// Apply a function to an argument
  VariableValue _applyFunction(int functionToken, VariableValue argument) {
    switch (functionToken) {
      case Tokenizer.absToken:
        if (argument is NumericValue) {
          return NumericValue(argument.value.abs());
        }
        throw ExpressionException('TYPE MISMATCH');

      case Tokenizer.intToken:
        if (argument is NumericValue) {
          return NumericValue(argument.value.truncateToDouble());
        }
        throw ExpressionException('TYPE MISMATCH');

      case Tokenizer.sgnToken:
        if (argument is NumericValue) {
          return NumericValue(argument.value.sign);
        }
        throw ExpressionException('TYPE MISMATCH');

      default:
        throw ExpressionException('FUNCTION NOT IMPLEMENTED: ${tokenizer.getTokenName(functionToken)}');
    }
  }

  /// Power function
  double _power(double base, double exponent) {
    if (base == 0 && exponent < 0) {
      throw ExpressionException('ILLEGAL QUANTITY');
    }
    return base == 0 ? 0 : dart_math.pow(base, exponent).toDouble();
  }

  /// Compare two values
  int _compare(VariableValue left, VariableValue right) {
    if (left is NumericValue && right is NumericValue) {
      return left.value.compareTo(right.value);
    } else if (left is StringValue && right is StringValue) {
      return left.value.compareTo(right.value);
    } else {
      throw ExpressionException('TYPE MISMATCH');
    }
  }

  /// Check if token is an operator
  bool _isOperator(int token) {
    return _operatorPrecedence.containsKey(token) || tokenizer.isOperator(token);
  }

  /// Check if character is a digit
  bool _isDigit(int ch) {
    return ch >= 48 && ch <= 57; // ASCII '0' to '9'
  }

  /// Check if character is a letter
  bool _isLetter(int ch) {
    return (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122); // A-Z or a-z
  }

  /// Get current token
  int _getCurrentToken() {
    if (_position >= _expression.length) {
      return 0;
    }
    return _expression[_position];
  }

  /// Advance to next token
  void _advance() {
    _position++;
  }

  /// Skip spaces
  void _skipSpaces() {
    while (_position < _expression.length && _getCurrentToken() == 32) { // ASCII space
      _advance();
    }
  }
}

/// Stack entry for expression evaluation
class StackEntry {
  final StackEntryType type;
  final VariableValue? value;
  final int? operator;
  final int precedence;

  StackEntry({
    required this.type,
    this.value,
    this.operator,
    this.precedence = 0,
  });
}

/// Type of stack entry
enum StackEntryType {
  value,    // Operand value
  operator, // Operator
}

/// Result of expression evaluation
class ExpressionResult {
  final VariableValue value;
  final int endPosition;

  ExpressionResult(this.value, this.endPosition);
}

/// Exception thrown during expression evaluation
class ExpressionException implements Exception {
  final String message;

  ExpressionException(this.message);

  @override
  String toString() => 'ExpressionException: $message';
}


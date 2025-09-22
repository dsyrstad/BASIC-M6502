import '../memory/memory.dart';
import '../memory/variables.dart';
import 'tokenizer.dart';
import 'expression_evaluator.dart';

/// Main BASIC interpreter equivalent to NEWSTT in original code.
///
/// Handles the main execution loop, statement dispatching, and
/// text pointer management. This is the core of the BASIC interpreter.
class Interpreter {
  final Memory memory;
  final Tokenizer tokenizer;
  final VariableStorage variables;
  final ExpressionEvaluator expressionEvaluator;

  /// Current execution state
  ExecutionState _state = ExecutionState.immediate;

  /// Text pointer - current position in tokenized line
  int _textPointer = 0;

  /// Current tokenized line being executed
  List<int> _currentLine = [];

  /// Direct mode input buffer
  String _directModeInput = '';

  /// Program mode flag
  bool get isInProgramMode => _state == ExecutionState.program;

  /// Direct mode flag
  bool get isInDirectMode => _state == ExecutionState.immediate;

  Interpreter(this.memory, this.tokenizer, this.variables, this.expressionEvaluator);

  /// Main interpreter loop (NEWSTT equivalent)
  void mainLoop() {
    while (true) {
      try {
        // Check execution state
        if (_state == ExecutionState.immediate) {
          _handleDirectMode();
        } else if (_state == ExecutionState.program) {
          _executeNextStatement();
        } else if (_state == ExecutionState.stopped) {
          break;
        }
      } catch (e) {
        _handleError(e);
      }
    }
  }

  /// Handle direct (immediate) mode execution
  void _handleDirectMode() {
    // In direct mode, we wait for user input and execute immediately
    // This would normally read from console, but for now we'll simulate
    print('READY.');
    // TODO: Read from actual console input
    // For now, just stop
    _state = ExecutionState.stopped;
  }

  /// Execute the next statement in program mode
  void _executeNextStatement() {
    // Get current character (CHRGET equivalent)
    int currentChar = _getCurrentChar();

    // Skip spaces
    while (currentChar == 32) {
      _advanceTextPointer();
      currentChar = _getCurrentChar();
    }

    // Check for end of line or end of statement
    if (currentChar == 0 || currentChar == 58) { // null or colon
      if (currentChar == 58) {
        _advanceTextPointer(); // Skip the colon
      }
      // If end of line, advance to next line
      if (currentChar == 0) {
        _advanceToNextLine();
      }
      return;
    }

    // Check for line number (direct assignment)
    if (_isDigit(currentChar)) {
      _handleLineNumberEntry();
      return;
    }

    // Dispatch statement based on token
    _dispatchStatement(currentChar);
  }

  /// Get current character at text pointer (CHRGET equivalent)
  int _getCurrentChar() {
    if (_textPointer >= _currentLine.length) {
      return 0; // End of line
    }
    return _currentLine[_textPointer];
  }

  /// Advance text pointer and return new character (CHRGOT equivalent)
  int _advanceTextPointer() {
    _textPointer++;
    return _getCurrentChar();
  }

  /// Check if character is a digit
  bool _isDigit(int ch) {
    return ch >= 48 && ch <= 57; // ASCII '0' to '9'
  }

  /// Check if character is a letter
  bool _isLetter(int ch) {
    return (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122); // A-Z or a-z
  }

  /// Skip spaces at current text pointer
  void _skipSpaces() {
    while (_textPointer < _currentLine.length && _getCurrentChar() == 32) { // ASCII space
      _advanceTextPointer();
    }
  }

  /// Parse a variable name at current text pointer
  String _parseVariableName() {
    _skipSpaces();

    if (_textPointer >= _currentLine.length) {
      throw InterpreterException('SYNTAX ERROR - Missing variable name');
    }

    final nameStart = _textPointer;
    final firstChar = _getCurrentChar();

    // First character must be a letter
    if (!_isLetter(firstChar)) {
      throw InterpreterException('SYNTAX ERROR - Variable must start with letter');
    }

    _advanceTextPointer();

    // Second character can be letter or digit
    if (_textPointer < _currentLine.length) {
      final secondChar = _getCurrentChar();
      if (_isLetter(secondChar) || _isDigit(secondChar)) {
        _advanceTextPointer();
      }
    }

    // Check for string variable suffix '$'
    if (_textPointer < _currentLine.length && _getCurrentChar() == 36) { // '$'
      _advanceTextPointer();
    }

    // Check for array variable suffix '(' (we'll handle this later)
    if (_textPointer < _currentLine.length && _getCurrentChar() == 40) { // '('
      throw InterpreterException('ARRAY NOT YET IMPLEMENTED');
    }

    final nameBytes = _currentLine.sublist(nameStart, _textPointer);
    return String.fromCharCodes(nameBytes);
  }

  /// Handle line number entry (program editing)
  void _handleLineNumberEntry() {
    // Parse line number
    int lineNumber = 0;
    int currentChar = _getCurrentChar();

    while (_isDigit(currentChar)) {
      lineNumber = lineNumber * 10 + (currentChar - 48);
      currentChar = _advanceTextPointer();
    }

    // Skip spaces after line number
    while (currentChar == 32) {
      currentChar = _advanceTextPointer();
    }

    if (currentChar == 0) {
      // Line number only - delete line
      _deleteLine(lineNumber);
    } else {
      // Line number with content - store line
      _storeLine(lineNumber, _getRemainingLine());
    }
  }

  /// Get remaining content of current line
  List<int> _getRemainingLine() {
    if (_textPointer >= _currentLine.length) {
      return [];
    }
    return _currentLine.sublist(_textPointer);
  }

  /// Store a line in the program
  void _storeLine(int lineNumber, List<int> content) {
    // TODO: Implement program storage
    print('Storing line $lineNumber: ${tokenizer.detokenize(content)}');
  }

  /// Delete a line from the program
  void _deleteLine(int lineNumber) {
    // TODO: Implement line deletion
    print('Deleting line $lineNumber');
  }

  /// Advance to next program line
  void _advanceToNextLine() {
    // TODO: Implement program line advancement
    // For now, just stop
    _state = ExecutionState.stopped;
  }

  /// Dispatch statement execution based on token
  void _dispatchStatement(int token) {
    // Check if it's a statement token
    if (tokenizer.isStatement(token)) {
      _executeStatement(token);
    } else {
      // Not a statement token - might be assignment or expression
      _handleAssignmentOrExpression();
    }
  }

  /// Execute a specific statement
  void _executeStatement(int token) {
    _advanceTextPointer(); // Skip the statement token

    switch (token) {
      case Tokenizer.endToken:
        _executeEnd();
        break;
      case Tokenizer.remToken:
        _executeRem();
        break;
      case Tokenizer.printToken:
        _executePrint();
        break;
      case Tokenizer.runToken:
        _executeRun();
        break;
      case Tokenizer.listToken:
        _executeList();
        break;
      case Tokenizer.newToken:
        _executeNew();
        break;
      case Tokenizer.gotoToken:
        _executeGoto();
        break;
      case Tokenizer.letToken:
        _executeLet();
        break;
      default:
        throw InterpreterException('SYNTAX ERROR - Unknown statement: ${tokenizer.getTokenName(token)}');
    }
  }

  /// Handle assignment or expression evaluation
  void _handleAssignmentOrExpression() {
    // Try to parse as variable assignment (implicit LET)
    if (_isLetter(_getCurrentChar())) {
      final savedPosition = _textPointer;

      try {
        // Try to parse variable name
        final variableName = _parseVariableName();

        // Skip spaces and check for equals sign
        _skipSpaces();
        if (_getCurrentChar() == Tokenizer.equalToken) { // Equals token
          // This is an assignment - execute like LET
          _advanceTextPointer(); // Skip equals sign

          // Evaluate the expression on the right side
          final result = expressionEvaluator.evaluateExpression(_currentLine, _textPointer);
          _textPointer = result.endPosition;

          // Store the value in the variable
          variables.setVariable(variableName, result.value);
          return;
        }
      } catch (e) {
        // Not a valid assignment, restore position and fall through
        _textPointer = savedPosition;
      }
    }

    // Not an assignment - evaluate as expression (for direct mode)
    try {
      final result = expressionEvaluator.evaluateExpression(_currentLine, _textPointer);
      _textPointer = result.endPosition;

      // In direct mode, print the result
      if (_state == ExecutionState.immediate) {
        print(result.value.toString());
      }
    } catch (e) {
      throw InterpreterException('SYNTAX ERROR - Invalid statement');
    }
  }

  /// Execute END statement
  void _executeEnd() {
    _state = ExecutionState.stopped;
    print('END');
  }

  /// Execute REM statement (comment)
  void _executeRem() {
    // Skip to end of line - everything after REM is a comment
    _textPointer = _currentLine.length;
  }

  /// Execute PRINT statement (basic version)
  void _executePrint() {
    // TODO: Implement full PRINT with expressions
    // For now, just print remaining text as literal
    final remaining = _getRemainingLine();
    final text = tokenizer.detokenize(remaining);
    print(text);
    _textPointer = _currentLine.length; // Move to end of line
  }

  /// Execute RUN statement
  void _executeRun() {
    // TODO: Implement RUN - start program execution
    print('RUN not yet implemented');
    _state = ExecutionState.stopped;
  }

  /// Execute LIST statement
  void _executeList() {
    // TODO: Implement LIST - show program lines
    print('LIST not yet implemented');
  }

  /// Execute NEW statement
  void _executeNew() {
    // TODO: Implement NEW - clear program
    print('NEW not yet implemented');
  }

  /// Execute GOTO statement
  void _executeGoto() {
    // TODO: Parse line number and jump
    print('GOTO not yet implemented');
  }

  /// Execute LET statement
  void _executeLet() {
    // Parse variable name on left side of assignment
    final variableName = _parseVariableName();

    // Skip spaces and look for equals sign
    _skipSpaces();
    if (_getCurrentChar() != Tokenizer.equalToken) { // Equals token
      throw InterpreterException('SYNTAX ERROR - Missing = in LET statement');
    }
    _advanceTextPointer(); // Skip the equals sign

    // Evaluate the expression on the right side
    final result = expressionEvaluator.evaluateExpression(_currentLine, _textPointer);
    _textPointer = result.endPosition;

    // Store the value in the variable
    variables.setVariable(variableName, result.value);
  }

  /// Handle runtime errors
  void _handleError(dynamic error) {
    if (error is InterpreterException) {
      print(error.message);
    } else {
      print('RUNTIME ERROR: $error');
    }
    _state = ExecutionState.immediate; // Return to direct mode
  }

  /// Execute a line of BASIC code
  void executeLine(String line) {
    // Tokenize the line
    _currentLine = tokenizer.tokenizeLine(line);
    _textPointer = 0;

    // If line starts with a number, it's a program line
    if (_currentLine.isNotEmpty && _isDigit(_currentLine[0])) {
      _state = ExecutionState.immediate; // Stay in immediate mode for line entry
      _handleLineNumberEntry();
    } else {
      // Direct mode execution
      _state = ExecutionState.immediate;
      while (_textPointer < _currentLine.length) {
        _executeNextStatement();
      }
    }
  }

  /// Reset interpreter to initial state
  void reset() {
    _state = ExecutionState.immediate;
    _textPointer = 0;
    _currentLine = [];
    _directModeInput = '';
  }

  /// Check if interpreter is running
  bool get isRunning => _state != ExecutionState.stopped;
}

/// Execution state of the interpreter
enum ExecutionState {
  immediate, // Direct mode - executing immediate commands
  program,   // Program mode - executing stored program
  stopped    // Stopped - exit interpreter
}

/// Exception thrown by interpreter
class InterpreterException implements Exception {
  final String message;

  InterpreterException(this.message);

  @override
  String toString() => 'InterpreterException: $message';
}
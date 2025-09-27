import 'dart:io';

import '../memory/memory.dart';
import '../memory/variables.dart';
import '../memory/program_storage.dart';
import '../memory/user_functions.dart';
import '../runtime/stack.dart';
import '../runtime/errors.dart';
import '../io/screen.dart';
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
  final ProgramStorage programStorage;
  final RuntimeStack runtimeStack;
  final Screen screen;
  final UserFunctionStorage userFunctions;

  /// Current execution state
  ExecutionState _state = ExecutionState.immediate;

  /// Text pointer - current position in tokenized line
  int _textPointer = 0;

  /// Current tokenized line being executed
  List<int> _currentLine = [];

  /// Current line number being executed (-1 for direct mode)
  int _currentLineNumber = -1;

  /// Direct mode input buffer
  String _directModeInput = '';

  /// DATA statement pointer - line number containing current DATA statement
  int _dataLineNumber = -1;

  /// DATA statement pointer - position within the DATA line
  int _dataTextPointer = 0;

  /// Flag to track if we need to find first DATA statement
  bool _dataInitialized = false;

  /// Whether to rethrow exceptions in runProgram (for tests)
  bool _shouldRethrowExceptions = false;

  /// Program mode flag
  bool get isInProgramMode => _state == ExecutionState.program;

  /// Direct mode flag
  bool get isInDirectMode => _state == ExecutionState.immediate;

  Interpreter(
    this.memory,
    this.tokenizer,
    this.variables,
    this.expressionEvaluator,
    this.programStorage,
    this.runtimeStack,
    this.screen,
    this.userFunctions,
  );

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
    if (currentChar == 0 || currentChar == 58) {
      // null or colon
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
    while (_textPointer < _currentLine.length && _getCurrentChar() == 32) {
      // ASCII space
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
      throw InterpreterException(
        'SYNTAX ERROR - Variable must start with letter',
      );
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
    if (_textPointer < _currentLine.length && _getCurrentChar() == 36) {
      // '$'
      _advanceTextPointer();
    }

    // Check for array variable suffix '(' (we'll handle this later)
    if (_textPointer < _currentLine.length && _getCurrentChar() == 40) {
      // '('
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
    programStorage.storeLine(lineNumber, content);
  }

  /// Delete a line from the program
  void _deleteLine(int lineNumber) {
    programStorage.deleteLine(lineNumber);
  }

  /// Advance to next program line
  void _advanceToNextLine() {
    if (_currentLineNumber == -1) {
      // Direct mode - stop execution
      _state = ExecutionState.stopped;
      return;
    }

    final nextLineNumber = programStorage.getNextLineNumber(_currentLineNumber);
    if (nextLineNumber == -1) {
      // End of program
      _state = ExecutionState.immediate;
      print('READY.');
      return;
    }

    _jumpToLine(nextLineNumber);
  }

  /// Jump to a specific line number
  void _jumpToLine(int lineNumber) {
    final lineAddress = programStorage.findLineAddress(lineNumber);
    if (lineAddress == -1) {
      throw InterpreterException(
        'UNDEF\'D STATEMENT ERROR - Line $lineNumber not found',
      );
    }

    _currentLineNumber = lineNumber;
    _currentLine = programStorage.getLineContent(lineNumber);
    _textPointer = 0;
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
      case Tokenizer.clearToken:
        _executeClear();
        break;
      case Tokenizer.gotoToken:
        _executeGoto();
        break;
      case Tokenizer.letToken:
        _executeLet();
        break;
      case Tokenizer.ifToken:
        _executeIf();
        break;
      case Tokenizer.forToken:
        _executeFor();
        break;
      case Tokenizer.nextToken:
        _executeNext();
        break;
      case Tokenizer.gosubToken:
        _executeGosub();
        break;
      case Tokenizer.returnToken:
        _executeReturn();
        break;
      case Tokenizer.onToken:
        _executeOn();
        break;
      case Tokenizer.inputToken:
        _executeInput();
        break;
      case Tokenizer.dataToken:
        _executeData();
        break;
      case Tokenizer.readToken:
        _executeRead();
        break;
      case Tokenizer.restoreToken:
        _executeRestore();
        break;
      case Tokenizer.getToken:
        _executeGet();
        break;
      case Tokenizer.saveToken:
        _executeSave();
        break;
      case Tokenizer.loadToken:
        _executeLoad();
        break;
      case Tokenizer.verifyToken:
        _executeVerify();
        break;
      case Tokenizer.pokeToken:
        _executePoke();
        break;
      case Tokenizer.defToken:
        _executeDef();
        break;
      case Tokenizer.dimToken:
        _executeDim();
        break;
      case Tokenizer.stopToken:
        _executeStop();
        break;
      case Tokenizer.waitToken:
        _executeWait();
        break;
      case Tokenizer.contToken:
        _executeCont();
        break;
      case Tokenizer.clrToken:
        _executeClr();
        break;
      case Tokenizer.cmdToken:
        _executeCmd();
        break;
      case Tokenizer.sysToken:
        _executeSys();
        break;
      case Tokenizer.openToken:
        _executeOpen();
        break;
      case Tokenizer.closeToken:
        _executeClose();
        break;
      default:
        throw InterpreterException(
          'SYNTAX ERROR - Unknown statement: ${tokenizer.getTokenName(token)}',
        );
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
        if (_getCurrentChar() == Tokenizer.equalToken) {
          // Equals token
          // This is an assignment - execute like LET
          _advanceTextPointer(); // Skip equals sign

          // Evaluate the expression on the right side
          final result = expressionEvaluator.evaluateExpression(
            _currentLine,
            _textPointer,
          );
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
      final result = expressionEvaluator.evaluateExpression(
        _currentLine,
        _textPointer,
      );
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

  /// Execute PRINT statement
  void _executePrint() {
    // Handle PRINT with expressions
    _skipSpaces();

    // Check if there's anything to print
    if (_textPointer >= _currentLine.length || _getCurrentChar() == 0) {
      // Empty PRINT - just print newline
      screen.printLine('');
      return;
    }

    // Evaluate and print expressions
    bool needNewline = true;
    while (_textPointer < _currentLine.length) {
      final currentChar = _getCurrentChar();

      if (currentChar == 0 || currentChar == 58) {
        // null or colon (end of statement)
        break;
      }

      // Check for print separators
      if (currentChar == 44) {
        // comma - tab to next zone
        screen.tabToNextZone();
        _advanceTextPointer();
        _skipSpaces();
        needNewline = false;
        continue;
      } else if (currentChar == 59) {
        // semicolon - no spacing
        _advanceTextPointer();
        _skipSpaces();
        needNewline = false;
        continue;
      }

      // Evaluate expression
      try {
        final result = expressionEvaluator.evaluateExpression(
          _currentLine,
          _textPointer,
        );
        _textPointer = result.endPosition;

        // Format and print the result
        if (result.value is NumericValue) {
          final numValue = (result.value as NumericValue).value;
          String formatted;
          if (numValue == numValue.truncate().toDouble() &&
              numValue.abs() < 1e15) {
            // Print integers without decimal point
            formatted = numValue.truncate().toString();
          } else {
            // Print floating point
            formatted = numValue.toString();
          }
          // Add leading space for positive numbers (BASIC convention)
          if (numValue >= 0) {
            formatted = ' $formatted';
          }
          screen.printWithoutNewline(formatted);
        } else if (result.value is StringValue) {
          final strValue = (result.value as StringValue).value;
          screen.printWithoutNewline(strValue);
        } else if (result.value is TabValue) {
          final tabValue = (result.value as TabValue);
          screen.tabToColumn(tabValue.column);
        } else if (result.value is SpcValue) {
          final spcValue = (result.value as SpcValue);
          screen.printSpaces(spcValue.spaces);
        } else {
          screen.printWithoutNewline(result.value.toString());
        }

        needNewline = true;
        _skipSpaces();
      } catch (e) {
        // If expression evaluation fails, try to print as literal
        final remaining = _getRemainingLine();
        final text = tokenizer.detokenize(remaining);
        screen.printWithoutNewline(text);
        _textPointer = _currentLine.length;
        break;
      }
    }

    // Print final newline if needed
    if (needNewline) {
      screen.printLine('');
    }
  }

  /// Execute RUN statement
  void _executeRun() {
    // Clear variables (RUN should start fresh)
    variables.clearVariables();

    // Check if there's a line number after RUN
    final startLineNumber = _parseLineNumber();

    int firstLine;
    if (startLineNumber != -1) {
      // Start from specified line
      firstLine = startLineNumber;
    } else {
      // Start from first line in program
      firstLine = programStorage.getFirstLineNumber();
      if (firstLine == -1) {
        print('READY.'); // Empty program
        return;
      }
    }

    // Remember original state for exception handling
    final wasImmediate = _state == ExecutionState.immediate;

    // Switch to program mode and start execution
    _state = ExecutionState.program;
    _jumpToLine(firstLine);

    // Continue execution until program completes
    // When called from executeLine (typically in tests), we want exceptions to propagate
    // When called from interactive mode, exceptions should be caught and printed
    runProgram(rethrowExceptions: _shouldRethrowExceptions);
  }

  /// Execute LIST statement
  void _executeList() {
    final lineNumbers = programStorage.getAllLineNumbers();

    if (lineNumbers.isEmpty) {
      print('READY.'); // No program to list
      return;
    }

    // Check for line range specification
    int? startLine;
    int? endLine;

    _skipSpaces();
    if (_textPointer < _currentLine.length &&
        _isDigit(_currentLine[_textPointer])) {
      // Parse start line number
      startLine = _parseLineNumber();

      _skipSpaces();
      // Check for dash indicating range
      if (_textPointer < _currentLine.length &&
          _currentLine[_textPointer] == '-') {
        _textPointer++;
        _skipSpaces();

        // Parse end line number if present
        if (_textPointer < _currentLine.length &&
            _isDigit(_currentLine[_textPointer])) {
          endLine = _parseLineNumber();
        }
      } else {
        // Single line specified
        endLine = startLine;
      }
    }

    // Filter line numbers based on range
    List<int> linesToList;
    if (startLine != null) {
      if (endLine != null) {
        // Range specified
        linesToList = lineNumbers
            .where((ln) => ln >= startLine! && ln <= endLine!)
            .toList();
      } else {
        // Open-ended range (LIST 100-)
        linesToList = lineNumbers.where((ln) => ln >= startLine!).toList();
      }
    } else {
      // No range specified, list all
      linesToList = lineNumbers;
    }

    for (final lineNumber in linesToList) {
      try {
        final line = programStorage.getLineForDisplay(
          lineNumber,
          tokenizer.detokenize,
        );
        print(line);
      } catch (e) {
        print('Error listing line $lineNumber: $e');
      }
    }
  }

  /// Execute NEW statement
  void _executeNew() {
    // Clear the program
    programStorage.clearProgram();

    // Clear all variables
    variables.clearVariables();

    // Clear user-defined functions
    userFunctions.clear();

    // Return to immediate mode
    _state = ExecutionState.immediate;
    _currentLineNumber = -1;

    print('READY.');
  }

  /// Execute CLEAR statement
  void _executeClear() {
    // CLEAR clears variables but keeps the program in memory
    // This is different from NEW which clears both program and variables
    variables.clearVariables();

    // Clear user-defined functions
    userFunctions.clear();

    // Clear the runtime stack
    runtimeStack.clear();

    // Return to immediate mode
    _state = ExecutionState.immediate;
    _currentLineNumber = -1;

    print('READY.');
  }

  /// Execute GOTO statement
  void _executeGoto() {
    _skipSpaces();

    if (_textPointer >= _currentLine.length) {
      throw InterpreterException('SYNTAX ERROR - Missing line number in GOTO');
    }

    // Always evaluate as an expression (handles both static numbers and computations)
    final result = expressionEvaluator.evaluateExpression(
      _currentLine,
      _textPointer,
    );
    _textPointer = result.endPosition;

    if (result.value is! NumericValue) {
      throw InterpreterException('TYPE MISMATCH - GOTO target must be numeric');
    }

    final targetLineNumber = (result.value as NumericValue).value.toInt();
    if (targetLineNumber < 0 || targetLineNumber > 65535) {
      throw InterpreterException(
        'ILLEGAL QUANTITY ERROR - Line number out of range',
      );
    }

    _jumpToLine(targetLineNumber);
  }

  /// Parse a line number at current text pointer
  int _parseLineNumber() {
    _skipSpaces();

    if (_textPointer >= _currentLine.length) {
      return -1;
    }

    int lineNumber = 0;
    int currentChar = _getCurrentChar();

    if (!_isDigit(currentChar)) {
      return -1;
    }

    while (_isDigit(currentChar) && _textPointer < _currentLine.length) {
      lineNumber = lineNumber * 10 + (currentChar - 48);
      _advanceTextPointer();
      currentChar = _getCurrentChar();
    }

    return lineNumber;
  }

  /// Execute LET statement
  void _executeLet() {
    // Parse variable name on left side of assignment
    final variableName = _parseVariableName();

    // Skip spaces and look for equals sign
    _skipSpaces();
    if (_getCurrentChar() != Tokenizer.equalToken) {
      // Equals token
      throw InterpreterException('SYNTAX ERROR - Missing = in LET statement');
    }
    _advanceTextPointer(); // Skip the equals sign

    // Evaluate the expression on the right side
    final result = expressionEvaluator.evaluateExpression(
      _currentLine,
      _textPointer,
    );
    _textPointer = result.endPosition;

    // Store the value in the variable
    variables.setVariable(variableName, result.value);
  }

  /// Execute IF statement
  void _executeIf() {
    // Evaluate the condition expression
    final conditionResult = expressionEvaluator.evaluateExpression(
      _currentLine,
      _textPointer,
    );
    _textPointer = conditionResult.endPosition;

    // Check if condition is true (non-zero)
    bool conditionTrue = false;
    if (conditionResult.value is NumericValue) {
      final numValue = conditionResult.value as NumericValue;
      conditionTrue = numValue.value != 0.0;
    } else {
      throw InterpreterException(
        'TYPE MISMATCH - IF condition must be numeric',
      );
    }

    // Skip spaces
    _skipSpaces();

    // Check for THEN keyword (optional in some BASIC dialects)
    if (_textPointer < _currentLine.length &&
        _getCurrentChar() == Tokenizer.thenToken) {
      _advanceTextPointer(); // Skip THEN token
      _skipSpaces();
    }

    if (conditionTrue) {
      // Condition is true - execute the statement after THEN
      // Check if it's a line number (GOTO) or a statement
      if (_textPointer < _currentLine.length) {
        final nextChar = _getCurrentChar();
        if (_isDigit(nextChar)) {
          // It's a line number - jump to it
          final targetLine = _parseLineNumber();
          if (targetLine != -1) {
            _jumpToLine(targetLine);
          }
        } else {
          // It's a statement - execute it
          _dispatchStatement(nextChar);
        }
      }
    } else {
      // Condition is false - skip to end of line
      _textPointer = _currentLine.length;
    }
  }

  /// Execute FOR statement
  void _executeFor() {
    // Parse: FOR variable = start TO end [STEP step]

    // Parse the loop variable name
    final variableName = _parseVariableName();

    // Skip spaces and check for equals sign
    _skipSpaces();
    if (_getCurrentChar() != Tokenizer.equalToken) {
      throw InterpreterException('SYNTAX ERROR - Missing = in FOR statement');
    }
    _advanceTextPointer(); // Skip equals sign

    // Evaluate the start value
    final startResult = expressionEvaluator.evaluateExpression(
      _currentLine,
      _textPointer,
    );
    _textPointer = startResult.endPosition;

    if (startResult.value is! NumericValue) {
      throw InterpreterException(
        'TYPE MISMATCH - FOR start value must be numeric',
      );
    }
    final startValue = (startResult.value as NumericValue).value;

    // Skip spaces and check for TO token
    _skipSpaces();
    if (_getCurrentChar() != Tokenizer.toToken) {
      throw InterpreterException('SYNTAX ERROR - Missing TO in FOR statement');
    }
    _advanceTextPointer(); // Skip TO token

    // Evaluate the end value
    final endResult = expressionEvaluator.evaluateExpression(
      _currentLine,
      _textPointer,
    );
    _textPointer = endResult.endPosition;

    if (endResult.value is! NumericValue) {
      throw InterpreterException(
        'TYPE MISMATCH - FOR end value must be numeric',
      );
    }
    final endValue = (endResult.value as NumericValue).value;

    // Check for optional STEP clause
    double stepValue = 1.0; // Default step
    _skipSpaces();
    if (_textPointer < _currentLine.length &&
        _getCurrentChar() == Tokenizer.stepToken) {
      _advanceTextPointer(); // Skip STEP token

      final stepResult = expressionEvaluator.evaluateExpression(
        _currentLine,
        _textPointer,
      );
      _textPointer = stepResult.endPosition;

      if (stepResult.value is! NumericValue) {
        throw InterpreterException(
          'TYPE MISMATCH - FOR step value must be numeric',
        );
      }
      stepValue = (stepResult.value as NumericValue).value;

      if (stepValue == 0.0) {
        throw InterpreterException(
          'ILLEGAL QUANTITY ERROR - STEP cannot be zero',
        );
      }
    }

    // Set the loop variable to the start value
    variables.setVariable(variableName, NumericValue(startValue));

    // Check if loop should execute at least once
    bool shouldExecute;
    if (stepValue > 0) {
      shouldExecute = startValue <= endValue;
    } else {
      shouldExecute = startValue >= endValue;
    }

    if (!shouldExecute) {
      // Skip to matching NEXT statement
      _skipToMatchingNext(variableName);
      return;
    }

    // Push FOR loop onto stack
    runtimeStack.pushForLoop(
      variableName,
      stepValue,
      endValue,
      _currentLineNumber,
      _textPointer,
    );
  }

  /// Execute NEXT statement
  void _executeNext() {
    // Parse: NEXT [variable]

    String? variableName;
    _skipSpaces();

    // Check if variable name is specified
    if (_textPointer < _currentLine.length && _isLetter(_getCurrentChar())) {
      variableName = _parseVariableName();
    }

    // Find the matching FOR loop on the stack
    ForLoopEntry? forEntry;

    if (variableName != null) {
      // Pop the specific FOR loop
      forEntry = runtimeStack.popForLoop(variableName);
      if (forEntry == null) {
        throw InterpreterException(
          'NEXT WITHOUT FOR - No matching FOR statement for variable $variableName',
        );
      }
    } else {
      // Pop the most recent FOR loop
      // Search from top of stack for any FOR loop
      final activeVars = runtimeStack.getActiveForVariables();
      if (activeVars.isEmpty) {
        throw InterpreterException('NEXT WITHOUT FOR - No active FOR loops');
      }

      // Use the most recent FOR loop variable
      variableName = activeVars.last;
      forEntry = runtimeStack.popForLoop(variableName);
    }

    if (forEntry == null) {
      throw InterpreterException(
        'NEXT WITHOUT FOR - No matching FOR statement',
      );
    }

    // Get current value of loop variable
    final currentVar = variables.getVariable(variableName);
    if (currentVar is! NumericValue) {
      throw InterpreterException(
        'TYPE MISMATCH - Loop variable must be numeric',
      );
    }

    // Increment the loop variable by step
    final newValue = currentVar.value + forEntry.stepValue;
    variables.setVariable(variableName, NumericValue(newValue));

    // Check if loop should continue
    bool continueLoop;
    if (forEntry.stepValue > 0) {
      continueLoop = newValue <= forEntry.limitValue;
    } else {
      continueLoop = newValue >= forEntry.limitValue;
    }

    if (continueLoop) {
      // Continue loop - push FOR entry back onto stack and jump back to FOR line
      runtimeStack.pushForLoop(
        forEntry.variableName,
        forEntry.stepValue,
        forEntry.limitValue,
        forEntry.lineNumber,
        forEntry.textPointer,
      );

      // Jump back to the line after the FOR statement
      _jumpToLine(forEntry.lineNumber);
      _textPointer = forEntry.textPointer;
    }
    // If not continuing, just fall through to next statement
  }

  /// Execute GOSUB statement
  void _executeGosub() {
    // Parse the target line number
    final targetLineNumber = _parseLineNumber();

    if (targetLineNumber == -1) {
      throw InterpreterException('SYNTAX ERROR - Invalid line number in GOSUB');
    }

    // Push current position onto GOSUB stack for RETURN
    // Save the current line number and text pointer for return
    runtimeStack.pushGosub(_currentLineNumber, _textPointer);

    // Jump to the subroutine
    _jumpToLine(targetLineNumber);
  }

  /// Execute RETURN statement
  void _executeReturn() {
    // Pop the most recent GOSUB entry from stack
    final gosubEntry = runtimeStack.popGosub();

    if (gosubEntry == null) {
      throw InterpreterException(
        'RETURN WITHOUT GOSUB - No matching GOSUB statement',
      );
    }

    // Return to the line and position after the GOSUB
    _jumpToLine(gosubEntry.lineNumber);
    _textPointer = gosubEntry.textPointer;
  }

  /// Execute ON statement (ON expression GOTO/GOSUB line1, line2, ...)
  void _executeOn() {
    // Evaluate the expression
    final result = expressionEvaluator.evaluateExpression(
      _currentLine,
      _textPointer,
    );
    _textPointer = result.endPosition;

    if (result.value is! NumericValue) {
      throw InterpreterException(
        'TYPE MISMATCH - ON expression must be numeric',
      );
    }

    final numValue = (result.value as NumericValue).value;
    final index = numValue.truncate(); // Convert to integer

    // Skip spaces and get the keyword (GOTO or GOSUB)
    _skipSpaces();

    if (_textPointer >= _currentLine.length) {
      throw InterpreterException(
        'SYNTAX ERROR - Missing GOTO or GOSUB in ON statement',
      );
    }

    final keyword = _getCurrentChar();
    bool isGosub;

    if (keyword == Tokenizer.gotoToken) {
      isGosub = false;
      _advanceTextPointer(); // Skip GOTO token
    } else if (keyword == Tokenizer.gosubToken) {
      isGosub = true;
      _advanceTextPointer(); // Skip GOSUB token
    } else {
      throw InterpreterException(
        'SYNTAX ERROR - ON must be followed by GOTO or GOSUB',
      );
    }

    // Parse the list of line numbers
    final lineNumbers = <int>[];
    _skipSpaces();

    while (_textPointer < _currentLine.length) {
      final currentChar = _getCurrentChar();

      // Check for end of statement
      if (currentChar == 0 || currentChar == 58) {
        // null or colon
        break;
      }

      // Parse line number
      final lineNumber = _parseLineNumber();
      if (lineNumber == -1) {
        throw InterpreterException(
          'SYNTAX ERROR - Invalid line number in ON statement',
        );
      }

      lineNumbers.add(lineNumber);

      // Skip spaces and check for comma
      _skipSpaces();
      if (_textPointer < _currentLine.length && _getCurrentChar() == 44) {
        // comma
        _advanceTextPointer(); // Skip comma
        _skipSpaces();
      } else {
        break; // No more line numbers
      }
    }

    // Check if we have any line numbers
    if (lineNumbers.isEmpty) {
      throw InterpreterException(
        'SYNTAX ERROR - No line numbers in ON statement',
      );
    }

    // Check if index is in range (1-based indexing in BASIC)
    if (index < 1 || index > lineNumbers.length) {
      // Out of range - do nothing (this is standard BASIC behavior)
      return;
    }

    // Get the target line number (convert to 0-based indexing)
    final targetLine = lineNumbers[index - 1];

    // Execute GOTO or GOSUB to the target line
    if (isGosub) {
      // Save current position for GOSUB
      runtimeStack.pushGosub(_currentLineNumber, _textPointer);
    }

    _jumpToLine(targetLine);
  }

  /// Execute INPUT statement
  void _executeInput() {
    // Parse optional prompt string
    String prompt = "";
    _skipSpaces();

    // Check for quoted prompt string
    if (_getCurrentChar() == 34) {
      // Double quote
      _advanceTextPointer(); // Skip opening quote
      final promptStart = _textPointer;

      // Find closing quote
      while (_textPointer < _currentLine.length && _getCurrentChar() != 34) {
        _advanceTextPointer();
      }

      if (_textPointer >= _currentLine.length) {
        throw InterpreterException(
          'SYNTAX ERROR - Unterminated string in INPUT',
        );
      }

      // Extract prompt string
      prompt = String.fromCharCodes(
        _currentLine.sublist(promptStart, _textPointer),
      );

      _advanceTextPointer(); // Skip closing quote
      _skipSpaces();

      // Check for required semicolon after prompt
      if (_getCurrentChar() != 59) {
        // Semicolon
        throw InterpreterException(
          'SYNTAX ERROR - Missing semicolon after INPUT prompt',
        );
      }
      _advanceTextPointer(); // Skip semicolon
      _skipSpaces();
    }

    // Parse variable list
    final variableNames = <String>[];

    while (true) {
      // Parse variable name
      final variableName = _parseVariableName();
      variableNames.add(variableName);

      // Skip spaces and check for comma
      _skipSpaces();
      if (_textPointer >= _currentLine.length || _getCurrentChar() != 44) {
        // Comma
        break; // No more variables
      }
      _advanceTextPointer(); // Skip comma
      _skipSpaces();
    }

    // Get input from user
    bool inputSuccess = false;
    while (!inputSuccess) {
      // Display prompt (use "? " if no custom prompt)
      if (prompt.isEmpty) {
        stdout.write('? ');
      } else {
        stdout.write(prompt);
      }

      // Read line from stdin
      final inputLine = stdin.readLineSync() ?? '';

      // Parse input values separated by commas
      final values = <String>[];
      int pos = 0;
      bool parseError = false;

      while (pos < inputLine.length && !parseError) {
        // Skip leading spaces
        while (pos < inputLine.length && inputLine[pos] == ' ') {
          pos++;
        }

        if (pos >= inputLine.length) break;

        // Check if value is a quoted string
        if (inputLine[pos] == '"') {
          // Parse quoted string
          pos++; // Skip opening quote
          final startPos = pos;

          while (pos < inputLine.length && inputLine[pos] != '"') {
            pos++;
          }

          if (pos >= inputLine.length) {
            print('?REDO FROM START');
            parseError = true;
            break; // Break out of parsing loop to restart input
          }

          values.add(inputLine.substring(startPos, pos));
          pos++; // Skip closing quote
        } else {
          // Parse unquoted value (up to comma or end)
          final startPos = pos;

          while (pos < inputLine.length && inputLine[pos] != ',') {
            pos++;
          }

          values.add(inputLine.substring(startPos, pos).trim());
        }

        // Skip comma if present
        if (pos < inputLine.length && inputLine[pos] == ',') {
          pos++;
        }
      }

      // If there was a parse error, restart input
      if (parseError) {
        continue; // Restart input loop
      }

      // If no values entered and we need at least one
      if (values.isEmpty && variableNames.isNotEmpty) {
        print('?REDO FROM START');
        continue; // Restart input loop
      }

      // Check if we have the right number of values
      if (values.length < variableNames.length) {
        // Too few values - ask for remaining values individually
        for (int i = values.length; i < variableNames.length; i++) {
          stdout.write('? ');
          final additionalInput = stdin.readLineSync() ?? '';
          values.add(additionalInput.trim());
        }
      }

      if (values.length > variableNames.length) {
        print('?EXTRA IGNORED');
        // Trim to the number of variables we need
        values.removeRange(variableNames.length, values.length);
      }

      // Try to assign values to variables
      bool assignmentSuccess = true;
      for (int i = 0; i < variableNames.length; i++) {
        final varName = variableNames[i];
        final value = i < values.length ? values[i] : '';

        if (varName.endsWith('\$')) {
          // String variable
          variables.setVariable(varName, StringValue(value));
        } else {
          // Numeric variable - parse the value
          if (value.isEmpty) {
            variables.setVariable(varName, NumericValue(0));
          } else {
            // Try to parse as number
            try {
              double numValue;

              // Check for valid number format
              if (value == '.') {
                numValue = 0;
              } else if (value.contains('E') || value.contains('e')) {
                // Scientific notation
                numValue = double.parse(value);
              } else {
                // Regular number
                numValue = double.parse(value);
              }

              variables.setVariable(varName, NumericValue(numValue));
            } catch (e) {
              // Invalid number
              print('?REDO FROM START');
              assignmentSuccess = false;
              break;
            }
          }
        }
      }

      inputSuccess = assignmentSuccess;
    }

    // Ensure text pointer is at end of line after INPUT completes
    _textPointer = _currentLine.length;
  }

  /// Execute DATA statement
  void _executeData() {
    // DATA statements are not executed - they are only used by READ
    // Skip to end of line
    _textPointer = _currentLine.length;
  }

  /// Execute READ statement
  void _executeRead() {
    // Initialize data pointer if not yet done
    if (!_dataInitialized) {
      _findFirstData();
    }

    // Parse variable list
    final variableNames = <String>[];

    while (true) {
      // Parse variable name
      final variableName = _parseVariableName();
      variableNames.add(variableName);

      // Skip spaces and check for comma
      _skipSpaces();
      if (_textPointer >= _currentLine.length || _getCurrentChar() != 44) {
        // Comma
        break; // No more variables
      }
      _advanceTextPointer(); // Skip comma
      _skipSpaces();
    }

    // Read data values for each variable
    for (final varName in variableNames) {
      // Get next data value
      final value = _getNextDataValue();

      if (value == null) {
        throw InterpreterException('OUT OF DATA ERROR');
      }

      if (varName.endsWith('\$')) {
        // String variable - store as string
        variables.setVariable(varName, StringValue(value));
      } else {
        // Numeric variable - parse as number
        try {
          final numValue = double.parse(value);
          variables.setVariable(varName, NumericValue(numValue));
        } catch (e) {
          // If not a valid number, treat as 0
          variables.setVariable(varName, NumericValue(0));
        }
      }
    }
  }

  /// Execute RESTORE statement
  void _executeRestore() {
    // Check for optional line number
    _skipSpaces();

    if (_textPointer < _currentLine.length && _isDigit(_getCurrentChar())) {
      // Parse line number
      final targetLine = _parseLineNumber();

      // Find specified DATA line
      if (!_findDataAtOrAfter(targetLine)) {
        throw InterpreterException(
          'UNDEF\'D STATEMENT ERROR - No DATA at or after line $targetLine',
        );
      }
    } else {
      // No line number - restore to first DATA
      _findFirstData();
    }
  }

  /// Find the first DATA statement in the program
  void _findFirstData() {
    _dataInitialized = true;

    // Start from the beginning of the program
    final firstLine = programStorage.getFirstLineNumber();
    if (firstLine == -1) {
      _dataLineNumber = -1;
      _dataTextPointer = 0;
      return;
    }

    int currentLine = firstLine;

    while (currentLine != -1) {
      final lineContent = programStorage.getLineContent(currentLine);

      // Search for DATA token in this line
      for (int i = 0; i < lineContent.length; i++) {
        if (lineContent[i] == Tokenizer.dataToken) {
          _dataLineNumber = currentLine;
          _dataTextPointer = i + 1; // Position after DATA token
          return;
        }
      }

      currentLine = programStorage.getNextLineNumber(currentLine);
    }

    // No DATA statements found
    _dataLineNumber = -1;
    _dataTextPointer = 0;
  }

  /// Find DATA statement at or after specified line number
  bool _findDataAtOrAfter(int targetLine) {
    // Find the target line or next available line
    int currentLine = programStorage.findLineAddress(targetLine) != -1
        ? targetLine
        : programStorage.getNextLineNumber(targetLine - 1);

    while (currentLine != -1) {
      final lineContent = programStorage.getLineContent(currentLine);

      // Search for DATA token in this line
      for (int i = 0; i < lineContent.length; i++) {
        if (lineContent[i] == Tokenizer.dataToken) {
          _dataLineNumber = currentLine;
          _dataTextPointer = i + 1; // Position after DATA token
          _dataInitialized = true;
          return true;
        }
      }

      currentLine = programStorage.getNextLineNumber(currentLine);
    }

    return false;
  }

  /// Get the next value from DATA statements
  String? _getNextDataValue() {
    if (_dataLineNumber == -1) {
      return null; // No DATA available
    }

    final lineContent = programStorage.getLineContent(_dataLineNumber);

    // Skip spaces
    while (_dataTextPointer < lineContent.length &&
        lineContent[_dataTextPointer] == 32) {
      _dataTextPointer++;
    }

    if (_dataTextPointer >= lineContent.length ||
        lineContent[_dataTextPointer] == 0 ||
        lineContent[_dataTextPointer] == 58) {
      // End of current DATA statement - find next DATA
      _findNextData();
      if (_dataLineNumber == -1) {
        return null; // No more DATA
      }
      return _getNextDataValue(); // Recursive call to get value from next DATA
    }

    // Check if value is quoted string
    if (lineContent[_dataTextPointer] == 34) {
      // Double quote
      _dataTextPointer++; // Skip opening quote
      final valueStart = _dataTextPointer;

      // Find closing quote
      while (_dataTextPointer < lineContent.length &&
          lineContent[_dataTextPointer] != 34) {
        _dataTextPointer++;
      }

      final value = String.fromCharCodes(
        lineContent.sublist(valueStart, _dataTextPointer),
      );

      if (_dataTextPointer < lineContent.length &&
          lineContent[_dataTextPointer] == 34) {
        _dataTextPointer++; // Skip closing quote
      }

      // Skip comma if present
      _skipDataComma(lineContent);

      return value;
    } else {
      // Unquoted value - read until comma or end
      final valueStart = _dataTextPointer;

      while (_dataTextPointer < lineContent.length &&
          lineContent[_dataTextPointer] != 44 && // Comma
          lineContent[_dataTextPointer] != 58 && // Colon
          lineContent[_dataTextPointer] != 0) {
        // End of line
        _dataTextPointer++;
      }

      // Trim trailing spaces
      int valueEnd = _dataTextPointer;
      while (valueEnd > valueStart && lineContent[valueEnd - 1] == 32) {
        valueEnd--;
      }

      final value = String.fromCharCodes(
        lineContent.sublist(valueStart, valueEnd),
      );

      // Skip comma if present
      _skipDataComma(lineContent);

      return value;
    }
  }

  /// Skip comma in DATA statement
  void _skipDataComma(List<int> lineContent) {
    // Skip spaces
    while (_dataTextPointer < lineContent.length &&
        lineContent[_dataTextPointer] == 32) {
      _dataTextPointer++;
    }

    // Skip comma if present
    if (_dataTextPointer < lineContent.length &&
        lineContent[_dataTextPointer] == 44) {
      _dataTextPointer++;
    }
  }

  /// Execute GET statement - read single character from keyboard
  void _executeGet() {
    // Parse variable name
    final variableName = _parseVariableName();

    // Read a single character from stdin without waiting for Enter
    stdout.write(''); // Flush output

    // Note: In Dart, reading a single character without Enter is platform-specific
    // and requires terminal mode changes. For now, we'll read a line and take first char
    stdin.echoMode = false;
    stdin.lineMode = false;

    try {
      // Read single character
      final char = stdin.readByteSync();

      if (char == -1) {
        // EOF or error - store empty string
        if (variableName.endsWith('\$')) {
          variables.setVariable(variableName, StringValue(''));
        } else {
          variables.setVariable(variableName, NumericValue(0));
        }
      } else {
        // Convert to string
        final charStr = String.fromCharCode(char);

        if (variableName.endsWith('\$')) {
          // String variable - store character as string
          variables.setVariable(variableName, StringValue(charStr));
        } else {
          // Numeric variable - store ASCII code
          variables.setVariable(variableName, NumericValue(char.toDouble()));
        }
      }
    } finally {
      // Restore normal terminal mode
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
  }

  /// Find the next DATA statement after current position
  void _findNextData() {
    if (_dataLineNumber == -1) {
      return;
    }

    final currentLineContent = programStorage.getLineContent(_dataLineNumber);

    // Check if there's another DATA on the same line (after colon)
    for (int i = _dataTextPointer; i < currentLineContent.length; i++) {
      if (currentLineContent[i] == 58) {
        // Colon
        // Check for DATA after colon
        for (int j = i + 1; j < currentLineContent.length; j++) {
          if (currentLineContent[j] == Tokenizer.dataToken) {
            _dataTextPointer = j + 1; // Position after DATA token
            return;
          }
        }
      }
    }

    // Look for DATA in subsequent lines
    int currentLine = programStorage.getNextLineNumber(_dataLineNumber);

    while (currentLine != -1) {
      final lineContent = programStorage.getLineContent(currentLine);

      // Search for DATA token
      for (int i = 0; i < lineContent.length; i++) {
        if (lineContent[i] == Tokenizer.dataToken) {
          _dataLineNumber = currentLine;
          _dataTextPointer = i + 1; // Position after DATA token
          return;
        }
      }

      currentLine = programStorage.getNextLineNumber(currentLine);
    }

    // No more DATA statements
    _dataLineNumber = -1;
    _dataTextPointer = 0;
  }

  /// Skip to matching NEXT statement for a given variable
  void _skipToMatchingNext(String variableName) {
    int forNestLevel = 1;

    while (true) {
      // Advance to next statement/line
      _advanceToNextLine();

      if (_currentLineNumber == -1) {
        throw InterpreterException(
          'FOR WITHOUT NEXT - Missing NEXT statement for variable $variableName',
        );
      }

      // Look for FOR and NEXT tokens in current line
      _textPointer = 0;
      while (_textPointer < _currentLine.length) {
        final token = _getCurrentChar();

        if (token == Tokenizer.forToken) {
          forNestLevel++;
        } else if (token == Tokenizer.nextToken) {
          forNestLevel--;
          if (forNestLevel == 0) {
            // Found matching NEXT - position after it
            _advanceTextPointer(); // Skip NEXT token
            _skipSpaces();

            // Check if it specifies our variable
            if (_textPointer < _currentLine.length &&
                _isLetter(_getCurrentChar())) {
              final nextVar = _parseVariableName();
              if (nextVar == variableName) {
                return; // Found exact match
              }
            } else {
              return; // NEXT without variable matches any FOR
            }

            // Not our variable, but still counts as a NEXT
            forNestLevel++;
          }
        }

        _advanceTextPointer();
      }
    }
  }

  /// Handle runtime errors
  void _handleError(dynamic error) {
    // Enhanced error recovery system
    if (error is InterpreterException) {
      print(error.message);
    } else {
      print('RUNTIME ERROR: $error');
    }

    // Perform error recovery
    _recoverFromError();
  }

  /// Recover from error by resetting system state appropriately
  void _recoverFromError() {
    // Reset text pointer to safe state
    _textPointer = 0;
    _currentLine = [];

    // Clear any partial expression evaluation state
    expressionEvaluator.reset();

    // If we were in program mode, return to immediate mode
    if (_state == ExecutionState.program) {
      print('READY.');
      _state = ExecutionState.immediate;
      _currentLineNumber = -1;
    }

    // Clear any temporary strings that might have been created
    // during the failed operation
    // Note: Full garbage collection might be too expensive here,
    // but we should at least clear any temps from the failed operation

    // Stack remains intact for FOR/GOSUB unless specifically corrupted
    // Variables remain intact - this is standard BASIC behavior
    // Program lines remain intact
  }

  /// Execute a line of BASIC code
  void executeLine(String line) {
    // Set flag to rethrow exceptions (for test compatibility)
    _shouldRethrowExceptions = true;

    try {
      // Tokenize the line
      _currentLine = tokenizer.tokenizeLine(line);
      _textPointer = 0;

      // If line starts with a number, it's a program line
      if (_currentLine.isNotEmpty && _isDigit(_currentLine[0])) {
        _state =
            ExecutionState.immediate; // Stay in immediate mode for line entry
        _handleLineNumberEntry();
      } else {
        // Direct mode execution
        _state = ExecutionState.immediate;
        while (_textPointer < _currentLine.length) {
          _executeNextStatement();
        }
      }
    } finally {
      // Reset the flag after execution
      _shouldRethrowExceptions = false;
    }
  }

  /// Process direct mode input (alias for executeLine)
  void processDirectModeInput(String line) {
    try {
      executeLine(line);
    } on InterpreterException catch (e) {
      // Convert InterpreterException to BasicError
      BasicErrorCode errorCode;
      if (e.message.contains('SYNTAX ERROR')) {
        errorCode = BasicErrorCode.syntaxError;
      } else if (e.message.contains('RETURN WITHOUT GOSUB')) {
        errorCode = BasicErrorCode.returnWithoutGosub;
      } else if (e.message.contains('OUT OF DATA')) {
        errorCode = BasicErrorCode.outOfData;
      } else {
        errorCode = BasicErrorCode.syntaxError; // Default for unknown errors
      }
      throw BasicError(errorCode, context: e.message);
    } catch (e) {
      // Convert any other exception to BasicError
      throw BasicError(BasicErrorCode.syntaxError, context: e.toString());
    }
  }

  /// Evaluate an expression from a string and return the result
  VariableValue evaluateExpressionFromString(String expression) {
    try {
      // Tokenize the expression
      _currentLine = tokenizer.tokenizeLine(expression);
      _textPointer = 0;

      // Evaluate the expression
      var result = expressionEvaluator.evaluateExpression(
        _currentLine,
        _textPointer,
      );
      _textPointer = result.endPosition;
      return result.value;
    } on ExpressionException catch (e) {
      // Convert ExpressionException to BasicError
      BasicErrorCode errorCode;
      if (e.message.contains('DIVISION BY ZERO')) {
        errorCode = BasicErrorCode.divisionByZero;
      } else if (e.message.contains('TYPE MISMATCH')) {
        errorCode = BasicErrorCode.typeMismatch;
      } else if (e.message.contains('OVERFLOW')) {
        errorCode = BasicErrorCode.overflow;
      } else if (e.message.contains('UNDEFINED FUNCTION')) {
        errorCode = BasicErrorCode.undefinedFunction;
      } else {
        errorCode = BasicErrorCode.syntaxError; // Default
      }
      throw BasicError(errorCode, context: e.message);
    } catch (e) {
      // Convert any other exception to BasicError
      throw BasicError(BasicErrorCode.syntaxError, context: e.toString());
    }
  }

  /// Execute SAVE statement
  void _executeSave() {
    _skipSpaces();

    // Parse filename string
    if (_getCurrentChar() != 34) {
      // Not a quote
      throw InterpreterException('SYNTAX ERROR - Filename must be in quotes');
    }

    _textPointer++; // Skip opening quote
    final filenameStart = _textPointer;

    // Find closing quote
    while (_textPointer < _currentLine.length && _getCurrentChar() != 34) {
      _textPointer++;
    }

    if (_textPointer >= _currentLine.length) {
      throw InterpreterException('SYNTAX ERROR - Missing closing quote');
    }

    // Extract filename
    final filenameBytes = _currentLine.sublist(filenameStart, _textPointer);
    final filename = String.fromCharCodes(filenameBytes);
    _textPointer++; // Skip closing quote

    // Validate filename
    if (filename.isEmpty) {
      throw InterpreterException('SYNTAX ERROR - Empty filename');
    }

    // Check if program exists
    if (programStorage.isEmpty) {
      throw InterpreterException('PROGRAM ERROR - No program to save');
    }

    // Save the program
    try {
      final programData = programStorage.exportProgram();
      final file = File(filename);

      // Check if directory exists and is writable
      final directory = file.parent;
      if (!directory.existsSync()) {
        throw InterpreterException(
          'DEVICE NOT PRESENT - Directory does not exist',
        );
      }

      // Check for disk space (basic check - if file exists, we should be able to write)
      file.writeAsBytesSync(programData);
      print('SAVED');
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 28) {
        // ENOSPC - No space left on device
        throw InterpreterException('DEVICE FULL - Insufficient disk space');
      } else if (e.osError?.errorCode == 13) {
        // EACCES - Permission denied
        throw InterpreterException('WRITE PROTECT - Cannot write to file');
      } else {
        throw InterpreterException('DEVICE ERROR - ${e.message}');
      }
    } catch (e) {
      throw InterpreterException('FILE ERROR - Cannot save to $filename: $e');
    }
  }

  /// Execute LOAD statement
  void _executeLoad() {
    _skipSpaces();

    // Parse filename string
    if (_getCurrentChar() != 34) {
      // Not a quote
      throw InterpreterException('SYNTAX ERROR - Filename must be in quotes');
    }

    _textPointer++; // Skip opening quote
    final filenameStart = _textPointer;

    // Find closing quote
    while (_textPointer < _currentLine.length && _getCurrentChar() != 34) {
      _textPointer++;
    }

    if (_textPointer >= _currentLine.length) {
      throw InterpreterException('SYNTAX ERROR - Missing closing quote');
    }

    // Extract filename
    final filenameBytes = _currentLine.sublist(filenameStart, _textPointer);
    final filename = String.fromCharCodes(filenameBytes);
    _textPointer++; // Skip closing quote

    // Validate filename
    if (filename.isEmpty) {
      throw InterpreterException('SYNTAX ERROR - Empty filename');
    }

    // Load the program
    try {
      final file = File(filename);

      // Check if file exists
      if (!file.existsSync()) {
        throw InterpreterException('FILE NOT FOUND - $filename');
      }

      // Check if file is readable
      final stat = file.statSync();
      if (stat.type == FileSystemEntityType.directory) {
        throw InterpreterException('DEVICE ERROR - $filename is a directory');
      }

      // Check file size - prevent loading huge files
      if (stat.size > 65536) {
        // 64KB limit for BASIC programs
        throw InterpreterException('PROGRAM TOO LARGE - File exceeds 64KB');
      }

      // Try to read the file
      final programData = file.readAsBytesSync();

      // Validate file format (basic check)
      if (programData.isEmpty) {
        throw InterpreterException('BAD FORMAT - File is empty');
      }

      // Clear current program and variables
      programStorage.clearProgram();
      variables.clearVariables();

      // Import the new program
      try {
        programStorage.importProgram(programData);
        print('LOADED');
      } catch (e) {
        // Restore clean state if import fails
        programStorage.clearProgram();
        variables.clearVariables();
        throw InterpreterException('BAD FORMAT - Invalid program file');
      }
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 2) {
        // ENOENT - No such file or directory
        throw InterpreterException('FILE NOT FOUND - $filename');
      } else if (e.osError?.errorCode == 13) {
        // EACCES - Permission denied
        throw InterpreterException('READ PROTECTED - Cannot read file');
      } else if (e.osError?.errorCode == 21) {
        // EISDIR - Is a directory
        throw InterpreterException('DEVICE ERROR - $filename is a directory');
      } else {
        throw InterpreterException('DEVICE ERROR - ${e.message}');
      }
    } catch (e) {
      if (e is InterpreterException) {
        throw e;
      }
      throw InterpreterException('FILE ERROR - Cannot load from $filename: $e');
    }
  }

  /// Execute VERIFY statement
  void _executeVerify() {
    _skipSpaces();

    // Parse filename string
    if (_getCurrentChar() != 34) {
      // Not a quote
      throw InterpreterException('SYNTAX ERROR - Filename must be in quotes');
    }

    _textPointer++; // Skip opening quote
    final filenameStart = _textPointer;

    // Find closing quote
    while (_textPointer < _currentLine.length && _getCurrentChar() != 34) {
      _textPointer++;
    }

    if (_textPointer >= _currentLine.length) {
      throw InterpreterException('SYNTAX ERROR - Missing closing quote');
    }

    // Extract filename
    final filenameBytes = _currentLine.sublist(filenameStart, _textPointer);
    final filename = String.fromCharCodes(filenameBytes);
    _textPointer++; // Skip closing quote

    // Validate filename
    if (filename.isEmpty) {
      throw InterpreterException('SYNTAX ERROR - Empty filename');
    }

    // Verify the program
    try {
      final file = File(filename);

      // Check if file exists
      if (!file.existsSync()) {
        throw InterpreterException('FILE NOT FOUND - $filename');
      }

      // Check if file is readable
      final stat = file.statSync();
      if (stat.type == FileSystemEntityType.directory) {
        throw InterpreterException('DEVICE ERROR - $filename is a directory');
      }

      // Check file size
      if (stat.size > 65536) {
        // 64KB limit for BASIC programs
        throw InterpreterException('PROGRAM TOO LARGE - File exceeds 64KB');
      }

      // Try to read the file
      final programData = file.readAsBytesSync();

      // Validate file format (basic check)
      if (programData.isEmpty) {
        throw InterpreterException('BAD FORMAT - File is empty');
      }

      // Export current program for comparison
      final currentData = programStorage.exportProgram();

      // Compare the programs
      if (programData.length != currentData.length) {
        print('VERIFY ERROR - Program length differs');
        return;
      }

      for (int i = 0; i < programData.length; i++) {
        if (programData[i] != currentData[i]) {
          print('VERIFY ERROR - Program content differs at byte $i');
          return;
        }
      }

      print('VERIFIED');
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 2) {
        // ENOENT - No such file or directory
        throw InterpreterException('FILE NOT FOUND - $filename');
      } else if (e.osError?.errorCode == 13) {
        // EACCES - Permission denied
        throw InterpreterException('READ PROTECTED - Cannot read file');
      } else if (e.osError?.errorCode == 21) {
        // EISDIR - Is a directory
        throw InterpreterException('DEVICE ERROR - $filename is a directory');
      } else {
        throw InterpreterException('DEVICE ERROR - ${e.message}');
      }
    } catch (e) {
      if (e is InterpreterException) {
        throw e;
      }
      throw InterpreterException('FILE ERROR - Cannot verify $filename: $e');
    }
  }

  /// Execute POKE statement
  void _executePoke() {
    _skipSpaces();

    // Evaluate address expression
    final addressResult = expressionEvaluator.evaluateExpression(
      _currentLine,
      _textPointer,
    );
    _textPointer = addressResult.endPosition;

    if (addressResult.value is! NumericValue) {
      throw InterpreterException('TYPE MISMATCH');
    }

    final address = (addressResult.value as NumericValue).value.round();
    if (address < 0 || address > 65535) {
      throw InterpreterException('ILLEGAL QUANTITY');
    }

    _skipSpaces();

    // Expect comma separator
    if (_textPointer >= _currentLine.length || _getCurrentChar() != 44) {
      // comma
      throw InterpreterException('SYNTAX ERROR - Missing comma in POKE');
    }
    _advanceTextPointer(); // Skip comma

    _skipSpaces();

    // Evaluate value expression
    final valueResult = expressionEvaluator.evaluateExpression(
      _currentLine,
      _textPointer,
    );
    _textPointer = valueResult.endPosition;

    if (valueResult.value is! NumericValue) {
      throw InterpreterException('TYPE MISMATCH');
    }

    final value = (valueResult.value as NumericValue).value.round();
    if (value < 0 || value > 255) {
      throw InterpreterException('ILLEGAL QUANTITY');
    }

    // Write byte to memory
    memory.writeByte(address, value);
  }

  /// Execute DEF statement - define user function
  void _executeDef() {
    _skipSpaces();

    // Check if we have "FN" followed by a letter
    // This could be tokenized as FN token + letter, or as individual letters F + N + letter
    String functionName = '';

    if (_textPointer < _currentLine.length &&
        _getCurrentChar() == Tokenizer.fnToken) {
      // Case 1: FN is properly tokenized
      _advanceTextPointer(); // Skip FN token
      _skipSpaces();

      if (_textPointer >= _currentLine.length ||
          !_isLetter(_getCurrentChar())) {
        throw InterpreterException(
          'SYNTAX ERROR - Invalid function name after FN',
        );
      }

      functionName =
          'FN' + String.fromCharCode(_getCurrentChar()).toUpperCase();
      _advanceTextPointer();
    } else if (_textPointer + 1 < _currentLine.length &&
        _getCurrentChar() == 70 && // 'F'
        _currentLine[_textPointer + 1] == 78) {
      // 'N'
      // Case 2: FN is stored as individual characters
      _advanceTextPointer(); // Skip 'F'
      _advanceTextPointer(); // Skip 'N'

      if (_textPointer >= _currentLine.length ||
          !_isLetter(_getCurrentChar())) {
        throw InterpreterException(
          'SYNTAX ERROR - Invalid function name after FN',
        );
      }

      functionName =
          'FN' + String.fromCharCode(_getCurrentChar()).toUpperCase();
      _advanceTextPointer();
    } else {
      throw InterpreterException('SYNTAX ERROR - Expected FN after DEF');
    }

    bool isStringFunction = false;
    if (_textPointer < _currentLine.length && _getCurrentChar() == 36) {
      // $ character
      isStringFunction = true;
      functionName += '\$';
      _advanceTextPointer();
    }

    _skipSpaces();

    // Must have opening parenthesis (per original Microsoft BASIC 6502 spec)
    if (_textPointer >= _currentLine.length || _getCurrentChar() != 40) {
      // (
      throw InterpreterException(
        'SYNTAX ERROR - Expected ( after function name',
      );
    }
    _advanceTextPointer(); // Skip (

    _skipSpaces();

    // Parse single parameter name - must be a single letter variable (no strings allowed per original spec)
    if (_textPointer >= _currentLine.length || !_isLetter(_getCurrentChar())) {
      throw InterpreterException('SYNTAX ERROR - Expected parameter name');
    }

    String parameter = String.fromCharCode(_getCurrentChar()).toUpperCase();
    _advanceTextPointer();

    // Original Microsoft BASIC 6502 does not support string functions
    // But we'll keep this for compatibility with our extended implementation
    if (_textPointer < _currentLine.length && _getCurrentChar() == 36) {
      // $ character
      parameter += '\$';
      _advanceTextPointer();
    }

    _skipSpaces();

    // Must have closing parenthesis
    if (_textPointer >= _currentLine.length || _getCurrentChar() != 41) {
      // )
      throw InterpreterException('SYNTAX ERROR - Expected ) after parameter');
    }
    _advanceTextPointer(); // Skip )

    _skipSpaces();

    // Expect equals sign
    if (_textPointer >= _currentLine.length ||
        _getCurrentChar() != Tokenizer.equalToken) {
      throw InterpreterException(
        'SYNTAX ERROR - Expected = after parameter list',
      );
    }
    _advanceTextPointer(); // Skip =

    _skipSpaces();

    // Capture the rest of the line as the function expression
    List<int> expression = _currentLine.sublist(_textPointer);

    // Create and store the function
    final function = UserFunction(
      name: functionName,
      parameter: parameter,
      expression: expression,
      isStringFunction: isStringFunction,
    );

    userFunctions.defineFunction(function);

    // Advance to end of line
    _textPointer = _currentLine.length;
  }

  /// Execute DIM statement - dimension arrays
  void _executeDim() {
    _skipSpaces();

    // Parse one or more array declarations separated by commas
    while (_textPointer < _currentLine.length) {
      final currentChar = _getCurrentChar();
      if (currentChar == 0 || currentChar == 58) {
        // null or colon (end of statement)
        break;
      }

      // Parse variable name
      if (!_isLetter(_getCurrentChar())) {
        throw InterpreterException('SYNTAX ERROR - Expected variable name');
      }

      final variableName = _parseVariableName();

      _skipSpaces();

      // Expect opening parenthesis
      if (_textPointer >= _currentLine.length || _getCurrentChar() != 40) {
        // (
        throw InterpreterException(
          'SYNTAX ERROR - Expected ( after array name',
        );
      }
      _advanceTextPointer(); // Skip (

      // Parse dimensions
      List<int> dimensions = [];

      while (true) {
        _skipSpaces();

        // Evaluate dimension expression
        final result = expressionEvaluator.evaluateExpression(
          _currentLine,
          _textPointer,
        );
        _textPointer = result.endPosition;

        if (result.value is! NumericValue) {
          throw InterpreterException('TYPE MISMATCH');
        }

        final dimension = (result.value as NumericValue).value.round();
        if (dimension < 0) {
          throw InterpreterException('ILLEGAL QUANTITY');
        }

        dimensions.add(dimension);

        _skipSpaces();

        final nextChar = _getCurrentChar();
        if (nextChar == 44) {
          // comma - more dimensions
          _advanceTextPointer();
          continue;
        } else if (nextChar == 41) {
          // ) - end of dimensions
          _advanceTextPointer();
          break;
        } else {
          throw InterpreterException('SYNTAX ERROR - Expected , or ) in DIM');
        }
      }

      // Dimension the array - simplified implementation
      // For now, just ensure the variable exists as an array marker
      // TODO: Implement proper array storage with ArrayManager
      print(
        'DIM $variableName(${dimensions.join(',')}) - not fully implemented',
      );

      _skipSpaces();

      // Check for comma (more arrays) or end
      if (_textPointer < _currentLine.length && _getCurrentChar() == 44) {
        // comma
        _advanceTextPointer();
        _skipSpaces();
        continue;
      } else {
        break;
      }
    }
  }

  /// Execute STOP statement - halt program execution
  void _executeStop() {
    _state = ExecutionState.stopped;
    print('BREAK');
  }

  /// Execute WAIT statement - wait for memory condition (stub)
  void _executeWait() {
    throw InterpreterException('FUNCTION NOT IMPLEMENTED');
  }

  /// Execute CONT statement - continue from STOP
  void _executeCont() {
    throw InterpreterException('FUNCTION NOT IMPLEMENTED');
  }

  /// Execute CLR statement - clear screen (stub)
  void _executeClr() {
    screen.clearScreen();
  }

  /// Execute CMD statement - command device (stub)
  void _executeCmd() {
    throw InterpreterException('FUNCTION NOT IMPLEMENTED');
  }

  /// Execute SYS statement - system call (stub)
  void _executeSys() {
    throw InterpreterException('FUNCTION NOT IMPLEMENTED');
  }

  /// Execute OPEN statement - open file (stub)
  void _executeOpen() {
    throw InterpreterException('FUNCTION NOT IMPLEMENTED');
  }

  /// Execute CLOSE statement - close file (stub)
  void _executeClose() {
    throw InterpreterException('FUNCTION NOT IMPLEMENTED');
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

  /// Evaluate an expression from a string and return the numeric result
  double evaluateExpression(String expressionString) {
    final tokens = tokenizer.tokenizeLine(expressionString);
    final result = expressionEvaluator.evaluateExpression(tokens, 0);
    if (result.value is NumericValue) {
      return (result.value as NumericValue).value;
    }
    throw InterpreterException('Expected numeric result');
  }

  /// Execute program until completion
  void runProgram({bool rethrowExceptions = false}) {
    int maxSteps = 10000; // Prevent infinite loops
    int stepCount = 0;

    while (_state == ExecutionState.program && stepCount < maxSteps) {
      try {
        _executeNextStatement();
        stepCount++;
      } catch (e) {
        if (rethrowExceptions && e is InterpreterException) {
          _state = ExecutionState.immediate;
          rethrow;
        }
        _handleError(e);
        break;
      }
    }

    if (stepCount >= maxSteps) {
      print('Program stopped - maximum steps reached (possible infinite loop)');
      _state = ExecutionState.immediate;
    }
  }
}

/// Execution state of the interpreter
enum ExecutionState {
  immediate, // Direct mode - executing immediate commands
  program, // Program mode - executing stored program
  stopped, // Stopped - exit interpreter
}

/// Exception thrown by interpreter
class InterpreterException implements Exception {
  final String message;

  InterpreterException(this.message);

  @override
  String toString() => 'InterpreterException: $message';
}

import 'dart:io';

import '../memory/memory.dart';
import '../memory/variables.dart';
import '../memory/program_storage.dart';
import '../runtime/stack.dart';
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

  /// Program mode flag
  bool get isInProgramMode => _state == ExecutionState.program;

  /// Direct mode flag
  bool get isInDirectMode => _state == ExecutionState.immediate;

  Interpreter(this.memory, this.tokenizer, this.variables, this.expressionEvaluator, this.programStorage, this.runtimeStack);

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
      throw InterpreterException('UNDEF\'D STATEMENT ERROR - Line $lineNumber not found');
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

  /// Execute PRINT statement
  void _executePrint() {
    // Handle PRINT with expressions
    _skipSpaces();

    // Check if there's anything to print
    if (_textPointer >= _currentLine.length || _getCurrentChar() == 0) {
      // Empty PRINT - just print newline
      print('');
      return;
    }

    // Evaluate and print expressions
    bool needNewline = true;
    while (_textPointer < _currentLine.length) {
      final currentChar = _getCurrentChar();

      if (currentChar == 0 || currentChar == 58) { // null or colon (end of statement)
        break;
      }

      // Check for print separators
      if (currentChar == 44) { // comma - tab to next zone
        print(''); // For now, just newline (TODO: implement tab zones)
        _advanceTextPointer();
        _skipSpaces();
        needNewline = false;
        continue;
      } else if (currentChar == 59) { // semicolon - no spacing
        _advanceTextPointer();
        _skipSpaces();
        needNewline = false;
        continue;
      }

      // Evaluate expression
      try {
        final result = expressionEvaluator.evaluateExpression(_currentLine, _textPointer);
        _textPointer = result.endPosition;

        // Print the result
        if (result.value is NumericValue) {
          final numValue = (result.value as NumericValue).value;
          if (numValue == numValue.truncate().toDouble() && numValue.abs() < 1e15) {
            // Print integers without decimal point
            print(numValue.truncate().toString());
          } else {
            // Print floating point
            print(numValue.toString());
          }
        } else if (result.value is StringValue) {
          final strValue = (result.value as StringValue).value;
          print(strValue);
        } else {
          print(result.value.toString());
        }

        needNewline = true;
        _skipSpaces();
      } catch (e) {
        // If expression evaluation fails, try to print as literal
        final remaining = _getRemainingLine();
        final text = tokenizer.detokenize(remaining);
        print(text);
        _textPointer = _currentLine.length;
        break;
      }
    }

    // Print final newline if needed
    if (needNewline) {
      // Already printed with print() calls above
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

    // Switch to program mode and start execution
    _state = ExecutionState.program;
    _jumpToLine(firstLine);

    // Continue execution until program completes
    runProgram();
  }

  /// Execute LIST statement
  void _executeList() {
    final lineNumbers = programStorage.getAllLineNumbers();

    if (lineNumbers.isEmpty) {
      print('READY.'); // No program to list
      return;
    }

    for (final lineNumber in lineNumbers) {
      try {
        final line = programStorage.getLineForDisplay(lineNumber, tokenizer.detokenize);
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

    // Return to immediate mode
    _state = ExecutionState.immediate;
    _currentLineNumber = -1;

    print('READY.');
  }

  /// Execute GOTO statement
  void _executeGoto() {
    // Parse the target line number
    final targetLineNumber = _parseLineNumber();

    if (targetLineNumber == -1) {
      throw InterpreterException('SYNTAX ERROR - Invalid line number in GOTO');
    }

    // Jump to the target line
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

  /// Execute IF statement
  void _executeIf() {
    // Evaluate the condition expression
    final conditionResult = expressionEvaluator.evaluateExpression(_currentLine, _textPointer);
    _textPointer = conditionResult.endPosition;

    // Check if condition is true (non-zero)
    bool conditionTrue = false;
    if (conditionResult.value is NumericValue) {
      final numValue = conditionResult.value as NumericValue;
      conditionTrue = numValue.value != 0.0;
    } else {
      throw InterpreterException('TYPE MISMATCH - IF condition must be numeric');
    }

    // Skip spaces
    _skipSpaces();

    // Check for THEN keyword (optional in some BASIC dialects)
    if (_textPointer < _currentLine.length && _getCurrentChar() == Tokenizer.thenToken) {
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
    final startResult = expressionEvaluator.evaluateExpression(_currentLine, _textPointer);
    _textPointer = startResult.endPosition;

    if (startResult.value is! NumericValue) {
      throw InterpreterException('TYPE MISMATCH - FOR start value must be numeric');
    }
    final startValue = (startResult.value as NumericValue).value;

    // Skip spaces and check for TO token
    _skipSpaces();
    if (_getCurrentChar() != Tokenizer.toToken) {
      throw InterpreterException('SYNTAX ERROR - Missing TO in FOR statement');
    }
    _advanceTextPointer(); // Skip TO token

    // Evaluate the end value
    final endResult = expressionEvaluator.evaluateExpression(_currentLine, _textPointer);
    _textPointer = endResult.endPosition;

    if (endResult.value is! NumericValue) {
      throw InterpreterException('TYPE MISMATCH - FOR end value must be numeric');
    }
    final endValue = (endResult.value as NumericValue).value;

    // Check for optional STEP clause
    double stepValue = 1.0; // Default step
    _skipSpaces();
    if (_textPointer < _currentLine.length && _getCurrentChar() == Tokenizer.stepToken) {
      _advanceTextPointer(); // Skip STEP token

      final stepResult = expressionEvaluator.evaluateExpression(_currentLine, _textPointer);
      _textPointer = stepResult.endPosition;

      if (stepResult.value is! NumericValue) {
        throw InterpreterException('TYPE MISMATCH - FOR step value must be numeric');
      }
      stepValue = (stepResult.value as NumericValue).value;

      if (stepValue == 0.0) {
        throw InterpreterException('ILLEGAL QUANTITY ERROR - STEP cannot be zero');
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
    runtimeStack.pushForLoop(variableName, stepValue, endValue, _currentLineNumber, _textPointer);
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
        throw InterpreterException('NEXT WITHOUT FOR - No matching FOR statement for variable $variableName');
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
      throw InterpreterException('NEXT WITHOUT FOR - No matching FOR statement');
    }

    // Get current value of loop variable
    final currentVar = variables.getVariable(variableName);
    if (currentVar is! NumericValue) {
      throw InterpreterException('TYPE MISMATCH - Loop variable must be numeric');
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
      throw InterpreterException('RETURN WITHOUT GOSUB - No matching GOSUB statement');
    }

    // Return to the line and position after the GOSUB
    _jumpToLine(gosubEntry.lineNumber);
    _textPointer = gosubEntry.textPointer;
  }

  /// Execute ON statement (ON expression GOTO/GOSUB line1, line2, ...)
  void _executeOn() {
    // Evaluate the expression
    final result = expressionEvaluator.evaluateExpression(_currentLine, _textPointer);
    _textPointer = result.endPosition;

    if (result.value is! NumericValue) {
      throw InterpreterException('TYPE MISMATCH - ON expression must be numeric');
    }

    final numValue = (result.value as NumericValue).value;
    final index = numValue.truncate(); // Convert to integer

    // Skip spaces and get the keyword (GOTO or GOSUB)
    _skipSpaces();

    if (_textPointer >= _currentLine.length) {
      throw InterpreterException('SYNTAX ERROR - Missing GOTO or GOSUB in ON statement');
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
      throw InterpreterException('SYNTAX ERROR - ON must be followed by GOTO or GOSUB');
    }

    // Parse the list of line numbers
    final lineNumbers = <int>[];
    _skipSpaces();

    while (_textPointer < _currentLine.length) {
      final currentChar = _getCurrentChar();

      // Check for end of statement
      if (currentChar == 0 || currentChar == 58) { // null or colon
        break;
      }

      // Parse line number
      final lineNumber = _parseLineNumber();
      if (lineNumber == -1) {
        throw InterpreterException('SYNTAX ERROR - Invalid line number in ON statement');
      }

      lineNumbers.add(lineNumber);

      // Skip spaces and check for comma
      _skipSpaces();
      if (_textPointer < _currentLine.length && _getCurrentChar() == 44) { // comma
        _advanceTextPointer(); // Skip comma
        _skipSpaces();
      } else {
        break; // No more line numbers
      }
    }

    // Check if we have any line numbers
    if (lineNumbers.isEmpty) {
      throw InterpreterException('SYNTAX ERROR - No line numbers in ON statement');
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
    if (_getCurrentChar() == 34) { // Double quote
      _advanceTextPointer(); // Skip opening quote
      final promptStart = _textPointer;

      // Find closing quote
      while (_textPointer < _currentLine.length && _getCurrentChar() != 34) {
        _advanceTextPointer();
      }

      if (_textPointer >= _currentLine.length) {
        throw InterpreterException('SYNTAX ERROR - Unterminated string in INPUT');
      }

      // Extract prompt string
      prompt = String.fromCharCodes(
        _currentLine.sublist(promptStart, _textPointer)
      );

      _advanceTextPointer(); // Skip closing quote
      _skipSpaces();

      // Check for required semicolon after prompt
      if (_getCurrentChar() != 59) { // Semicolon
        throw InterpreterException('SYNTAX ERROR - Missing semicolon after INPUT prompt');
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
      if (_textPointer >= _currentLine.length || _getCurrentChar() != 44) { // Comma
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

  /// Skip to matching NEXT statement for a given variable
  void _skipToMatchingNext(String variableName) {
    int forNestLevel = 1;

    while (true) {
      // Advance to next statement/line
      _advanceToNextLine();

      if (_currentLineNumber == -1) {
        throw InterpreterException('FOR WITHOUT NEXT - Missing NEXT statement for variable $variableName');
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
            if (_textPointer < _currentLine.length && _isLetter(_getCurrentChar())) {
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

  /// Execute program until completion
  void runProgram() {
    int maxSteps = 10000; // Prevent infinite loops
    int stepCount = 0;

    while (_state == ExecutionState.program && stepCount < maxSteps) {
      try {
        _executeNextStatement();
        stepCount++;
      } catch (e) {
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
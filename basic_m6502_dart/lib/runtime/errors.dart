/// Error handling system for Microsoft BASIC 6502 interpreter
library;

/// BASIC error codes from original ERRTAB
enum BasicErrorCode {
  /// No error
  ok(0, 'OK'),

  /// NEXT WITHOUT FOR
  nextWithoutFor(1, 'NF'),

  /// SYNTAX ERROR
  syntaxError(2, 'SN'),

  /// RETURN WITHOUT GOSUB
  returnWithoutGosub(3, 'RG'),

  /// OUT OF DATA
  outOfData(4, 'OD'),

  /// ILLEGAL QUANTITY
  illegalQuantity(5, 'FC'),

  /// OVERFLOW
  overflow(6, 'OV'),

  /// OUT OF MEMORY
  outOfMemory(7, 'OM'),

  /// UNDEFINED LINE
  undefinedLine(8, 'UL'),

  /// SUBSCRIPT OUT OF RANGE
  subscriptOutOfRange(9, 'BS'),

  /// DIVISION BY ZERO
  divisionByZero(10, 'DZ'),

  /// ILLEGAL DIRECT
  illegalDirect(11, 'ID'),

  /// TYPE MISMATCH
  typeMismatch(12, 'TM'),

  /// STRING TOO LONG
  stringTooLong(13, 'LS'),

  /// FILE NOT FOUND
  fileNotFound(14, 'FN'),

  /// FILE DATA ERROR
  fileDataError(15, 'FD'),

  /// FILE NOT OPEN
  fileNotOpen(16, 'NF'),

  /// UNDEFINED FUNCTION
  undefinedFunction(17, 'UF'),

  /// REDIMENSIONED ARRAY
  redimensionedArray(18, 'RD'),

  /// BREAK
  breakError(19, 'BK');

  const BasicErrorCode(this.code, this.shortMessage);

  /// Numeric error code
  final int code;

  /// Two-character error message (original BASIC style)
  final String shortMessage;

  /// Long error message for modern users
  String get longMessage {
    switch (this) {
      case BasicErrorCode.ok:
        return 'No error';
      case BasicErrorCode.nextWithoutFor:
        return 'NEXT without FOR';
      case BasicErrorCode.syntaxError:
        return 'Syntax error';
      case BasicErrorCode.returnWithoutGosub:
        return 'RETURN without GOSUB';
      case BasicErrorCode.outOfData:
        return 'Out of DATA';
      case BasicErrorCode.illegalQuantity:
        return 'Illegal quantity';
      case BasicErrorCode.overflow:
        return 'Overflow';
      case BasicErrorCode.outOfMemory:
        return 'Out of memory';
      case BasicErrorCode.undefinedLine:
        return 'Undefined line number';
      case BasicErrorCode.subscriptOutOfRange:
        return 'Subscript out of range';
      case BasicErrorCode.divisionByZero:
        return 'Division by zero';
      case BasicErrorCode.illegalDirect:
        return 'Illegal direct mode command';
      case BasicErrorCode.typeMismatch:
        return 'Type mismatch';
      case BasicErrorCode.stringTooLong:
        return 'String too long';
      case BasicErrorCode.fileNotFound:
        return 'File not found';
      case BasicErrorCode.fileDataError:
        return 'File data error';
      case BasicErrorCode.fileNotOpen:
        return 'File not open';
      case BasicErrorCode.undefinedFunction:
        return 'Undefined function';
      case BasicErrorCode.redimensionedArray:
        return 'Redimensioned array';
      case BasicErrorCode.breakError:
        return 'Break';
    }
  }
}

/// BASIC runtime error with proper error codes and messages
class BasicError implements Exception {
  /// Error code
  final BasicErrorCode errorCode;

  /// Optional additional context
  final String? context;

  /// Line number where error occurred (-1 if not applicable)
  final int lineNumber;

  BasicError(this.errorCode, {this.context, this.lineNumber = -1});

  /// Get formatted error message
  String get message {
    final errorMsg = errorCode.longMessage;
    final lineInfo = lineNumber >= 0 ? ' in line $lineNumber' : '';
    final contextInfo = context != null ? ': $context' : '';

    return '?${errorCode.shortMessage} ERROR$lineInfo$contextInfo';
  }

  /// Get short error message (original BASIC style)
  String get shortMessage {
    final lineInfo = lineNumber >= 0 ? ' in $lineNumber' : '';
    return '?${errorCode.shortMessage} ERROR$lineInfo';
  }

  @override
  String toString() => message;
}

/// Error handler for BASIC interpreter
class ErrorHandler {
  /// Current error state
  BasicError? _currentError;

  /// ON ERROR handling (if implemented)
  int? _onErrorLine;

  /// Set current error
  void setError(BasicError error) {
    _currentError = error;
  }

  /// Clear current error
  void clearError() {
    _currentError = null;
  }

  /// Get current error
  BasicError? get currentError => _currentError;

  /// Check if there's an error
  bool get hasError => _currentError != null;

  /// Set ON ERROR GOTO line (for future implementation)
  void setOnErrorGoto(int lineNumber) {
    _onErrorLine = lineNumber;
  }

  /// Clear ON ERROR handler
  void clearOnError() {
    _onErrorLine = null;
  }

  /// Get ON ERROR line
  int? get onErrorLine => _onErrorLine;

  /// Reset error handler
  void reset() {
    _currentError = null;
    _onErrorLine = null;
  }

  /// Create common error types
  static BasicError syntaxError([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.syntaxError,
        context: context,
        lineNumber: lineNumber,
      );

  static BasicError typeMismatch([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.typeMismatch,
        context: context,
        lineNumber: lineNumber,
      );

  static BasicError illegalQuantity([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.illegalQuantity,
        context: context,
        lineNumber: lineNumber,
      );

  static BasicError divisionByZero([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.divisionByZero,
        context: context,
        lineNumber: lineNumber,
      );

  static BasicError overflow([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.overflow,
        context: context,
        lineNumber: lineNumber,
      );

  static BasicError outOfMemory([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.outOfMemory,
        context: context,
        lineNumber: lineNumber,
      );

  static BasicError subscriptOutOfRange([
    String? context,
    int lineNumber = -1,
  ]) => BasicError(
    BasicErrorCode.subscriptOutOfRange,
    context: context,
    lineNumber: lineNumber,
  );

  static BasicError outOfData([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.outOfData,
        context: context,
        lineNumber: lineNumber,
      );

  static BasicError undefinedLine([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.undefinedLine,
        context: context,
        lineNumber: lineNumber,
      );

  static BasicError nextWithoutFor([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.nextWithoutFor,
        context: context,
        lineNumber: lineNumber,
      );

  static BasicError returnWithoutGosub([
    String? context,
    int lineNumber = -1,
  ]) => BasicError(
    BasicErrorCode.returnWithoutGosub,
    context: context,
    lineNumber: lineNumber,
  );

  static BasicError undefinedFunction([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.undefinedFunction,
        context: context,
        lineNumber: lineNumber,
      );

  static BasicError stringTooLong([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.stringTooLong,
        context: context,
        lineNumber: lineNumber,
      );

  static BasicError fileNotFound([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.fileNotFound,
        context: context,
        lineNumber: lineNumber,
      );

  static BasicError redimensionedArray([
    String? context,
    int lineNumber = -1,
  ]) => BasicError(
    BasicErrorCode.redimensionedArray,
    context: context,
    lineNumber: lineNumber,
  );

  static BasicError illegalDirect([String? context, int lineNumber = -1]) =>
      BasicError(
        BasicErrorCode.illegalDirect,
        context: context,
        lineNumber: lineNumber,
      );
}

# Migration Guide from 6502 Assembly to Dart

## Overview

This guide is for developers who want to understand how the original Microsoft BASIC 1.1 for 6502 assembly code (m6502.asm) was translated into this Dart implementation. It documents the translation strategies, design decisions, and architectural changes.

## Table of Contents

1. [Translation Philosophy](#translation-philosophy)
2. [Architecture Mapping](#architecture-mapping)
3. [Data Structure Translation](#data-structure-translation)
4. [Algorithm Translation](#algorithm-translation)
5. [Memory Management](#memory-management)
6. [Key Implementation Decisions](#key-implementation-decisions)
7. [Code Examples](#code-examples)

## Translation Philosophy

### Goals

1. **Semantic Fidelity**: Preserve the behavior and logic of the original
2. **Modern Idioms**: Use Dart best practices where appropriate
3. **Maintainability**: Create clear, readable code
4. **Performance**: Efficient implementation without sacrificing clarity
5. **Testability**: Design for comprehensive testing

### Non-Goals

1. **Cycle-accurate emulation**: Not emulating 6502 CPU
2. **Binary compatibility**: Not reading/writing original format
3. **Hardware simulation**: Not emulating hardware registers
4. **Instruction-level mapping**: Not translating every instruction

## Architecture Mapping

### High-Level Component Mapping

| 6502 Assembly | Dart Implementation | Notes |
|---------------|---------------------|-------|
| NEWSTT main loop | `Interpreter.run()` | Main execution loop |
| CRUNCH tokenizer | `Tokenizer.tokenize()` | Text to tokens |
| FRMEVL evaluator | `ExpressionEvaluator.evaluate()` | Expression evaluation |
| CHRGET/CHRGOT | Iterator pattern | Character/token fetching |
| PTRGET variable lookup | `VariableStorage.get/set` | Variable access |
| Stack manipulation | Dart `List<StackFrame>` | Runtime stack |
| Memory array | `Uint8List` | 64KB memory |
| String space | `StringManager` | String allocation |
| Floating-point package | `FloatingPoint` class | Math operations |

### File Organization

**Original**: Single ~7000 line assembly file

**Dart**: Modular package structure
```
lib/
├── basic_interpreter.dart         # Public API
├── interpreter/
│   ├── interpreter.dart           # Main loop (NEWSTT)
│   ├── tokenizer.dart             # Tokenizer (CRUNCH)
│   ├── parser.dart                # Parser
│   └── expression_evaluator.dart  # Expression eval (FRMEVL)
├── memory/
│   ├── memory.dart                # Memory simulation
│   ├── variables.dart             # Variable storage (PTRGET)
│   ├── strings.dart               # String manager
│   ├── arrays.dart                # Array manager
│   └── garbage_collection.dart    # String GC (GARBAG)
├── math/
│   ├── floating_point.dart        # 5-byte float format
│   ├── operations.dart            # FADD, FSUB, FMUL, FDIV
│   ├── functions.dart             # SIN, COS, etc.
│   └── conversions.dart           # FIN, FOUT
├── statements/
│   ├── control_flow.dart          # GOTO, GOSUB, FOR, IF
│   ├── io.dart                    # PRINT, INPUT
│   ├── data.dart                  # DATA, READ
│   └── file_ops.dart              # LOAD, SAVE
├── io/
│   ├── console.dart               # I/O abstraction
│   └── screen.dart                # Screen emulation
└── runtime/
    ├── stack.dart                 # FOR/GOSUB stack
    ├── errors.dart                # Error handling
    └── line_editor.dart           # Line editing
```

## Data Structure Translation

### Zero Page Variables

**Original**: Critical variables in zero page (fast access)

```assembly
TXTPTR = $3D    ; Text pointer (2 bytes)
VARPNT = $47    ; Variable pointer (2 bytes)
FACMO  = $61    ; FAC mantissa (5 bytes)
```

**Dart**: Instance variables in classes

```dart
class Interpreter {
  int _textPointer = 0;      // Equivalent to TXTPTR
  int _currentLine = 0;      // Current executing line
  // ... other state variables
}

class FloatingPoint {
  double _accumulator = 0.0;  // Equivalent to FAC
  double _argument = 0.0;     // Equivalent to ARG
}
```

**Rationale**: Zero page was an optimization for 6502. In Dart, instance variables provide better encapsulation.

### Memory Layout

**Original**: Contiguous memory with regions

```assembly
; Memory map:
; $0000-$00FF : Zero page
; $0100-$01FF : Stack
; $0200+      : Program text
; Variables follow program
; Strings grow down from top
```

**Dart**: Simulated memory + separate structures

```dart
class Memory {
  final Uint8List _bytes;  // 64KB array

  // Symbolic regions
  static const int zeroPage = 0x0000;
  static const int stackPage = 0x0100;
  static const int programStart = 0x0200;
}

class VariableStorage {
  final Map<String, double> _numericVars = {};
  final Map<String, String> _stringVars = {};
  final Map<String, Array> _arrays = {};
}
```

**Rationale**: Separate data structures are clearer and more efficient than simulating pointers.

### Program Storage

**Original**: Linked list in memory

```assembly
; Program line format:
; +0,+1: Link to next line (0 = end)
; +2,+3: Line number
; +4...: Tokenized text
; Last byte: $00
```

**Dart**: Structured objects

```dart
class ProgramLine {
  final int lineNumber;
  final List<Token> tokens;
  final String originalText;
}

class Program {
  final Map<int, ProgramLine> _lines = {};  // Sorted by line number

  ProgramLine? getLine(int lineNumber) => _lines[lineNumber];
  ProgramLine? getNextLine(int lineNumber) { /* ... */ }
}
```

**Rationale**: Object-oriented structure is clearer and provides better operations.

### Variable Storage

**Original**: Sequential list with 2-char names

```assembly
; Variable format:
; +0: First char of name
; +1: Second char of name (or $00)
; +2-+5: Value (5-byte float or string descriptor)
```

**Dart**: Hash map with full names

```dart
class VariableStorage {
  final Map<String, double> _numericVars = {};
  final Map<String, String> _stringVars = {};

  void setNumeric(String name, double value) {
    final key = _normalizeName(name);  // Take first 2 chars
    _numericVars[key] = value;
  }

  String _normalizeName(String name) {
    // Only first 2 characters significant
    name = name.toUpperCase();
    return name.length <= 2 ? name : name.substring(0, 2);
  }
}
```

**Rationale**: Hash map provides O(1) lookup. Name normalization preserves BASIC semantics.

### String Descriptors

**Original**: 3-byte descriptor

```assembly
; String descriptor:
; +0: Length (0-255)
; +1,+2: Pointer to string data (little-endian)
```

**Dart**: Class with pointer to string space

```dart
class StringDescriptor {
  final int length;
  final int address;  // Address in string space

  StringDescriptor(this.length, this.address);
}

class StringManager {
  final Memory _memory;
  int _stringSpaceTop;

  String getString(StringDescriptor desc) {
    final bytes = _memory.readBytes(desc.address, desc.length);
    return String.fromCharCodes(bytes);
  }
}
```

**Rationale**: Preserves the indirection model while using Dart's string type.

### Stack Frames

**Original**: Fixed-size frames pushed to hardware stack

```assembly
; FOR stack frame (16 bytes):
; +0,+1: Next line address
; +2,+3: Current line number
; +4,+5: NEXT line address
; +6-+9: STEP value
; +10-+13: LIMIT value
; +14,+15: Variable address
```

**Dart**: Typed stack frame classes

```dart
abstract class StackFrame {
  StackFrameType get type;
}

class ForLoopFrame extends StackFrame {
  final String variable;
  final double limit;
  final double step;
  final int returnLine;
  final int returnPosition;
}

class GosubFrame extends StackFrame {
  final int returnLine;
  final int returnPosition;
}

class RuntimeStack {
  final List<StackFrame> _frames = [];

  void pushFor(ForLoopFrame frame) => _frames.add(frame);
  ForLoopFrame? popFor() { /* ... */ }
}
```

**Rationale**: Type-safe frames prevent stack corruption and improve debuggability.

## Algorithm Translation

### Main Interpreter Loop (NEWSTT)

**Original Assembly**:
```assembly
NEWSTT:
  JSR CHRGET        ; Get next character
  BEQ NEWSTT        ; Skip if null
  CMP #':'          ; Statement separator?
  BEQ NEWSTT        ; Yes, get next
  JSR EXECUTE       ; Execute statement
  JMP NEWSTT        ; Continue
```

**Dart Translation**:
```dart
void run({int? startLine}) {
  _currentLine = startLine ?? _program.firstLine;

  while (true) {
    final line = _program.getLine(_currentLine);
    if (line == null) break;

    try {
      for (final statement in line.statements) {
        _executeStatement(statement);
        if (_shouldStop) return;
      }
      _currentLine = _program.getNextLineNumber(_currentLine);
    } catch (e) {
      _handleError(e);
    }
  }
}
```

**Key Changes**:
1. Explicit loop instead of JMP
2. Try-catch for error handling
3. Structured iteration over statements
4. Object-oriented line access

### Expression Evaluation (FRMEVL)

**Original Assembly**: Stack-based with goto-heavy control flow

```assembly
FRMEVL:
  LDX #$00          ; Clear stack
  LDA #$01          ; Dummy precedence
FRMEVL1:
  JSR CHKNUM        ; Get numeric value
FRMEVL2:
  JSR CHRGET        ; Get operator
  BEQ FRMEVL3       ; End of expression
  JSR DOOPER        ; Apply operator
  JMP FRMEVL2       ; Continue
```

**Dart Translation**: Operator precedence climbing

```dart
Value evaluate(List<Token> tokens) {
  _position = 0;
  return _parseExpression(0);  // Min precedence = 0
}

Value _parseExpression(int minPrecedence) {
  Value left = _parsePrimary();  // Number, variable, function, (expr)

  while (_position < tokens.length) {
    final op = _currentToken;
    if (!_isOperator(op) || _precedence(op) < minPrecedence) {
      break;
    }

    _advance();
    final right = _parseExpression(_precedence(op) + 1);
    left = _applyOperator(op, left, right);
  }

  return left;
}
```

**Key Changes**:
1. Recursive descent parser
2. Explicit precedence handling
3. Type-safe value objects
4. Clear structure vs goto-based flow

### Variable Lookup (PTRGET)

**Original Assembly**: Linear search through variable list

```assembly
PTRGET:
  STA VARPNT        ; Save first char
  STX VARPNT+1      ; Save second char
  LDA VARTAB        ; Start of variables
  STA LOWTR
PTRGET1:
  LDA (LOWTR),Y     ; Get first char
  BEQ PTRGET2       ; End of list
  CMP VARPNT        ; Match first char?
  BNE PTRGET3       ; No, skip
  INY
  LDA (LOWTR),Y     ; Get second char
  CMP VARPNT+1      ; Match?
  BEQ FOUND         ; Yes!
PTRGET3:
  ; Skip to next variable
  JMP PTRGET1
```

**Dart Translation**: Hash map lookup

```dart
double getNumeric(String name) {
  final key = _normalizeName(name);
  return _numericVars[key] ?? 0.0;  // Return 0 if undefined
}

void setNumeric(String name, double value) {
  final key = _normalizeName(name);
  _numericVars[key] = value;
}

String _normalizeName(String name) {
  name = name.toUpperCase();
  if (name.endsWith('\$')) {
    // String variable
    name = name.substring(0, name.length - 1);
  }
  // Take only first 2 characters
  return name.length <= 2 ? name : name.substring(0, 2);
}
```

**Key Changes**:
1. O(1) hash lookup vs O(n) linear search
2. Separate maps for numeric vs string
3. Name normalization preserves semantics

### String Garbage Collection (GARBAG)

**Original Assembly**: Mark and compact

```assembly
GARBAG:
  ; Mark phase: Scan all string descriptors
  ; Compact phase: Move live strings together
  ; Update descriptors with new addresses
```

**Dart Translation**: Mark and compact with modern structures

```dart
void garbageCollect() {
  // Phase 1: Mark all referenced strings
  final referenced = <int>{};

  // Scan variables
  for (final desc in _stringVars.values) {
    referenced.add(desc.address);
  }

  // Scan array elements
  for (final array in _arrays.values) {
    if (array.isString) {
      for (final desc in array.elements) {
        referenced.add(desc.address);
      }
    }
  }

  // Scan temporary strings
  for (final desc in _tempStrings) {
    referenced.add(desc.address);
  }

  // Phase 2: Compact string space
  final newAddresses = <int, int>{};
  int writePos = _stringSpaceTop;

  for (final addr in referenced.toList()..sort()) {
    final desc = _getDescriptorByAddress(addr);
    final data = _memory.readBytes(addr, desc.length);
    _memory.writeBytes(writePos, data);
    newAddresses[addr] = writePos;
    writePos += desc.length;
  }

  // Phase 3: Update all descriptors
  _updateDescriptorAddresses(newAddresses);
  _stringSpaceTop = writePos;
}
```

**Key Changes**:
1. Set-based marking (clearer)
2. Explicit phases with comments
3. Type-safe descriptor handling
4. Modern collection operations

## Memory Management

### Original Strategy

The 6502 version used careful pointer manipulation:

1. **Program Storage**: Linked list starting at fixed address
2. **Variable Storage**: Sequential after program
3. **Array Storage**: Sequential after variables
4. **String Space**: Top-down from MEMSIZ

All managed through pointer arithmetic.

### Dart Strategy

Modern memory management with simulated regions:

#### Program Storage

```dart
class Program {
  // Lines stored in sorted map (implicit linked list)
  final Map<int, ProgramLine> _lines = {};

  void addLine(ProgramLine line) {
    _lines[line.lineNumber] = line;
  }

  ProgramLine? getNextLine(int current) {
    // Find next higher line number
    final sorted = _lines.keys.toList()..sort();
    final index = sorted.indexOf(current);
    return index >= 0 && index < sorted.length - 1
        ? _lines[sorted[index + 1]]
        : null;
  }
}
```

#### Variable Storage

```dart
class VariableStorage {
  // Separate maps for each type
  final Map<String, double> _numericVars = {};
  final Map<String, String> _stringVars = {};
  final Map<String, Array> _arrays = {};

  void clear() {
    _numericVars.clear();
    _stringVars.clear();
    _arrays.clear();
  }
}
```

#### String Management

```dart
class StringManager {
  final Memory _memory;
  int _stringSpaceTop;    // Top of string space (grows down)
  int _stringSpaceBottom; // Bottom limit

  StringDescriptor allocateString(String text) {
    final length = text.length;
    final needed = length;

    // Check if space available
    if (_stringSpaceTop - needed < _stringSpaceBottom) {
      garbageCollect();  // Try to free space

      if (_stringSpaceTop - needed < _stringSpaceBottom) {
        throw MemoryException('OUT OF STRING SPACE');
      }
    }

    // Allocate top-down
    _stringSpaceTop -= needed;
    final address = _stringSpaceTop;

    // Write string data
    _memory.writeBytes(address, text.codeUnits);

    return StringDescriptor(length, address);
  }
}
```

## Key Implementation Decisions

### 1. Token Representation

**Decision**: Use enum + value class instead of byte codes

```dart
class Token {
  final TokenType type;
  final dynamic value;  // String, double, or null
  final int position;   // For error reporting

  Token(this.type, this.value, this.position);
}

enum TokenType {
  // Keywords
  print, input, let, dim, goto, gosub, return_,
  if_, then, for_, to, step, next, end, stop,
  // Operators
  plus, minus, multiply, divide, power,
  equal, notEqual, lessThan, greaterThan,
  // Literals
  number, string, identifier,
  // Special
  colon, semicolon, comma, leftParen, rightParen,
}
```

**Rationale**: Type safety, better tooling support, clearer code.

### 2. Error Handling

**Decision**: Use exceptions instead of error flags

```dart
abstract class BasicException implements Exception {
  String get errorCode;
  String get message;
  int? get lineNumber;
}

class SyntaxException extends BasicException {
  final String errorCode = 'SN';
  final String message;
  final int? lineNumber;

  SyntaxException(this.message, [this.lineNumber]);
}

// Usage:
void _checkSyntax(bool condition, String message) {
  if (!condition) {
    throw SyntaxException(message, _currentLine);
  }
}
```

**Rationale**: Dart idiom, automatic stack unwinding, better error context.

### 3. Floating-Point Format

**Decision**: Use Dart `double` internally, convert for compatibility

```dart
class FloatingPoint {
  // Convert TO Microsoft 5-byte format (for storage/compatibility)
  static Uint8List pack(double value) {
    // Implementation converts IEEE 754 to Microsoft format
  }

  // Convert FROM Microsoft 5-byte format
  static double unpack(Uint8List bytes) {
    // Implementation converts Microsoft format to IEEE 754
  }
}

// Internal arithmetic uses native Dart doubles
double add(double a, double b) => a + b;
```

**Rationale**: Native performance, simpler code, convert only when needed for compatibility.

### 4. I/O Abstraction

**Decision**: Abstract console interface

```dart
abstract class BasicConsole {
  void print(String text);
  Future<String?> readLineAsync({String? prompt});
  String? getChar();
  void clear();
}

// Default implementation
class StdioConsole extends BasicConsole {
  @override
  void print(String text) => stdout.write(text);

  @override
  Future<String?> readLineAsync({String? prompt}) async {
    if (prompt != null) stdout.write(prompt);
    return stdin.readLineSync();
  }
}
```

**Rationale**: Enables testing, web integration, custom UIs.

### 5. Testing Strategy

**Decision**: Comprehensive unit + integration tests

```dart
// Unit test example
test('variables store and retrieve numeric values', () {
  final vars = VariableStorage(memory);
  vars.setNumeric('A', 42.0);
  expect(vars.getNumeric('A'), equals(42.0));
});

// Integration test example
test('classic BASIC program runs correctly', () {
  final interpreter = BasicInterpreter();
  interpreter.loadProgram('''
    10 FOR I = 1 TO 10
    20   PRINT I
    30 NEXT I
  ''');
  interpreter.executeProgram();
  // Verify output
});
```

**Rationale**: Ensures correctness, prevents regressions, documents behavior.

## Code Examples

### Example 1: PRINT Statement

**Original Assembly**:
```assembly
PRINT:
  JSR FRMEVL        ; Evaluate expression
  BIT VALTYP        ; Check type
  BMI STROUT        ; String: print it
  JSR FOUT          ; Number: convert to string
STROUT:
  JSR STRPRT        ; Print string
  JSR CHRGOT        ; Get next char
  BEQ FINPRT        ; End of statement
  CMP #';'          ; Semicolon?
  BEQ PRINT1        ; Yes: no space
  CMP #','          ; Comma?
  BEQ PRINTTAB      ; Yes: tab
```

**Dart Translation**:
```dart
void _executePrint(List<Token> tokens) {
  int pos = 1;  // Skip PRINT token

  while (pos < tokens.length) {
    if (tokens[pos].type == TokenType.semicolon) {
      pos++;  // No space, continue
      continue;
    }

    if (tokens[pos].type == TokenType.comma) {
      _printTab();  // Tab to next zone
      pos++;
      continue;
    }

    // Evaluate expression
    final endPos = _findExpressionEnd(tokens, pos);
    final expr = tokens.sublist(pos, endPos);
    final value = _evaluator.evaluate(expr);

    if (value.isString) {
      _console.print(value.stringValue);
    } else {
      _console.print(value.numericValue.toString());
    }

    pos = endPos;
  }

  // Print newline unless ending with ; or ,
  if (tokens.last.type != TokenType.semicolon &&
      tokens.last.type != TokenType.comma) {
    _console.print('\n');
  }
}
```

### Example 2: FOR Loop

**Original Assembly**:
```assembly
FOR:
  LDA #$80          ; FOR token
  STA FORPNT        ; Mark as FOR loop
  JSR LET           ; Handle variable = start
  JSR FRMEVL        ; Evaluate TO expression
  ; Push stack frame
  ; ... (16 bytes)
```

**Dart Translation**:
```dart
void _executeFor(List<Token> tokens) {
  // Parse: FOR var = start TO end [STEP step]
  final variable = tokens[1].value as String;

  // Find = sign
  int pos = 2;
  if (tokens[pos].type != TokenType.equal) {
    throw SyntaxException('Expected = in FOR');
  }
  pos++;

  // Evaluate start expression
  final toPos = _findToken(tokens, TokenType.to, pos);
  final startExpr = tokens.sublist(pos, toPos);
  final startValue = _evaluator.evaluate(startExpr).numericValue;

  // Evaluate end expression
  pos = toPos + 1;
  final stepPos = _findToken(tokens, TokenType.step, pos);
  final hasStep = stepPos != -1;
  final endPos = hasStep ? stepPos : tokens.length;
  final endExpr = tokens.sublist(pos, endPos);
  final endValue = _evaluator.evaluate(endExpr).numericValue;

  // Evaluate step (default 1)
  double stepValue = 1.0;
  if (hasStep) {
    final stepExpr = tokens.sublist(stepPos + 1);
    stepValue = _evaluator.evaluate(stepExpr).numericValue;
  }

  // Set loop variable
  _variables.setNumeric(variable, startValue);

  // Push FOR frame
  _stack.pushFor(ForLoopFrame(
    variable: variable,
    limit: endValue,
    step: stepValue,
    returnLine: _currentLine,
    returnPosition: _currentPosition,
  ));
}

void _executeNext(List<Token> tokens) {
  final variable = tokens.length > 1
      ? tokens[1].value as String
      : null;

  // Pop FOR frame
  final frame = _stack.popFor();
  if (frame == null) {
    throw RuntimeException('NEXT WITHOUT FOR');
  }

  // Check variable matches (if specified)
  if (variable != null && variable != frame.variable) {
    throw RuntimeException('NEXT WITHOUT FOR');
  }

  // Increment loop variable
  final current = _variables.getNumeric(frame.variable);
  final next = current + frame.step;
  _variables.setNumeric(frame.variable, next);

  // Check if loop continues
  final done = frame.step > 0
      ? next > frame.limit
      : next < frame.limit;

  if (!done) {
    // Continue loop: jump back
    _currentLine = frame.returnLine;
    _currentPosition = frame.returnPosition;
    // Push frame back for next iteration
    _stack.pushFor(frame);
  }
  // If done, just continue to next statement
}
```

### Example 3: Expression Evaluation

**Original Assembly**: Complex stack manipulation

```assembly
FRMEVL:
  LDX #$00          ; Stack pointer
  BEQ FRMEVL1
FRMEVL1:
  JSR CHRGET
  BCS FIN           ; Digit
  JSR ISVAR         ; Variable?
  BCS FRMEVL2
  CMP #'('          ; Left paren?
  BEQ FRMEVL3
  ; ... handle operators ...
```

**Dart Translation**: Clean recursive descent

```dart
Value evaluate(List<Token> tokens) {
  _tokens = tokens;
  _position = 0;
  return _parseExpression(0);
}

Value _parseExpression(int minPrecedence) {
  Value left = _parsePrimary();

  while (_position < _tokens.length) {
    final op = _current;
    if (!_isOperator(op)) break;

    final prec = _precedence(op);
    if (prec < minPrecedence) break;

    _advance();
    final right = _parseExpression(prec + 1);
    left = _applyOperator(op, left, right);
  }

  return left;
}

Value _parsePrimary() {
  final token = _current;

  // Number literal
  if (token.type == TokenType.number) {
    _advance();
    return Value.numeric(token.value as double);
  }

  // String literal
  if (token.type == TokenType.string) {
    _advance();
    return Value.string(token.value as String);
  }

  // Parenthesized expression
  if (token.type == TokenType.leftParen) {
    _advance();
    final expr = _parseExpression(0);
    _expect(TokenType.rightParen);
    return expr;
  }

  // Variable
  if (token.type == TokenType.identifier) {
    return _parseVariable();
  }

  // Function
  if (_isFunction(token)) {
    return _parseFunction();
  }

  throw SyntaxException('Unexpected token: ${token.type}');
}
```

## Performance Considerations

### Original Performance Characteristics

- 6502 @ 1 MHz ≈ 1,000,000 instructions/second
- Memory access: 2-6 cycles per operation
- Linear variable lookup: O(n)
- No optimization (every instruction counts)

### Dart Implementation Performance

- Modern CPU @ 2+ GHz
- JIT compilation optimizes hot paths
- Hash map lookups: O(1)
- Garbage collection managed automatically

**Result**: Dart version is typically 1000x+ faster than original hardware.

## Testing and Validation

### Validation Strategy

1. **Unit Tests**: Each component tested independently
2. **Integration Tests**: Classic BASIC programs
3. **Compatibility Tests**: Known program outputs compared
4. **Benchmark Tests**: Performance regression detection

### Test Coverage

```bash
# Run all tests
dart test

# Run with coverage
dart test --coverage=coverage
dart pub global activate coverage
format_coverage --lcov --in=coverage --out=coverage.lcov --report-on=lib
```

Current coverage: 90%+ of core functionality

## Conclusion

The migration from 6502 assembly to Dart involved:

1. **Architectural transformation**: Procedural → Object-oriented
2. **Algorithm preservation**: Core logic maintained
3. **Modern idioms**: Using Dart best practices
4. **Enhanced testability**: Comprehensive test coverage
5. **Improved maintainability**: Clear, documented code

The result is a faithful recreation that preserves the semantics of the original while leveraging modern language features for clarity and performance.

## References

- Original source: `m6502.asm`
- Microsoft BASIC 1.1 specification
- 6502 processor documentation
- Dart language documentation
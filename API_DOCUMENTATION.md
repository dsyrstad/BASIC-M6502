# API Documentation

## Overview

This document describes the public API for the Microsoft BASIC 6502 Dart implementation. It is intended for developers who want to integrate the BASIC interpreter into their own applications or extend its functionality.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Classes](#core-classes)
3. [Memory Management](#memory-management)
4. [Interpreter API](#interpreter-api)
5. [Math Package](#math-package)
6. [I/O System](#io-system)
7. [Extension Points](#extension-points)

## Architecture Overview

The interpreter is organized into several major subsystems:

```
┌─────────────────────────────────────────┐
│         BasicInterpreter                │
│         (Main Entry Point)              │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴───────┐
       │               │
       ▼               ▼
┌──────────────┐  ┌──────────────┐
│  Interpreter │  │    Memory    │
│   (Executor) │  │  Management  │
└──────┬───────┘  └──────┬───────┘
       │                 │
       │        ┌────────┴────────┐
       │        │                 │
       ▼        ▼                 ▼
┌──────────┐ ┌─────────┐  ┌─────────────┐
│   Math   │ │Variables│  │   Strings   │
│ Package  │ │ & Arrays│  │ & Garbage   │
└──────────┘ └─────────┘  └─────────────┘
       │
       ▼
┌──────────────┐
│  I/O System  │
│  (Console)   │
└──────────────┘
```

## Core Classes

### BasicInterpreter

Main entry point for the interpreter.

**Location**: `lib/basic_interpreter.dart`

#### Constructor

```dart
BasicInterpreter({
  BasicConsole? console,
  int memorySize = 65536,
})
```

Creates a new BASIC interpreter instance.

**Parameters**:
- `console` - Optional console for I/O (defaults to stdin/stdout)
- `memorySize` - Size of simulated memory (default: 64KB)

**Example**:
```dart
import 'package:basic_m6502/basic_interpreter.dart';

void main() {
  final interpreter = BasicInterpreter();
  interpreter.run();
}
```

#### Methods

##### run()

```dart
Future<void> run()
```

Starts the interactive REPL (Read-Eval-Print Loop).

**Example**:
```dart
await interpreter.run();
```

##### executeLine(String line)

```dart
void executeLine(String line)
```

Executes a single line of BASIC code (immediate mode).

**Parameters**:
- `line` - BASIC statement to execute

**Throws**: `BasicException` on syntax or runtime errors

**Example**:
```dart
interpreter.executeLine('PRINT "HELLO"');
```

##### executeProgram()

```dart
void executeProgram({int? startLine})
```

Executes the currently loaded program.

**Parameters**:
- `startLine` - Optional line number to start from

**Example**:
```dart
interpreter.executeProgram();
interpreter.executeProgram(startLine: 100);
```

##### loadProgram(String source)

```dart
void loadProgram(String source)
```

Loads a BASIC program from source text.

**Parameters**:
- `source` - Multi-line BASIC program source

**Example**:
```dart
final program = '''
10 PRINT "HELLO"
20 END
''';
interpreter.loadProgram(program);
interpreter.executeProgram();
```

##### loadProgramFromFile(String filename)

```dart
Future<void> loadProgramFromFile(String filename)
```

Loads a BASIC program from a file.

**Parameters**:
- `filename` - Path to BASIC program file

**Example**:
```dart
await interpreter.loadProgramFromFile('examples/hello.bas');
```

##### saveProgramToFile(String filename)

```dart
Future<void> saveProgramToFile(String filename)
```

Saves the current program to a file.

**Parameters**:
- `filename` - Path to save file

**Example**:
```dart
await interpreter.saveProgramToFile('saved_program.bas');
```

##### listProgram({int? startLine, int? endLine})

```dart
String listProgram({int? startLine, int? endLine})
```

Returns the program listing as a string.

**Parameters**:
- `startLine` - Optional starting line number
- `endLine` - Optional ending line number

**Returns**: Program listing

**Example**:
```dart
print(interpreter.listProgram());
print(interpreter.listProgram(startLine: 100, endLine: 200));
```

##### reset()

```dart
void reset()
```

Resets the interpreter (clears program and variables).

**Example**:
```dart
interpreter.reset();
```

##### clear()

```dart
void clear()
```

Clears all variables but keeps the program.

**Example**:
```dart
interpreter.clear();
```

#### Properties

##### memory

```dart
Memory get memory
```

Access to the underlying memory system.

**Example**:
```dart
final value = interpreter.memory.readByte(0x1000);
```

##### variables

```dart
VariableStorage get variables
```

Access to variable storage.

**Example**:
```dart
interpreter.variables.setNumeric('A', 42.0);
final value = interpreter.variables.getNumeric('A');
```

## Memory Management

### Memory

Simulates 6502 memory space.

**Location**: `lib/memory/memory.dart`

#### Constructor

```dart
Memory([int size = 65536])
```

Creates a memory instance.

**Example**:
```dart
final memory = Memory(65536);
```

#### Methods

##### readByte(int address)

```dart
int readByte(int address)
```

Reads a byte from memory.

**Parameters**:
- `address` - Memory address (0-65535)

**Returns**: Byte value (0-255)

**Example**:
```dart
final value = memory.readByte(0x1000);
```

##### writeByte(int address, int value)

```dart
void writeByte(int address, int value)
```

Writes a byte to memory.

**Parameters**:
- `address` - Memory address (0-65535)
- `value` - Byte value (0-255)

**Example**:
```dart
memory.writeByte(0x1000, 65);
```

##### readWord(int address)

```dart
int readWord(int address)
```

Reads a 16-bit word (little-endian).

**Returns**: Word value (0-65535)

**Example**:
```dart
final word = memory.readWord(0x1000);
```

##### writeWord(int address, int value)

```dart
void writeWord(int address, int value)
```

Writes a 16-bit word (little-endian).

**Example**:
```dart
memory.writeWord(0x1000, 12345);
```

##### dump(int start, int length)

```dart
String dump(int start, int length)
```

Creates a hex dump of memory.

**Example**:
```dart
print(memory.dump(0, 256));
```

### VariableStorage

Manages BASIC variables (simple and arrays).

**Location**: `lib/memory/variables.dart`

#### Methods

##### setNumeric(String name, double value)

```dart
void setNumeric(String name, double value)
```

Sets a numeric variable.

**Example**:
```dart
variables.setNumeric('A', 42.0);
variables.setNumeric('B2', 3.14);
```

##### getNumeric(String name)

```dart
double getNumeric(String name)
```

Gets a numeric variable (returns 0.0 if undefined).

**Example**:
```dart
final value = variables.getNumeric('A');
```

##### setString(String name, String value)

```dart
void setString(String name, String value)
```

Sets a string variable.

**Example**:
```dart
variables.setString('A\$', 'HELLO');
```

##### getString(String name)

```dart
String getString(String name)
```

Gets a string variable (returns empty string if undefined).

**Example**:
```dart
final str = variables.getString('A\$');
```

##### dimensionArray(String name, List<int> dimensions, bool isString)

```dart
void dimensionArray(String name, List<int> dimensions, bool isString)
```

Creates an array.

**Parameters**:
- `name` - Array name
- `dimensions` - List of dimension sizes
- `isString` - true for string array, false for numeric

**Example**:
```dart
variables.dimensionArray('A', [100], false);  // DIM A(100)
variables.dimensionArray('B', [10, 10], false);  // DIM B(10,10)
variables.dimensionArray('C\$', [50], true);  // DIM C$(50)
```

##### setArrayElement(String name, List<int> indices, dynamic value)

```dart
void setArrayElement(String name, List<int> indices, dynamic value)
```

Sets an array element.

**Example**:
```dart
variables.setArrayElement('A', [5], 42.0);
variables.setArrayElement('B', [3, 4], 100.0);
```

##### getArrayElement(String name, List<int> indices)

```dart
dynamic getArrayElement(String name, List<int> indices)
```

Gets an array element.

**Example**:
```dart
final value = variables.getArrayElement('A', [5]);
```

##### clear()

```dart
void clear()
```

Clears all variables.

**Example**:
```dart
variables.clear();
```

### StringManager

Manages string storage with garbage collection.

**Location**: `lib/memory/strings.dart`

#### Methods

##### createString(String text)

```dart
StringDescriptor createString(String text)
```

Creates a string in string space.

**Returns**: String descriptor

**Example**:
```dart
final desc = stringManager.createString('HELLO');
```

##### getString(StringDescriptor descriptor)

```dart
String getString(StringDescriptor descriptor)
```

Retrieves string text from a descriptor.

**Example**:
```dart
final text = stringManager.getString(desc);
```

##### concatenate(StringDescriptor a, StringDescriptor b)

```dart
StringDescriptor concatenate(StringDescriptor a, StringDescriptor b)
```

Concatenates two strings.

**Example**:
```dart
final result = stringManager.concatenate(desc1, desc2);
```

##### substring(StringDescriptor source, int start, int length)

```dart
StringDescriptor substring(StringDescriptor source, int start, int length)
```

Extracts a substring.

**Example**:
```dart
final sub = stringManager.substring(desc, 0, 5);
```

##### garbageCollect()

```dart
void garbageCollect()
```

Performs garbage collection on string space.

**Example**:
```dart
stringManager.garbageCollect();
```

## Interpreter API

### Interpreter

Core interpreter that executes BASIC statements.

**Location**: `lib/interpreter/interpreter.dart`

#### Constructor

```dart
Interpreter({
  required Memory memory,
  required VariableStorage variables,
  required StringManager stringManager,
  required BasicConsole console,
})
```

#### Methods

##### execute(String line)

```dart
void execute(String line)
```

Executes a line of BASIC code.

**Example**:
```dart
interpreter.execute('PRINT "HELLO"');
```

##### run({int? startLine})

```dart
void run({int? startLine})
```

Runs the loaded program.

**Example**:
```dart
interpreter.run();
interpreter.run(startLine: 100);
```

### Tokenizer

Converts BASIC source code to tokens.

**Location**: `lib/interpreter/tokenizer.dart`

#### Methods

##### tokenize(String line)

```dart
List<Token> tokenize(String line)
```

Tokenizes a line of BASIC code.

**Returns**: List of tokens

**Example**:
```dart
final tokens = tokenizer.tokenize('PRINT "HELLO"');
```

### ExpressionEvaluator

Evaluates BASIC expressions.

**Location**: `lib/interpreter/expression_evaluator.dart`

#### Methods

##### evaluate(List<Token> tokens)

```dart
Value evaluate(List<Token> tokens)
```

Evaluates an expression.

**Returns**: Numeric or string value

**Example**:
```dart
final result = evaluator.evaluate(tokens);
```

## Math Package

### FloatingPoint

Microsoft 5-byte floating-point format.

**Location**: `lib/math/floating_point.dart`

#### Static Methods

##### pack(double value)

```dart
static Uint8List pack(double value)
```

Converts Dart double to 5-byte Microsoft format.

**Returns**: 5-byte array

**Example**:
```dart
final bytes = FloatingPoint.pack(3.14159);
```

##### unpack(Uint8List bytes)

```dart
static double unpack(Uint8List bytes)
```

Converts 5-byte Microsoft format to Dart double.

**Example**:
```dart
final value = FloatingPoint.unpack(bytes);
```

### MathOperations

Basic arithmetic operations.

**Location**: `lib/math/operations.dart`

#### Static Methods

```dart
static double add(double a, double b)
static double subtract(double a, double b)
static double multiply(double a, double b)
static double divide(double a, double b)
static double power(double base, double exponent)
static double negate(double value)
```

**Example**:
```dart
final result = MathOperations.add(3.14, 2.71);
```

### MathFunctions

Transcendental and other math functions.

**Location**: `lib/math/functions.dart`

#### Static Methods

```dart
static double sin(double x)
static double cos(double x)
static double tan(double x)
static double atn(double x)
static double exp(double x)
static double log(double x)
static double sqr(double x)
static double abs(double x)
static double sgn(double x)
static double int_(double x)
static double rnd(double x)
```

**Example**:
```dart
final result = MathFunctions.sin(3.14159);
```

## I/O System

### BasicConsole

Abstract interface for console I/O.

**Location**: `lib/io/console.dart`

#### Abstract Methods

```dart
void print(String text)
String? readLine({String? prompt})
Future<String?> readLineAsync({String? prompt})
String? getChar()
void clear()
```

#### Default Implementation: StdioConsole

Uses stdin/stdout for I/O.

**Example**:
```dart
final console = StdioConsole();
console.print('HELLO');
final input = await console.readLineAsync(prompt: '? ');
```

### Custom Console Implementation

You can implement a custom console for integration:

```dart
class MyConsole extends BasicConsole {
  @override
  void print(String text) {
    // Your implementation
  }

  @override
  Future<String?> readLineAsync({String? prompt}) async {
    // Your implementation
  }

  @override
  String? getChar() {
    // Your implementation
  }

  @override
  void clear() {
    // Your implementation
  }

  @override
  String? readLine({String? prompt}) {
    // Your implementation
  }
}

// Use it:
final interpreter = BasicInterpreter(console: MyConsole());
```

### Screen

40-column screen emulation.

**Location**: `lib/io/screen.dart`

#### Methods

##### printAt(int row, int col, String text)

```dart
void printAt(int row, int col, String text)
```

Prints text at specific screen position.

##### clear()

```dart
void clear()
```

Clears the screen.

## Extension Points

### Adding Custom Statements

To add a custom BASIC statement:

1. Add token constant in `lib/interpreter/tokenizer.dart`
2. Add keyword to tokenizer keyword map
3. Add statement handler in `lib/interpreter/interpreter.dart`

**Example**: Adding a custom BEEP statement

```dart
// In tokenizer.dart
class TokenType {
  static const int beep = 0xE0;  // Choose unused token

  static const keywords = {
    // ... existing keywords ...
    'BEEP': beep,
  };
}

// In interpreter.dart
void _executeStatement(Token token) {
  switch (token.type) {
    // ... existing cases ...
    case TokenType.beep:
      _executeBeep();
      break;
  }
}

void _executeBeep() {
  console.print('\x07');  // ASCII bell character
}
```

### Adding Custom Functions

To add a custom function:

1. Add token constant for function
2. Add function handler in expression evaluator

**Example**: Adding a custom SQUARE function

```dart
// In tokenizer.dart
class TokenType {
  static const int fnSquare = 0xE1;

  static const keywords = {
    'SQUARE': fnSquare,
  };
}

// In expression_evaluator.dart
Value _evaluateFunction(Token token, Value argument) {
  switch (token.type) {
    // ... existing cases ...
    case TokenType.fnSquare:
      return Value.numeric(argument.numericValue * argument.numericValue);
  }
}
```

### Implementing File Systems

To add file system support:

1. Implement `FileSystem` interface
2. Pass to interpreter

```dart
abstract class FileSystem {
  Future<String> loadFile(String filename);
  Future<void> saveFile(String filename, String content);
  Future<bool> fileExists(String filename);
  Future<void> deleteFile(String filename);
}

class MyFileSystem implements FileSystem {
  @override
  Future<String> loadFile(String filename) async {
    // Implementation
  }

  // ... other methods ...
}
```

## Error Handling

### BasicException

Base exception class for all BASIC errors.

**Location**: `lib/runtime/errors.dart`

#### Properties

```dart
String get errorCode
String get message
int? get lineNumber
```

#### Subclasses

- `SyntaxException` - Syntax errors
- `RuntimeException` - Runtime errors
- `ExpressionException` - Expression evaluation errors
- `TypeException` - Type mismatch errors
- `MemoryException` - Out of memory errors

**Example**:
```dart
try {
  interpreter.execute('PRINT 1/0');
} on ExpressionException catch (e) {
  print('Error: ${e.message}');
}
```

## Usage Examples

### Embedding the Interpreter

```dart
import 'package:basic_m6502/basic_interpreter.dart';

void main() async {
  final interpreter = BasicInterpreter();

  // Load and run a program
  final program = '''
10 FOR I = 1 TO 10
20   PRINT I
30 NEXT I
''';

  interpreter.loadProgram(program);
  interpreter.executeProgram();
}
```

### Programmatic Control

```dart
import 'package:basic_m6502/basic_interpreter.dart';

void main() {
  final interpreter = BasicInterpreter();

  // Set variables programmatically
  interpreter.variables.setNumeric('X', 42.0);
  interpreter.variables.setString('N\$', 'ALICE');

  // Execute statements
  interpreter.executeLine('PRINT "X ="; X');
  interpreter.executeLine('PRINT "NAME: "; N\$');

  // Read results
  final result = interpreter.variables.getNumeric('X');
  print('Result: $result');
}
```

### Custom I/O Integration

```dart
import 'package:basic_m6502/basic_interpreter.dart';
import 'package:basic_m6502/io/console.dart';

class WebConsole extends BasicConsole {
  final List<String> output = [];
  final List<String> input = [];

  @override
  void print(String text) {
    output.add(text);
  }

  @override
  Future<String?> readLineAsync({String? prompt}) async {
    if (input.isEmpty) return null;
    return input.removeAt(0);
  }

  @override
  String? getChar() {
    if (input.isEmpty) return null;
    final line = input.removeAt(0);
    return line.isNotEmpty ? line[0] : null;
  }

  @override
  void clear() {
    output.clear();
  }

  @override
  String? readLine({String? prompt}) => null;
}

void main() {
  final console = WebConsole();
  final interpreter = BasicInterpreter(console: console);

  // Provide input
  console.input.add('ALICE');

  // Run program
  interpreter.loadProgram('''
10 INPUT "NAME"; N\$
20 PRINT "HELLO, "; N\$
''');
  interpreter.executeProgram();

  // Get output
  print(console.output.join('\n'));
}
```

## Performance Considerations

### Memory Usage

- Each variable uses 6 bytes (2 name + 4 value)
- Arrays are allocated contiguously
- String space grows from top of memory downward
- Garbage collection runs automatically when string space is low

### Optimization Tips

1. **Reuse variables** instead of creating many temporary variables
2. **Minimize string operations** in tight loops
3. **Use DEF FN** for repeated calculations
4. **Clear unused arrays** to free memory
5. **Avoid excessive garbage collection** by managing string lifetimes

### Benchmarking

```dart
import 'package:basic_m6502/basic_interpreter.dart';

void main() {
  final interpreter = BasicInterpreter();
  final stopwatch = Stopwatch()..start();

  interpreter.loadProgram('''
10 FOR I = 1 TO 10000
20   X = X + 1
30 NEXT I
''');

  interpreter.executeProgram();

  stopwatch.stop();
  print('Execution time: ${stopwatch.elapsedMilliseconds}ms');
}
```

## Thread Safety

The interpreter is **not thread-safe**. Do not call methods from multiple threads simultaneously. If you need concurrent access, synchronize calls externally:

```dart
import 'dart:async';

class SynchronizedInterpreter {
  final BasicInterpreter _interpreter;
  final _lock = Completer<void>()..complete();

  SynchronizedInterpreter(this._interpreter);

  Future<void> execute(String line) async {
    await _lock.future;
    final newLock = Completer<void>();
    final oldLock = _lock;
    _lock = newLock;

    try {
      _interpreter.executeLine(line);
    } finally {
      newLock.complete();
    }
  }
}
```

## Testing

### Unit Testing

```dart
import 'package:test/test.dart';
import 'package:basic_m6502/basic_interpreter.dart';

void main() {
  test('variables work correctly', () {
    final interpreter = BasicInterpreter();
    interpreter.variables.setNumeric('A', 42.0);
    expect(interpreter.variables.getNumeric('A'), equals(42.0));
  });

  test('expression evaluation', () {
    final interpreter = BasicInterpreter();
    interpreter.executeLine('A = 2 + 2');
    expect(interpreter.variables.getNumeric('A'), equals(4.0));
  });
}
```

## Version Compatibility

This API is based on **Microsoft BASIC 1.1 for 6502**. The implementation aims to maintain compatibility with:

- Commodore PET BASIC 1.0/2.0
- Apple II Integer BASIC concepts
- Ohio Scientific BASIC

See `DIALECT_DIFFERENCES.md` for specific compatibility notes.

## Further Reading

- [User Manual](USER_MANUAL.md) - End-user documentation
- [Dialect Differences](DIALECT_DIFFERENCES.md) - Compatibility notes
- [Migration Guide](MIGRATION_GUIDE.md) - Porting from 6502 assembly
- Original source: `m6502.asm` - Historical 6502 assembly implementation
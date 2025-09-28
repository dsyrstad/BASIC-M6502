import 'dart:io';

import 'memory/memory.dart';
import 'memory/variables.dart';
import 'memory/program_storage.dart';
import 'memory/user_functions.dart';
import 'memory/arrays.dart';
import 'runtime/stack.dart';
import 'runtime/errors.dart';
import 'io/screen.dart';
import 'interpreter/tokenizer.dart';
import 'interpreter/expression_evaluator.dart';
import 'interpreter/interpreter.dart';

/// Test screen that captures output instead of printing to stdout
class TestScreen extends Screen {
  final StringBuffer _output = StringBuffer();

  @override
  void printWithoutNewline(String text) {
    _output.write(text);
  }

  @override
  void printLine(String text) {
    _output.write(text);
    _output.write('\n');
  }

  String getOutput() => _output.toString();
  void clearOutput() => _output.clear();
}

/// High-level BASIC interpreter API for easy use in tests and applications.
///
/// This class provides a simplified interface to the full BASIC interpreter,
/// handling initialization and providing convenient methods for loading and
/// running BASIC programs.
class BasicInterpreter {
  late final Memory _memory;
  late final Tokenizer _tokenizer;
  late final VariableStorage _variables;
  late final ExpressionEvaluator _expressionEvaluator;
  late final ProgramStorage _programStorage;
  late final RuntimeStack _runtimeStack;
  late final TestScreen _screen;
  late final UserFunctionStorage _userFunctions;
  late final ArrayManager _arrays;
  late final Interpreter _interpreter;

  /// Constructor - initializes all components
  BasicInterpreter() {
    _memory = Memory();
    _tokenizer = Tokenizer();
    _variables = VariableStorage(_memory);
    _userFunctions = UserFunctionStorage();
    _arrays = ArrayManager(_memory);
    _runtimeStack = RuntimeStack(_memory, _variables);
    _screen = TestScreen();
    _expressionEvaluator = ExpressionEvaluator(
      _memory,
      _variables,
      _tokenizer,
      _userFunctions,
    );
    _programStorage = ProgramStorage(_memory);

    _interpreter = Interpreter(
      _memory,
      _tokenizer,
      _variables,
      _expressionEvaluator,
      _programStorage,
      _runtimeStack,
      _screen,
      _userFunctions,
      _arrays,
    );

    // Initialize memory layout for BASIC
    _initializeMemoryLayout();
  }

  /// Initialize memory layout with proper pointers
  void _initializeMemoryLayout() {
    // Set up memory regions as they would be in a real Commodore system
    final programStart = 0x0800; // Start of BASIC program area
    final variableStart = 0x1000; // Start of variable area
    final arrayStart = 0x2000; // Start of array area
    final stringStart = 0x8000; // Start of string space (grows down)
    final memoryTop = 0x7FFF; // Top of usable memory

    // Initialize zero page pointers
    _memory.writeWord(Memory.vartab, variableStart);
    _memory.writeWord(Memory.arytab, arrayStart);
    _memory.writeWord(Memory.strend, arrayStart);
    _memory.writeWord(Memory.fretop, stringStart);
    _memory.writeWord(Memory.memsiz, memoryTop);

    // Program storage will initialize itself with default start address
  }

  /// Load a BASIC program from a string
  void loadProgram(String programText) {
    // Clear any existing program
    clear();

    // Split into lines and process each one
    final lines = programText.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('REM ')) {
        // Process as a numbered line to add to program
        _interpreter.executeLine(trimmedLine);
      }
    }
  }

  /// Run the loaded program and return output
  String run() {
    _screen.clearOutput();

    try {
      // Execute RUN command to start program
      _interpreter.executeLine('RUN');
    } catch (e) {
      // Re-throw for test expectations
      rethrow;
    }

    return _screen.getOutput();
  }

  /// Execute a single line in immediate mode
  String executeLine(String line) {
    _screen.clearOutput();
    _interpreter.executeLine(line);
    return _screen.getOutput();
  }

  /// Clear program and variables (NEW command)
  void clear() {
    _interpreter.executeLine('NEW');
    _screen.clearOutput();
  }

  /// List the current program
  String list() {
    _screen.clearOutput();
    _interpreter.executeLine('LIST');
    return _screen.getOutput();
  }

  /// Save program to file
  void save(String filename) {
    _interpreter.executeLine('SAVE "$filename"');
  }

  /// Load program from file
  void load(String filename) {
    _interpreter.executeLine('LOAD "$filename"');
  }

  /// Get current output buffer contents
  String getOutput() {
    return _screen.getOutput();
  }

  /// Clear output buffer
  void clearOutput() {
    _screen.clearOutput();
  }

  /// Get variable value (for testing)
  dynamic getVariable(String name) {
    return _variables.getVariable(name);
  }

  /// Set variable value (for testing)
  void setVariable(String name, dynamic value) {
    _variables.setVariable(name, value);
  }

  /// Get memory contents at address (for testing)
  int peek(int address) {
    return _memory.readByte(address);
  }

  /// Set memory contents at address (for testing)
  void poke(int address, int value) {
    _memory.writeByte(address, value);
  }

  /// Check if program is currently running
  bool get isRunning => _interpreter.isRunning;

  /// Get current line number being executed (simplified for testing)
  int get currentLineNumber => -1; // Private field access not available

  /// Get program size in bytes
  int get programSize => _programStorage.programSize;

  /// Get available memory (simplified for testing)
  int get freeMemory => 65536; // Fixed value for testing
}
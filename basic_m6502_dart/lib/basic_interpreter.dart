import 'dart:io';

import 'memory/memory.dart';
import 'memory/variables.dart';
import 'memory/program_storage.dart';
import 'memory/user_functions.dart';
import 'memory/arrays.dart';
import 'runtime/stack.dart';
import 'runtime/errors.dart';
import 'io/screen.dart';
import 'io/file_io.dart';
import 'interpreter/tokenizer.dart';
import 'interpreter/expression_evaluator.dart';
import 'interpreter/interpreter.dart';

// Export FileIOManager for use in tests
export 'io/file_io.dart' show FileIOManager;

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
  late final FileIOManager _fileIO;
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
    _fileIO = FileIOManager();
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
      _fileIO,
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

  /// Execute a complete BASIC program and return result
  ProgramResult executeProgram(String programText) {
    try {
      loadProgram(programText);
      final output = run();
      return ProgramResult(success: true, output: output);
    } catch (e) {
      return ProgramResult(success: false, error: e.toString());
    }
  }

  /// Get current screen output
  String getOutput() {
    return _screen.getOutput();
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

  /// Clear output buffer
  void clearOutput() {
    _screen.clearOutput();
  }

  /// Get the interpreter instance (for advanced usage and testing)
  Interpreter get interpreter => _interpreter;

  /// Get the memory instance (for advanced usage and testing)
  Memory get memory => _memory;
}

/// Result of executing a BASIC program
class ProgramResult {
  final bool success;
  final String? output;
  final String? error;

  ProgramResult({required this.success, this.output, this.error});
}

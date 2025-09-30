import 'dart:io';

import 'package:basic_m6502_dart/memory/memory.dart';
import 'package:basic_m6502_dart/memory/variables.dart';
import 'package:basic_m6502_dart/memory/program_storage.dart';
import 'package:basic_m6502_dart/memory/user_functions.dart';
import 'package:basic_m6502_dart/memory/arrays.dart';
import 'package:basic_m6502_dart/runtime/stack.dart';
import 'package:basic_m6502_dart/io/screen.dart';
import 'package:basic_m6502_dart/io/file_io.dart';
import 'package:basic_m6502_dart/interpreter/tokenizer.dart';
import 'package:basic_m6502_dart/interpreter/expression_evaluator.dart';
import 'package:basic_m6502_dart/interpreter/interpreter.dart';
import 'package:basic_m6502_dart/runtime/errors.dart';

/// Main entry point for the Microsoft BASIC 6502 interpreter.
///
/// Provides an interactive REPL (Read-Eval-Print Loop) that allows users to:
/// - Enter BASIC programs line-by-line with line numbers
/// - Execute immediate mode commands without line numbers
/// - Run, list, save, and load BASIC programs
void main(List<String> arguments) {
  // Initialize all interpreter components
  final memory = Memory();
  final tokenizer = Tokenizer();
  final variables = VariableStorage(memory);
  final userFunctions = UserFunctionStorage();
  final arrays = ArrayManager(memory);
  final runtimeStack = RuntimeStack(memory, variables);
  final screen = Screen();
  final fileIO = FileIOManager();
  final expressionEvaluator = ExpressionEvaluator(
    memory,
    variables,
    tokenizer,
    userFunctions,
  );
  final programStorage = ProgramStorage(memory);

  final interpreter = Interpreter(
    memory,
    tokenizer,
    variables,
    expressionEvaluator,
    programStorage,
    runtimeStack,
    screen,
    userFunctions,
    arrays,
    fileIO,
  );

  // Initialize memory layout
  _initializeMemoryLayout(memory);

  // Print banner
  _printBanner(screen);

  // Set up Ctrl+C handling
  var interrupted = false;
  ProcessSignal.sigint.watch().listen((_) {
    interrupted = true;
    screen.printLine('');
    screen.printLine('BREAK');
    screen.printWithoutNewline('\nREADY.\n');
  });

  // Main REPL loop
  while (true) {
    try {
      interrupted = false;

      // Read a line from stdin
      final line = stdin.readLineSync();

      // Check for EOF (Ctrl+D)
      if (line == null) {
        screen.printLine('');
        break;
      }

      // Skip empty lines
      if (line.trim().isEmpty) {
        continue;
      }

      // Execute the line
      interpreter.executeLine(line);

      // If not interrupted and in immediate mode, show READY prompt
      if (!interrupted && interpreter.isInDirectMode) {
        screen.printWithoutNewline('\nREADY.\n');
      }
    } on BasicError catch (e) {
      // BASIC runtime error - display error message
      screen.printLine('?${e.message}');
      if (e.lineNumber >= 0) {
        screen.printLine(' IN LINE ${e.lineNumber}');
      }
      screen.printWithoutNewline('\nREADY.\n');
    } catch (e) {
      // Unexpected error - display and continue
      screen.printLine('ERROR: $e');
      screen.printWithoutNewline('\nREADY.\n');
    }
  }

  // Exit cleanly
  exit(0);
}

/// Initialize memory layout with proper pointers for BASIC
void _initializeMemoryLayout(Memory memory) {
  // Set up memory regions as they would be in a real Commodore system
  const variableStart = 0x1000; // Start of variable area
  const arrayStart = 0x2000; // Start of array area
  const stringStart = 0x8000; // Start of string space (grows down)
  const memoryTop = 0x7FFF; // Top of usable memory

  // Initialize zero page pointers
  memory.writeWord(Memory.vartab, variableStart);
  memory.writeWord(Memory.arytab, arrayStart);
  memory.writeWord(Memory.strend, arrayStart);
  memory.writeWord(Memory.fretop, stringStart);
  memory.writeWord(Memory.memsiz, memoryTop);
}

/// Print the startup banner
void _printBanner(Screen screen) {
  screen.printLine('');
  screen.printLine('MICROSOFT BASIC 6502 VERSION 1.1');
  screen.printLine('DART IMPLEMENTATION');
  screen.printLine('');
  final totalMemory = 0x7FFF - 0x0800;
  screen.printLine('$totalMemory BYTES FREE');
  screen.printLine('');
  screen.printWithoutNewline('READY.\n');
}

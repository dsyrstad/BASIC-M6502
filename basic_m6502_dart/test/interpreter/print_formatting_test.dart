import 'package:test/test.dart';
import 'dart:io';
import '../../lib/interpreter/interpreter.dart';
import '../../lib/interpreter/tokenizer.dart';
import '../../lib/interpreter/expression_evaluator.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';
import '../../lib/memory/program_storage.dart';
import '../../lib/runtime/stack.dart';
import '../../lib/io/screen.dart';
import '../../lib/io/file_io.dart';
import '../../lib/memory/user_functions.dart';
import '../../lib/memory/arrays.dart';

/// Mock screen that captures output for testing
class MockScreen extends Screen {
  final StringBuffer _buffer = StringBuffer();

  String get output => _buffer.toString();

  void clearOutput() {
    _buffer.clear();
  }

  @override
  void printWithoutNewline(String text) {
    _buffer.write(text);
    // Don't call super to avoid actual output to stdout
  }

  @override
  void printLine(String text) {
    _buffer.write(text);
    _buffer.write('\n');
    // Don't call super to avoid actual output to stdout
  }

  @override
  void tabToNextZone() {
    _buffer.write('<TAB_ZONE>');
    // Manually track tabs for testing
    final nextTab =
        ((cursorColumn ~/ Screen.tabZoneWidth) + 1) * Screen.tabZoneWidth;
    if (nextTab >= Screen.screenWidth) {
      _buffer.write('\n');
    } else {
      final spacesToPrint = nextTab - cursorColumn;
      for (int i = 0; i < spacesToPrint; i++) {
        _buffer.write(' ');
      }
    }
  }

  @override
  void tabToColumn(int column) {
    _buffer.write('<TAB_$column>');
    column = column.clamp(0, Screen.screenWidth - 1);
    if (column <= cursorColumn) {
      _buffer.write('\n');
    } else {
      final spacesToPrint = column - cursorColumn;
      for (int i = 0; i < spacesToPrint; i++) {
        _buffer.write(' ');
      }
    }
  }

  @override
  void printSpaces(int count) {
    _buffer.write('<SPC_$count>');
    for (int i = 0; i < count; i++) {
      _buffer.write(' ');
    }
  }
}

void main() {
  group('PRINT Formatting', () {
    late Memory memory;
    late Tokenizer tokenizer;
    late VariableStorage variables;
    late ExpressionEvaluator expressionEvaluator;
    late ProgramStorage programStorage;
    late RuntimeStack runtimeStack;
    late MockScreen screen;
    late UserFunctionStorage userFunctions;
    late ArrayManager arrays;
    late FileIOManager fileIO;
    late Interpreter interpreter;

    setUp(() {
      memory = Memory();
      tokenizer = Tokenizer();
      variables = VariableStorage(memory);
      userFunctions = UserFunctionStorage();
      arrays = ArrayManager(memory);
      expressionEvaluator = ExpressionEvaluator(
        memory,
        variables,
        tokenizer,
        userFunctions,
      );
      programStorage = ProgramStorage(memory);
      runtimeStack = RuntimeStack(memory, variables);
      screen = MockScreen();
      fileIO = FileIOManager();
      interpreter = Interpreter(
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

      // Initialize variable storage
      variables.initialize(0x2000);
      // Initialize string space top for arrays
      memory.writeWord(Memory.fretop, 0x8000);
    });

    test('should print numbers with leading space for positive values', () {
      interpreter.executeLine('PRINT 42');
      expect(screen.output, contains(' 42'));
    });

    test('should print negative numbers without extra space', () {
      interpreter.executeLine('PRINT -42');
      expect(screen.output, contains('-42'));
    });

    test('should handle semicolon separator (no spacing)', () {
      interpreter.executeLine('PRINT "A"; "B"');
      expect(screen.output, contains('AB'));
    });

    test('should handle comma separator (tab zones)', () {
      screen.clearOutput();
      interpreter.executeLine('PRINT "A", "B"');
      expect(screen.output, contains('<TAB_ZONE>'));
    });

    test('should handle TAB() function', () {
      screen.clearOutput();
      interpreter.executeLine('PRINT TAB(10); "X"');
      expect(screen.output, contains('<TAB_10>'));
    });

    test('should handle SPC() function', () {
      screen.clearOutput();
      interpreter.executeLine('PRINT SPC(5); "Y"');
      expect(screen.output, contains('<SPC_5>'));
    });

    test('should handle mixed separators', () {
      screen.clearOutput();
      interpreter.executeLine('PRINT "A"; "B", "C"');
      expect(screen.output, contains('AB<TAB_ZONE>'));
    });

    test('should handle trailing semicolon (no final newline)', () {
      screen.clearOutput();
      interpreter.executeLine('PRINT "Hello";');
      final output = screen.output;
      // Should not end with extra newline
      expect(output.endsWith('Hello'), isTrue);
    });

    test('should handle empty PRINT (newline only)', () {
      screen.clearOutput();
      interpreter.executeLine('PRINT');
      expect(screen.output, equals('\n'));
    });

    test('should format integers without decimal point', () {
      screen.clearOutput();
      interpreter.executeLine('PRINT 123');
      expect(screen.output, contains(' 123'));
      expect(screen.output, isNot(contains('123.0')));
    });

    test('should format floating point numbers', () {
      screen.clearOutput();
      interpreter.executeLine('PRINT 3.14');
      expect(screen.output, contains(' 3.14'));
    });

    test('should handle complex PRINT with multiple functions', () {
      screen.clearOutput();
      interpreter.executeLine('PRINT TAB(5); "A"; SPC(3); "B"');
      expect(screen.output, contains('<TAB_5>'));
      expect(screen.output, contains('<SPC_3>'));
      expect(screen.output, contains('A'));
      expect(screen.output, contains('B'));
    });
  });

  group('Screen Functionality', () {
    late Screen screen;

    setUp(() {
      screen = Screen();
    });

    test('should track cursor position', () {
      expect(screen.cursorColumn, equals(0));
      screen.printWithoutNewline('Hello');
      expect(screen.cursorColumn, equals(5));
    });

    test('should wrap at screen width', () {
      final longText = 'A' * 45; // Longer than 40 characters
      screen.printWithoutNewline(longText);
      // After wrapping, cursor should be at column 5 (45 - 40)
      expect(screen.cursorColumn, equals(5));
    });

    test('should calculate tab zones correctly', () {
      screen.printWithoutNewline('ABC'); // Column 3
      final initialColumn = screen.cursorColumn;
      screen.tabToNextZone();
      // Should tab to column 10 (next 10-character zone)
      expect(screen.cursorColumn, equals(10));
    });

    test('should handle TAB to specific column', () {
      screen.printWithoutNewline('Hi'); // Column 2
      screen.tabToColumn(15);
      expect(screen.cursorColumn, equals(15));
    });

    test('should handle TAB to column before current position', () {
      screen.printWithoutNewline('Hello World'); // Column 11
      final initialRow = screen.cursorRow;
      screen.tabToColumn(5); // Should go to new line first
      expect(screen.cursorRow, equals(initialRow + 1));
      expect(screen.cursorColumn, equals(5));
    });
  });
}

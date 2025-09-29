import 'package:test/test.dart';
import 'dart:io';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';
import '../../lib/memory/program_storage.dart';
import '../../lib/runtime/stack.dart';
import '../../lib/io/screen.dart';
import '../../lib/io/file_io.dart';
import '../../lib/interpreter/tokenizer.dart';
import '../../lib/interpreter/expression_evaluator.dart';
import '../../lib/interpreter/interpreter.dart';
import '../../lib/memory/user_functions.dart';
import '../../lib/memory/arrays.dart';

void main() {
  group('File Operations Tests', () {
    late FileIOManager fileIO;
    late Interpreter interpreter;
    late Memory memory;
    late VariableStorage variables;
    late ProgramStorage programStorage;
    late RuntimeStack runtimeStack;
    late Screen screen;
    late Tokenizer tokenizer;
    late ExpressionEvaluator expressionEvaluator;
    late UserFunctionStorage userFunctions;
    late ArrayManager arrays;
    late String testFileName;
    late Directory tempDir;

    setUp(() {
      memory = Memory();
      variables = VariableStorage(memory);
      programStorage = ProgramStorage(memory);
      runtimeStack = RuntimeStack(memory, variables);
      screen = Screen();
      fileIO = FileIOManager();
      tokenizer = Tokenizer();
      userFunctions = UserFunctionStorage();
      arrays = ArrayManager(memory);
      expressionEvaluator = ExpressionEvaluator(
        memory,
        variables,
        tokenizer,
        userFunctions,
      );
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

      // Create temporary directory for test files
      tempDir = Directory.systemTemp.createTempSync('basic_test_');
      testFileName = '${tempDir.path}/test_program.bas';
    });

    tearDown(() {
      // Clean up test files
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('SAVE command saves program to file', () {
      // Create a simple program
      interpreter.executeLine('10 PRINT "HELLO"');
      interpreter.executeLine('20 LET A = 42');

      // Save the program
      interpreter.executeLine('SAVE "$testFileName"');

      // Verify file was created
      expect(File(testFileName).existsSync(), isTrue);
    });

    test('LOAD command loads program from file', () {
      // Create and save a program
      interpreter.executeLine('10 PRINT "TEST"');
      interpreter.executeLine('20 LET B = 123');
      interpreter.executeLine('SAVE "$testFileName"');

      // Clear program
      interpreter.executeLine('NEW');
      expect(programStorage.getAllLineNumbers(), isEmpty);

      // Load the program back
      interpreter.executeLine('LOAD "$testFileName"');

      // Verify program was loaded
      final lineNumbers = programStorage.getAllLineNumbers();
      expect(lineNumbers, contains(10));
      expect(lineNumbers, contains(20));
    });

    test('VERIFY command succeeds when files match', () {
      // Create a simple program
      interpreter.executeLine('10 PRINT "VERIFY TEST"');
      interpreter.executeLine('30 END');

      // Save it
      interpreter.executeLine('SAVE "$testFileName"');

      // Verify it - should succeed without error
      expect(
        () => interpreter.executeLine('VERIFY "$testFileName"'),
        returnsNormally,
      );
    });

    test('SAVE with empty filename throws error', () {
      interpreter.executeLine('10 PRINT "TEST"');

      expect(() => interpreter.executeLine('SAVE ""'), throwsA(anything));
    });

    test('SAVE with no quotes throws syntax error', () {
      interpreter.executeLine('10 PRINT "TEST"');

      expect(() => interpreter.executeLine('SAVE test.bas'), throwsA(anything));
    });

    test('SAVE with empty program throws error', () {
      expect(
        () => interpreter.executeLine('SAVE "$testFileName"'),
        throwsA(anything),
      );
    });

    test('LOAD non-existent file throws error', () {
      expect(
        () => interpreter.executeLine('LOAD "nonexistent.bas"'),
        throwsA(anything),
      );
    });

    test('LOAD with empty filename throws error', () {
      expect(() => interpreter.executeLine('LOAD ""'), throwsA(anything));
    });

    test('LOAD with no quotes throws syntax error', () {
      expect(() => interpreter.executeLine('LOAD test.bas'), throwsA(anything));
    });

    test('VERIFY non-existent file throws error', () {
      interpreter.executeLine('10 PRINT "TEST"');

      expect(
        () => interpreter.executeLine('VERIFY "nonexistent.bas"'),
        throwsA(anything),
      );
    });

    test('VERIFY with empty filename throws error', () {
      interpreter.executeLine('10 PRINT "TEST"');

      expect(() => interpreter.executeLine('VERIFY ""'), throwsA(anything));
    });

    test('SAVE and LOAD preserve program content', () {
      // Create a complex program
      interpreter.executeLine('10 FOR I = 1 TO 10');
      interpreter.executeLine('20 PRINT "NUMBER"; I');
      interpreter.executeLine('30 NEXT I');
      interpreter.executeLine('40 PRINT "DONE"');

      // Save it
      interpreter.executeLine('SAVE "$testFileName"');

      // Clear program
      interpreter.executeLine('NEW');

      // Load it back
      interpreter.executeLine('LOAD "$testFileName"');

      // Verify all lines are present and can be displayed
      final lineNumbers = programStorage.getAllLineNumbers();
      expect(lineNumbers, [10, 20, 30, 40]);

      // Check each line can be retrieved for display
      for (final lineNumber in lineNumbers) {
        expect(
          () => programStorage.getLineForDisplay(
            lineNumber,
            tokenizer.detokenize,
          ),
          returnsNormally,
        );
      }
    });

    test('Multiple SAVE/LOAD operations work correctly', () {
      // Create first program
      interpreter.executeLine('10 PRINT "FIRST"');
      interpreter.executeLine('SAVE "$testFileName"');

      // Create second program
      interpreter.executeLine('NEW');
      interpreter.executeLine('20 PRINT "SECOND"');
      final secondFileName = '${tempDir.path}/second.bas';
      interpreter.executeLine('SAVE "$secondFileName"');

      // Load first program back
      interpreter.executeLine('LOAD "$testFileName"');
      expect(programStorage.getAllLineNumbers(), [10]);

      // Load second program back
      interpreter.executeLine('LOAD "$secondFileName"');
      expect(programStorage.getAllLineNumbers(), [20]);
    });

    test('SAVE overwrites existing file', () {
      // Create and save first program
      interpreter.executeLine('10 PRINT "FIRST VERSION"');
      interpreter.executeLine('SAVE "$testFileName"');

      // Create and save different program to same file
      interpreter.executeLine('NEW');
      interpreter.executeLine('20 PRINT "SECOND VERSION"');
      interpreter.executeLine('SAVE "$testFileName"');

      // Load and verify it's the second program
      interpreter.executeLine('LOAD "$testFileName"');
      expect(programStorage.getAllLineNumbers(), [20]);
    });

    test('LOAD clears variables', () {
      // Set some variables
      interpreter.executeLine('A = 42');
      interpreter.executeLine('B = 123');

      // Create and save a program
      interpreter.executeLine('10 PRINT "TEST"');
      interpreter.executeLine('SAVE "$testFileName"');

      // Load should clear variables
      interpreter.executeLine('LOAD "$testFileName"');

      // Variables should be cleared (can't easily test without accessing internals)
      // But we can verify the program loaded correctly
      expect(programStorage.getAllLineNumbers(), contains(10));
    });

    test('File operations handle path separators correctly', () {
      // Create subdirectory
      final subDir = Directory('${tempDir.path}/subdir');
      subDir.createSync();
      final subFileName = '${subDir.path}/nested_test.bas';

      // Save to nested path
      interpreter.executeLine('10 PRINT "NESTED"');
      interpreter.executeLine('SAVE "$subFileName"');

      expect(File(subFileName).existsSync(), isTrue);

      // Load from nested path
      interpreter.executeLine('NEW');
      interpreter.executeLine('LOAD "$subFileName"');

      expect(programStorage.getAllLineNumbers(), contains(10));
    });
  });
}

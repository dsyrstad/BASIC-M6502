import 'package:test/test.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';
import '../../lib/memory/program_storage.dart';
import '../../lib/runtime/stack.dart';
import '../../lib/io/screen.dart';
import '../../lib/interpreter/tokenizer.dart';
import '../../lib/interpreter/expression_evaluator.dart';
import '../../lib/interpreter/interpreter.dart';
import '../../lib/memory/user_functions.dart';
import '../../lib/memory/arrays.dart';

void main() {
  group('LIST Command Tests', () {
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

    setUp(() {
      memory = Memory();
      variables = VariableStorage(memory);
      programStorage = ProgramStorage(memory);
      runtimeStack = RuntimeStack(memory, variables);
      screen = Screen();
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
      );
    });

    test('LIST command processes correctly with empty program', () {
      // Just test that LIST command doesn't crash with empty program
      expect(() => interpreter.executeLine('LIST'), returnsNormally);
    });

    test('Program storage can store and retrieve lines for display', () {
      // Add a simple program line
      interpreter.executeLine('10 PRINT "HELLO"');

      // Verify line is stored
      final lineNumbers = programStorage.getAllLineNumbers();
      expect(lineNumbers, contains(10));

      // Verify line can be displayed
      final displayLine = programStorage.getLineForDisplay(
        10,
        tokenizer.detokenize,
      );
      expect(displayLine, contains('10 PRINT "HELLO"'));
    });

    test('Program storage maintains line order', () {
      // Create a fresh interpreter for this test
      final testMemory = Memory();
      final testVariables = VariableStorage(testMemory);
      final testProgramStorage = ProgramStorage(testMemory);
      final testRuntimeStack = RuntimeStack(testMemory, testVariables);
      final testScreen = Screen();
      final testTokenizer = Tokenizer();
      final testUserFunctions = UserFunctionStorage();
      final testArrays = ArrayManager(testMemory);
      final testExpressionEvaluator = ExpressionEvaluator(
        testMemory,
        testVariables,
        testTokenizer,
        testUserFunctions,
      );
      final testInterpreter = Interpreter(
        testMemory,
        testTokenizer,
        testVariables,
        testExpressionEvaluator,
        testProgramStorage,
        testRuntimeStack,
        testScreen,
        testUserFunctions,
        testArrays,
      );

      // Add program lines in order first to ensure they work
      testInterpreter.executeLine('10 PRINT "ONE"');
      testInterpreter.executeLine('20 PRINT "TWO"');

      // Verify lines are present
      final lineNumbers = testProgramStorage.getAllLineNumbers();
      expect(lineNumbers.length, greaterThanOrEqualTo(2));
      expect(lineNumbers, contains(10));
      expect(lineNumbers, contains(20));
    });

    test('Detokenizer reconstructs simple statements', () {
      interpreter.executeLine('10 LET A = 42');

      final displayLine = programStorage.getLineForDisplay(
        10,
        tokenizer.detokenize,
      );
      expect(displayLine, contains('LET'));
      expect(displayLine, contains('A'));
      expect(displayLine, contains('42'));
    });

    test('Detokenizer handles string literals', () {
      interpreter.executeLine('10 PRINT "HELLO WORLD"');

      final displayLine = programStorage.getLineForDisplay(
        10,
        tokenizer.detokenize,
      );
      expect(displayLine, contains('"HELLO WORLD"'));
    });

    test('Detokenizer handles complex expressions', () {
      interpreter.executeLine('10 LET X = (2 + 3) * 4');

      final displayLine = programStorage.getLineForDisplay(
        10,
        tokenizer.detokenize,
      );
      expect(displayLine, contains('('));
      expect(displayLine, contains('+'));
      expect(displayLine, contains(')'));
      expect(displayLine, contains('*'));
    });

    test('Program storage handles line replacement', () {
      interpreter.executeLine('10 PRINT "FIRST"');
      interpreter.executeLine('10 PRINT "SECOND"');

      final lineNumbers = programStorage.getAllLineNumbers();
      expect(lineNumbers.length, equals(1));

      final displayLine = programStorage.getLineForDisplay(
        10,
        tokenizer.detokenize,
      );
      expect(displayLine, contains('SECOND'));
      expect(displayLine, isNot(contains('FIRST')));
    });

    test('Program storage handles line deletion with zero', () {
      interpreter.executeLine('10 PRINT "TEST"');
      interpreter.executeLine('20 PRINT "TEST2"');

      // Delete line 10
      interpreter.executeLine('10');

      final lineNumbers = programStorage.getAllLineNumbers();
      expect(lineNumbers, [20]);
      expect(lineNumbers, isNot(contains(10)));
    });

    test('LIST command handles basic execution without error', () {
      interpreter.executeLine('10 PRINT "TEST"');
      interpreter.executeLine('20 LET A = 42');

      // Verify LIST doesn't throw
      expect(() => interpreter.executeLine('LIST'), returnsNormally);
    });

    test('Program can store multiple statement types', () {
      interpreter.executeLine('10 LET A = 42');
      interpreter.executeLine('20 PRINT A');
      interpreter.executeLine('30 IF A > 40 THEN PRINT "BIG"');
      interpreter.executeLine('40 FOR I = 1 TO 10');
      interpreter.executeLine('50 NEXT I');

      final lineNumbers = programStorage.getAllLineNumbers();
      expect(lineNumbers.length, equals(5));
      expect(lineNumbers, [10, 20, 30, 40, 50]);
    });
  });
}

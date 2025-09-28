import 'package:test/test.dart';
import '../../lib/interpreter/interpreter.dart';
import '../../lib/interpreter/tokenizer.dart';
import '../../lib/interpreter/expression_evaluator.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';
import '../../lib/memory/program_storage.dart';
import '../../lib/runtime/stack.dart';
import '../../lib/io/screen.dart';
import '../../lib/memory/user_functions.dart';
import '../../lib/memory/arrays.dart';

void main() {
  group('Computed GOTO', () {
    late Memory memory;
    late Tokenizer tokenizer;
    late VariableStorage variables;
    late ExpressionEvaluator expressionEvaluator;
    late ProgramStorage programStorage;
    late RuntimeStack runtimeStack;
    late Screen screen;
    late UserFunctionStorage userFunctions;
    late ArrayManager arrays;
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
      screen = Screen();
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

      // Initialize variable storage
      variables.initialize(0x2000);
      // Initialize string space top for arrays
      memory.writeWord(Memory.fretop, 0x8000);
    });

    test('should handle static GOTO (backward compatibility)', () {
      // Create a program with static GOTO
      final tokens1 = tokenizer.tokenizeLine('A = 1');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('GOTO 40');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine('A = 99'); // Should be skipped
      programStorage.storeLine(30, tokens3);
      final tokens4 = tokenizer.tokenizeLine('A = 2');
      programStorage.storeLine(40, tokens4);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify that GOTO worked correctly
      final varA = variables.getVariable('A');
      expect(varA, isA<NumericValue>());
      expect(
        (varA as NumericValue).value,
        equals(2.0),
      ); // Set by line 40, not 30
    });

    test('should handle computed GOTO with variable', () {
      // Create a program with computed GOTO using variables
      final tokens1 = tokenizer.tokenizeLine('A = 30');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('B = 10');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine('X = 1');
      programStorage.storeLine(30, tokens3);
      final tokens4 = tokenizer.tokenizeLine('GOTO A + B'); // A + B = 40
      programStorage.storeLine(35, tokens4);
      final tokens5 = tokenizer.tokenizeLine('X = 99'); // Should be skipped
      programStorage.storeLine(37, tokens5);
      final tokens6 = tokenizer.tokenizeLine('X = 2'); // Target of GOTO
      programStorage.storeLine(40, tokens6);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify that computed GOTO worked (A + B = 30 + 10 = 40)
      final varX = variables.getVariable('X');
      expect(varX, isA<NumericValue>());
      expect(
        (varX as NumericValue).value,
        equals(2.0),
      ); // Set by line 40, skipped line 37
    });

    test('should handle computed GOTO with arithmetic expression', () {
      // Create a program with arithmetic in GOTO
      final tokens1 = tokenizer.tokenizeLine('X = 1');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('GOTO 20 * 2');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine('X = 99'); // Should be skipped
      programStorage.storeLine(30, tokens3);
      final tokens4 = tokenizer.tokenizeLine('X = 2');
      programStorage.storeLine(40, tokens4);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify that computed GOTO worked (20 * 2 = 40)
      final varX = variables.getVariable('X');
      expect(varX, isA<NumericValue>());
      expect((varX as NumericValue).value, equals(2.0)); // Set by line 40
    });

    test('should handle computed GOTO with parentheses', () {
      // Create a program with parentheses in GOTO
      final tokens1 = tokenizer.tokenizeLine('N = 5');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('X = 1');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine(
        'GOTO (N + 3) * 5',
      ); // (5 + 3) * 5 = 40
      programStorage.storeLine(30, tokens3);
      final tokens4 = tokenizer.tokenizeLine('X = 99'); // Should be skipped
      programStorage.storeLine(35, tokens4);
      final tokens5 = tokenizer.tokenizeLine('X = 2');
      programStorage.storeLine(40, tokens5);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify that computed GOTO worked ((5 + 3) * 5 = 40)
      final varX = variables.getVariable('X');
      expect(varX, isA<NumericValue>());
      expect((varX as NumericValue).value, equals(2.0)); // Set by line 40
    });

    test('should throw error for non-numeric GOTO target', () {
      // Set up string variable
      interpreter.executeLine('S\$ = "HELLO"');

      // Try to use string in GOTO
      expect(
        () => interpreter.executeLine('GOTO S\$'),
        throwsA(isA<InterpreterException>()),
      );
    });

    test('should throw error for negative line number', () {
      // Try to use negative number in computed GOTO
      expect(
        () => interpreter.executeLine('GOTO -10'),
        throwsA(isA<InterpreterException>()),
      );
    });

    test('should throw error for line number too large', () {
      // Try to use overly large number in computed GOTO
      expect(
        () => interpreter.executeLine('GOTO 70000'),
        throwsA(isA<InterpreterException>()),
      );
    });

    test('should handle computed GOTO to non-existent line', () {
      // Create a simple program
      final tokens1 = tokenizer.tokenizeLine('A = 42');
      programStorage.storeLine(10, tokens1);

      // Run program with computed GOTO to non-existent line
      expect(
        () => interpreter.executeLine(
          'GOTO 10 + 15',
        ), // Goes to line 25 which doesn't exist
        throwsA(isA<InterpreterException>()),
      );
    });

    test('should handle floating point result in computed GOTO', () {
      // Create a program that uses floating point in GOTO
      final tokens1 = tokenizer.tokenizeLine('X = 1');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine(
        'GOTO 39.9 + 0.1',
      ); // Should go to line 40
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine('X = 99'); // Should be skipped
      programStorage.storeLine(30, tokens3);
      final tokens4 = tokenizer.tokenizeLine('X = 2');
      programStorage.storeLine(40, tokens4);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify that computed GOTO worked (39.9 + 0.1 = 40.0 -> 40)
      final varX = variables.getVariable('X');
      expect(varX, isA<NumericValue>());
      expect((varX as NumericValue).value, equals(2.0)); // Set by line 40
    });

    test('should work with function calls in computed GOTO', () {
      // Create a program that uses function in GOTO
      final tokens1 = tokenizer.tokenizeLine('X = 1');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine(
        'GOTO INT(40.7)',
      ); // Should go to line 40
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine('X = 99'); // Should be skipped
      programStorage.storeLine(30, tokens3);
      final tokens4 = tokenizer.tokenizeLine('X = 2');
      programStorage.storeLine(40, tokens4);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify that computed GOTO worked
      final varX = variables.getVariable('X');
      expect(varX, isA<NumericValue>());
      expect((varX as NumericValue).value, equals(2.0)); // Set by line 40
    });
  });
}

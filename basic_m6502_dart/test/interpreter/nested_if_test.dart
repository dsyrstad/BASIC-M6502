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
  group('Nested IF Statements', () {
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

    test('should handle simple nested IF - both true', () {
      // Create a program with nested IF statements
      final tokens1 = tokenizer.tokenizeLine('A = 1');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('B = 2');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine(
        'IF A = 1 THEN IF B = 2 THEN X = 42',
      );
      programStorage.storeLine(30, tokens3);
      final tokens4 = tokenizer.tokenizeLine('Y = 99'); // This should execute
      programStorage.storeLine(40, tokens4);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify both conditions were true and nested statement executed
      final varX = variables.getVariable('X');
      final varY = variables.getVariable('Y');
      expect(varX, isA<NumericValue>());
      expect(
        (varX as NumericValue).value,
        equals(42.0),
      ); // Should be set by nested IF
      expect(varY, isA<NumericValue>());
      expect(
        (varY as NumericValue).value,
        equals(99.0),
      ); // Should continue execution
    });

    test('should handle nested IF - outer false', () {
      // Create a program where outer IF is false
      final tokens1 = tokenizer.tokenizeLine('A = 2'); // Not 1
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('B = 2');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine(
        'IF A = 1 THEN IF B = 2 THEN X = 42',
      );
      programStorage.storeLine(30, tokens3);
      final tokens4 = tokenizer.tokenizeLine('Y = 99'); // This should execute
      programStorage.storeLine(40, tokens4);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify outer condition was false, so nested statement didn't execute
      final varX = variables.getVariable('X');
      final varY = variables.getVariable('Y');
      expect(varX, isA<NumericValue>());
      expect((varX as NumericValue).value, equals(0.0)); // Should not be set
      expect(varY, isA<NumericValue>());
      expect(
        (varY as NumericValue).value,
        equals(99.0),
      ); // Should continue execution
    });

    test('should handle nested IF - outer true, inner false', () {
      // Create a program where outer IF is true but inner IF is false
      final tokens1 = tokenizer.tokenizeLine('A = 1');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('B = 3'); // Not 2
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine(
        'IF A = 1 THEN IF B = 2 THEN X = 42',
      );
      programStorage.storeLine(30, tokens3);
      final tokens4 = tokenizer.tokenizeLine('Y = 99'); // This should execute
      programStorage.storeLine(40, tokens4);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify outer was true but inner was false, so nested statement didn't execute
      final varX = variables.getVariable('X');
      final varY = variables.getVariable('Y');
      expect(varX, isA<NumericValue>());
      expect((varX as NumericValue).value, equals(0.0)); // Should not be set
      expect(varY, isA<NumericValue>());
      expect(
        (varY as NumericValue).value,
        equals(99.0),
      ); // Should continue execution
    });

    test('should handle nested IF with GOTO', () {
      // Create a program with nested IF that does GOTO
      final tokens1 = tokenizer.tokenizeLine('A = 1');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('B = 2');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine(
        'IF A = 1 THEN IF B = 2 THEN GOTO 50',
      );
      programStorage.storeLine(30, tokens3);
      final tokens4 = tokenizer.tokenizeLine('X = 99'); // Should be skipped
      programStorage.storeLine(40, tokens4);
      final tokens5 = tokenizer.tokenizeLine('X = 42');
      programStorage.storeLine(50, tokens5);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify nested GOTO worked
      final varX = variables.getVariable('X');
      expect(varX, isA<NumericValue>());
      expect(
        (varX as NumericValue).value,
        equals(42.0),
      ); // Set by line 50, not 40
    });

    test('should handle triple nested IF', () {
      // Create a program with three levels of nesting
      final tokens1 = tokenizer.tokenizeLine('A = 1');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('B = 2');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine('C = 3');
      programStorage.storeLine(25, tokens3);
      final tokens4 = tokenizer.tokenizeLine(
        'IF A = 1 THEN IF B = 2 THEN IF C = 3 THEN X = 42',
      );
      programStorage.storeLine(30, tokens4);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify all three conditions were true
      final varX = variables.getVariable('X');
      expect(varX, isA<NumericValue>());
      expect(
        (varX as NumericValue).value,
        equals(42.0),
      ); // Should be set by triple nested IF
    });

    test('should handle nested IF with different operators', () {
      // Create a program with different comparison operators
      final tokens1 = tokenizer.tokenizeLine('A = 5');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('B = 3');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine(
        'IF A > 4 THEN IF B < 4 THEN X = 42',
      );
      programStorage.storeLine(30, tokens3);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify both conditions were true
      final varX = variables.getVariable('X');
      expect(varX, isA<NumericValue>());
      expect((varX as NumericValue).value, equals(42.0)); // Should be set
    });

    test('should handle nested IF with mixed statement types', () {
      // Create a program with nested IF and assignment
      final tokens1 = tokenizer.tokenizeLine('A = 1');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine(
        'IF A = 1 THEN X = 10: IF X = 10 THEN Y = 20',
      );
      programStorage.storeLine(20, tokens2);

      // Run the program
      interpreter.executeLine('RUN');

      // Verify both assignments worked
      final varX = variables.getVariable('X');
      final varY = variables.getVariable('Y');
      expect(varX, isA<NumericValue>());
      expect((varX as NumericValue).value, equals(10.0)); // Set by first part
      expect(varY, isA<NumericValue>());
      expect((varY as NumericValue).value, equals(20.0)); // Set by nested IF
    });
  });
}

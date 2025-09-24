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

void main() {
  group('RUN Command', () {
    late Memory memory;
    late Tokenizer tokenizer;
    late VariableStorage variables;
    late ExpressionEvaluator expressionEvaluator;
    late ProgramStorage programStorage;
    late RuntimeStack runtimeStack;
    late Screen screen;
    late UserFunctionStorage userFunctions;
    late Interpreter interpreter;

    setUp(() {
      memory = Memory();
      tokenizer = Tokenizer();
      variables = VariableStorage(memory);
      expressionEvaluator = ExpressionEvaluator(
        memory,
        variables,
        tokenizer,
        userFunctions,
      );
      programStorage = ProgramStorage(memory);
      runtimeStack = RuntimeStack(memory, variables);
      screen = Screen();
      userFunctions = UserFunctionStorage();
      interpreter = Interpreter(
        memory,
        tokenizer,
        variables,
        expressionEvaluator,
        programStorage,
        runtimeStack,
        screen,
        userFunctions,
      );

      // Initialize variable storage
      variables.initialize(0x2000);
    });

    test('should run simple program from beginning', () {
      // Create a simple program
      final tokens1 = tokenizer.tokenizeLine('A = 10');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('B = 20');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine('PRINT A + B');
      programStorage.storeLine(30, tokens3);

      // Execute RUN
      interpreter.executeLine('RUN');

      // Check that variables were set by the program
      final varA = variables.getVariable('A');
      final varB = variables.getVariable('B');
      expect(varA, isA<NumericValue>());
      expect((varA as NumericValue).value, equals(10.0));
      expect(varB, isA<NumericValue>());
      expect((varB as NumericValue).value, equals(20.0));
    });

    test('should clear variables before running program', () {
      // Set some initial variables
      interpreter.executeLine('A = 99');
      interpreter.executeLine('B\$ = "INITIAL"');

      // Verify variables are set
      final initialA = variables.getVariable('A');
      final initialB = variables.getVariable('B\$');
      expect((initialA as NumericValue).value, equals(99.0));
      expect((initialB as StringValue).value, equals('INITIAL'));

      // Create a program that uses different values
      final tokens1 = tokenizer.tokenizeLine('A = 42');
      programStorage.storeLine(10, tokens1);

      // Execute RUN
      interpreter.executeLine('RUN');

      // Variables should be cleared and then set by program
      final varA = variables.getVariable('A');
      final varB = variables.getVariable('B\$');
      expect((varA as NumericValue).value, equals(42.0)); // Set by program
      expect(
        (varB as StringValue).value,
        equals(''),
      ); // Cleared and not set by program
    });

    test('should reset runtime stack before running', () {
      // Create a FOR loop in a program
      final tokens1 = tokenizer.tokenizeLine('FOR I = 1 TO 3');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('PRINT I');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine('NEXT I');
      programStorage.storeLine(30, tokens3);

      // Execute RUN
      interpreter.executeLine('RUN');

      // The FOR loop should have completed successfully
      final varI = variables.getVariable('I');
      expect(varI, isA<NumericValue>());
      expect(
        (varI as NumericValue).value,
        equals(4.0),
      ); // After loop completion
    });

    test('should run program from specified line number', () {
      // Create a program with multiple lines
      final tokens1 = tokenizer.tokenizeLine('A = 1');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('A = 2');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine('A = 3');
      programStorage.storeLine(30, tokens3);

      // Execute RUN 20 (start from line 20)
      interpreter.executeLine('RUN 20');

      // Variable should be set by line 20 and 30, not line 10
      final varA = variables.getVariable('A');
      expect(varA, isA<NumericValue>());
      expect(
        (varA as NumericValue).value,
        equals(3.0),
      ); // Set by lines 20 and 30
    });

    test('should handle RUN with non-existent line number', () {
      // Create a program
      final tokens1 = tokenizer.tokenizeLine('A = 42');
      programStorage.storeLine(10, tokens1);

      // Try to run from a line that doesn't exist
      expect(
        () => interpreter.executeLine('RUN 50'),
        throwsA(isA<InterpreterException>()),
      );
    });

    test('should handle empty program', () {
      // Try to run when no program is loaded - should just return without error
      expect(() => interpreter.executeLine('RUN'), returnsNormally);
    });

    test('should initialize program execution state', () {
      // Create a program with GOTO
      final tokens1 = tokenizer.tokenizeLine('A = 10');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('GOTO 40');
      programStorage.storeLine(20, tokens2);
      final tokens3 = tokenizer.tokenizeLine(
        'A = 99',
      ); // This should be skipped
      programStorage.storeLine(30, tokens3);
      final tokens4 = tokenizer.tokenizeLine('B = 20');
      programStorage.storeLine(40, tokens4);

      // Execute RUN
      interpreter.executeLine('RUN');

      // Check that GOTO worked correctly
      final varA = variables.getVariable('A');
      final varB = variables.getVariable('B');
      expect((varA as NumericValue).value, equals(10.0)); // Set by line 10
      expect((varB as NumericValue).value, equals(20.0)); // Set by line 40
    });

    test('should work with RUN after program modifications', () {
      // Create initial program
      final tokens1 = tokenizer.tokenizeLine('A = 10');
      programStorage.storeLine(10, tokens1);

      // Run program
      interpreter.executeLine('RUN');
      final varA1 = variables.getVariable('A');
      expect((varA1 as NumericValue).value, equals(10.0));

      // Modify program
      final tokens2 = tokenizer.tokenizeLine('A = 20');
      programStorage.storeLine(10, tokens2); // Replace line 10

      // Run again
      interpreter.executeLine('RUN');
      final varA2 = variables.getVariable('A');
      expect(
        (varA2 as NumericValue).value,
        equals(20.0),
      ); // Should use new value
    });
  });
}

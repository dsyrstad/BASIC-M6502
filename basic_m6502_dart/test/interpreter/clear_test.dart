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
  group('CLEAR Command', () {
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

    test('should clear variables but keep program', () {
      // Add a program line
      final tokens = tokenizer.tokenizeLine('PRINT "HELLO"');
      programStorage.storeLine(10, tokens);

      // Set some variables
      interpreter.executeLine('A = 42');
      interpreter.executeLine('B\$ = "TEST"');

      // Verify variables are set
      final varA = variables.getVariable('A');
      final varB = variables.getVariable('B\$');
      expect(varA, isA<NumericValue>());
      expect((varA as NumericValue).value, equals(42.0));
      expect(varB, isA<StringValue>());
      expect((varB as StringValue).value, equals('TEST'));

      // Verify program exists
      expect(programStorage.getAllLineNumbers(), contains(10));

      // Execute CLEAR
      interpreter.executeLine('CLEAR');

      // Variables should be cleared (should return default values)
      final clearedA = variables.getVariable('A');
      final clearedB = variables.getVariable('B\$');
      expect(clearedA, isA<NumericValue>());
      expect((clearedA as NumericValue).value, equals(0.0));
      expect(clearedB, isA<StringValue>());
      expect((clearedB as StringValue).value, equals(''));

      // Program should still exist
      expect(programStorage.getAllLineNumbers(), contains(10));
    });

    test('should clear runtime stack', () {
      // Add a FOR loop program
      final tokens1 = tokenizer.tokenizeLine('FOR I = 1 TO 10');
      programStorage.storeLine(10, tokens1);
      final tokens2 = tokenizer.tokenizeLine('NEXT I');
      programStorage.storeLine(20, tokens2);

      // Start the FOR loop (this puts something on the stack)
      interpreter.executeLine('FOR I = 1 TO 10');

      // Verify stack has content (this is internal, but we can check via variables)
      final varI = variables.getVariable('I');
      expect(varI, isA<NumericValue>());
      expect((varI as NumericValue).value, equals(1.0));

      // Execute CLEAR
      interpreter.executeLine('CLEAR');

      // Stack should be cleared, variable should be reset
      final clearedI = variables.getVariable('I');
      expect(clearedI, isA<NumericValue>());
      expect((clearedI as NumericValue).value, equals(0.0));
    });

    test('NEW vs CLEAR difference', () {
      // Add a program line
      final tokens = tokenizer.tokenizeLine('PRINT "HELLO"');
      programStorage.storeLine(10, tokens);

      // Set a variable
      interpreter.executeLine('A = 42');

      // Verify initial state
      expect(programStorage.getAllLineNumbers(), contains(10));
      final varA = variables.getVariable('A');
      expect((varA as NumericValue).value, equals(42.0));

      // Execute CLEAR
      interpreter.executeLine('CLEAR');

      // Program should remain, variables cleared
      expect(programStorage.getAllLineNumbers(), contains(10));
      final clearedA = variables.getVariable('A');
      expect((clearedA as NumericValue).value, equals(0.0));

      // Set variable again
      interpreter.executeLine('A = 99');
      final varA2 = variables.getVariable('A');
      expect((varA2 as NumericValue).value, equals(99.0));

      // Execute NEW
      interpreter.executeLine('NEW');

      // Both program and variables should be cleared
      expect(programStorage.getAllLineNumbers(), isEmpty);
      final newA = variables.getVariable('A');
      expect((newA as NumericValue).value, equals(0.0));
    });
  });
}

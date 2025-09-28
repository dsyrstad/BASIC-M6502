import 'package:test/test.dart';
import '../../lib/interpreter/interpreter.dart';
import '../../lib/interpreter/tokenizer.dart';
import '../../lib/interpreter/expression_evaluator.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';
import '../../lib/memory/program_storage.dart';
import '../../lib/memory/user_functions.dart';
import '../../lib/memory/arrays.dart';
import '../../lib/runtime/stack.dart';
import '../../lib/io/screen.dart';
import '../../lib/memory/values.dart';

void main() {
  group('User-Defined Functions (DEF FN)', () {
    late Memory memory;
    late Tokenizer tokenizer;
    late VariableStorage variables;
    late UserFunctionStorage userFunctions;
    late ArrayManager arrays;
    late ExpressionEvaluator expressionEvaluator;
    late ProgramStorage programStorage;
    late RuntimeStack runtimeStack;
    late Screen screen;
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

      variables.initialize(0x2000);
      // Initialize string space top for arrays
      memory.writeWord(Memory.fretop, 0x8000);
    });

    test('should define simple numeric function', () {
      interpreter.processDirectModeInput('DEF FNA(X) = X * 2');

      final functions = userFunctions.getDefinedFunctions();
      expect(functions, contains('FNA'));
    });

    test('should call simple numeric function', () {
      interpreter.processDirectModeInput('DEF FNA(X) = X * 2');

      final result = interpreter.evaluateExpressionFromString('FNA(5)');
      expect(result, isA<NumericValue>());
      expect((result as NumericValue).value, equals(10.0));
    });

    test('should define function with complex expression', () {
      interpreter.processDirectModeInput('DEF FNB(Y) = Y * Y + 2 * Y + 1');

      final result = interpreter.evaluateExpressionFromString('FNB(3)');
      expect(result, isA<NumericValue>());
      expect((result as NumericValue).value, equals(16.0)); // 9 + 6 + 1 = 16
    });

    test('should define string function', () {
      interpreter.processDirectModeInput('DEF FNS\$(A\$) = A\$ + " world"');

      variables.setVariable('B\$', StringValue('hello'));
      final result = interpreter.evaluateExpressionFromString('FNS\$(B\$)');
      expect(result, isA<StringValue>());
      expect((result as StringValue).value, equals('hello world'));
    });

    test('should handle function with complex calculation', () {
      interpreter.processDirectModeInput('DEF FNC(X) = X * X + X - 1');

      final result = interpreter.evaluateExpressionFromString('FNC(4)');
      expect(result, isA<NumericValue>());
      expect(
        (result as NumericValue).value,
        equals(19.0),
      ); // 4*4 + 4 - 1 = 16 + 4 - 1 = 19
    });

    test('should handle function call within expression', () {
      interpreter.processDirectModeInput('DEF FNA(X) = X * 2');

      final result = interpreter.evaluateExpressionFromString(
        'FNA(3) + FNA(4)',
      );
      expect(result, isA<NumericValue>());
      expect((result as NumericValue).value, equals(14.0)); // 6 + 8 = 14
    });

    test('should handle nested function calls', () {
      interpreter.processDirectModeInput('DEF FNA(X) = X * 2');
      interpreter.processDirectModeInput('DEF FNB(Y) = Y + 1');

      final result = interpreter.evaluateExpressionFromString('FNA(FNB(2))');
      expect(result, isA<NumericValue>());
      expect(
        (result as NumericValue).value,
        equals(6.0),
      ); // FNA(FNB(2)) = FNA(3) = 6
    });

    test('should handle function using built-in functions', () {
      interpreter.processDirectModeInput('DEF FND(X) = SIN(X) + COS(X)');

      final result = interpreter.evaluateExpressionFromString('FND(0)');
      expect(result, isA<NumericValue>());
      expect(
        (result as NumericValue).value,
        closeTo(1.0, 0.001),
      ); // sin(0) + cos(0) = 0 + 1 = 1
    });

    test('should handle function redefinition', () {
      interpreter.processDirectModeInput('DEF FNA(X) = X * 2');
      interpreter.processDirectModeInput('DEF FNA(Y) = Y * 3');

      final result = interpreter.evaluateExpressionFromString('FNA(4)');
      expect(result, isA<NumericValue>());
      expect(
        (result as NumericValue).value,
        equals(12.0),
      ); // Should use latest definition
    });

    test('should handle parameter shadowing', () {
      variables.setVariable('X', NumericValue(100.0));
      interpreter.processDirectModeInput('DEF FNA(X) = X * 2');

      final result = interpreter.evaluateExpressionFromString('FNA(5)');
      expect(result, isA<NumericValue>());
      expect(
        (result as NumericValue).value,
        equals(10.0),
      ); // Function parameter should shadow global X

      // Global X should remain unchanged
      final globalX = variables.getVariable('X');
      expect((globalX as NumericValue).value, equals(100.0));
    });

    test('should handle string function with string operations', () {
      interpreter.processDirectModeInput(
        'DEF FNT\$(S\$) = LEFT\$(S\$, 2) + RIGHT\$(S\$, 2)',
      );

      variables.setVariable('T\$', StringValue('HELLO'));
      final result = interpreter.evaluateExpressionFromString('FNT\$(T\$)');
      expect(result, isA<StringValue>());
      expect(
        (result as StringValue).value,
        equals('HELO'),
      ); // Left 2 + Right 2 = "HE" + "LO"
    });

    test('should throw error for undefined function', () {
      expect(
        () => interpreter.evaluateExpressionFromString('FNZ(5)'),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle constant function', () {
      interpreter.processDirectModeInput('DEF FNE(X) = 42');

      final result = interpreter.evaluateExpressionFromString('FNE(5)');
      expect(result, isA<NumericValue>());
      expect((result as NumericValue).value, equals(42.0));
    });
  });
}

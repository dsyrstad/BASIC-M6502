import 'package:test/test.dart';
import '../lib/interpreter/tokenizer.dart';
import '../lib/interpreter/expression_evaluator.dart';
import '../lib/memory/memory.dart';
import '../lib/memory/variables.dart';
import '../lib/memory/user_functions.dart';

void main() {
  group('String Functions Tests', () {
    late Memory memory;
    late Tokenizer tokenizer;
    late VariableStorage variables;
    late UserFunctionStorage userFunctions;
    late ExpressionEvaluator expressionEvaluator;

    setUp(() {
      memory = Memory();
      tokenizer = Tokenizer();
      variables = VariableStorage(memory);
      userFunctions = UserFunctionStorage();
      expressionEvaluator = ExpressionEvaluator(
        memory,
        variables,
        tokenizer,
        userFunctions,
      );

      // Initialize variable storage
      variables.initialize(0x2000);
    });

    // Helper function to evaluate expression from string
    dynamic evaluateExpression(String expression) {
      final tokens = tokenizer.tokenizeLine(expression);
      final result = expressionEvaluator.evaluateExpression(tokens, 0);
      return result.value;
    }

    group('LEN function', () {
      test('should return length of string', () {
        final result = evaluateExpression('LEN("HELLO")');
        expect(result.value, equals(5.0));
      });

      test('should return 0 for empty string', () {
        final result = evaluateExpression('LEN("")');
        expect(result.value, equals(0.0));
      });

      test('should work with string variables', () {
        variables.setVariable('A\$', StringValue('TESTING'));
        final result = evaluateExpression('LEN(A\$)');
        expect(result.value, equals(7.0));
      });
    });

    group('ASC function', () {
      test('should return ASCII code of first character', () {
        final result = evaluateExpression('ASC("A")');
        expect(result.value, equals(65.0));
      });

      test('should work with multi-character strings', () {
        final result = evaluateExpression('ASC("ABC")');
        expect(result.value, equals(65.0));
      });

      test('should error on empty string', () {
        expect(() => evaluateExpression('ASC("")'), throwsA(anything));
      });
    });

    group('CHR\$ function', () {
      test('should return character from ASCII code', () {
        final result = evaluateExpression('CHR\$(65)');
        expect(result.value, equals('A'));
      });

      test('should work with space character', () {
        final result = evaluateExpression('CHR\$(32)');
        expect(result.value, equals(' '));
      });

      test('should error on invalid codes', () {
        expect(() => evaluateExpression('CHR\$(256)'), throwsA(anything));
      });

      test('should error on negative codes', () {
        expect(() => evaluateExpression('CHR\$(-1)'), throwsA(anything));
      });
    });

    group('LEFT\$ function', () {
      test('should return leftmost characters', () {
        final result = evaluateExpression('LEFT\$("HELLO", 3)');
        expect(result.value, equals('HEL'));
      });

      test('should return whole string if count exceeds length', () {
        final result = evaluateExpression('LEFT\$("HELLO", 10)');
        expect(result.value, equals('HELLO'));
      });

      test('should return empty string for count 0', () {
        final result = evaluateExpression('LEFT\$("HELLO", 0)');
        expect(result.value, equals(''));
      });

      test('should work with string variables', () {
        variables.setVariable('A\$', StringValue('TESTING'));
        final result = evaluateExpression('LEFT\$(A\$, 4)');
        expect(result.value, equals('TEST'));
      });
    });

    group('RIGHT\$ function', () {
      test('should return rightmost characters', () {
        final result = evaluateExpression('RIGHT\$("HELLO", 3)');
        expect(result.value, equals('LLO'));
      });

      test('should return whole string if count exceeds length', () {
        final result = evaluateExpression('RIGHT\$("HELLO", 10)');
        expect(result.value, equals('HELLO'));
      });

      test('should return empty string for count 0', () {
        final result = evaluateExpression('RIGHT\$("HELLO", 0)');
        expect(result.value, equals(''));
      });

      test('should work with string variables', () {
        variables.setVariable('A\$', StringValue('TESTING'));
        final result = evaluateExpression('RIGHT\$(A\$, 3)');
        expect(result.value, equals('ING'));
      });
    });

    group('MID\$ function', () {
      test('should return substring from position', () {
        final result = evaluateExpression('MID\$("HELLO", 2, 3)');
        expect(result.value, equals('ELL'));
      });

      test('should return rest of string without length argument', () {
        final result = evaluateExpression('MID\$("HELLO", 3)');
        expect(result.value, equals('LLO'));
      });

      test('should handle position at end of string', () {
        final result = evaluateExpression('MID\$("HELLO", 6)');
        expect(result.value, equals(''));
      });

      test('should clip length to string bounds', () {
        final result = evaluateExpression('MID\$("HELLO", 4, 10)');
        expect(result.value, equals('LO'));
      });

      test('should work with string variables', () {
        variables.setVariable('A\$', StringValue('TESTING'));
        final result = evaluateExpression('MID\$(A\$, 2, 3)');
        expect(result.value, equals('EST'));
      });

      test('should use 1-based indexing', () {
        final result = evaluateExpression('MID\$("HELLO", 1, 1)');
        expect(result.value, equals('H'));
      });
    });

    group('String function combinations', () {
      test('should allow nested string functions', () {
        final result = evaluateExpression('LEFT\$(MID\$("HELLO WORLD", 7), 3)');
        expect(result.value, equals('WOR'));
      });

      test('should work with concatenation', () {
        final result = evaluateExpression(
          'LEFT\$("HELLO", 3) + RIGHT\$("WORLD", 3)',
        );
        expect(result.value, equals('HELRLD'));
      });

      test('should handle CHR\$ and ASC round trip', () {
        final result = evaluateExpression('CHR\$(ASC("X"))');
        expect(result.value, equals('X'));
      });
    });
  });
}

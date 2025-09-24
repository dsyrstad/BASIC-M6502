import 'package:test/test.dart';
import '../../lib/interpreter/expression_evaluator.dart';
import '../../lib/interpreter/tokenizer.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';
import '../../lib/memory/user_functions.dart';

void main() {
  group('ExpressionEvaluator', () {
    late Memory memory;
    late VariableStorage variables;
    late Tokenizer tokenizer;
    late UserFunctionStorage userFunctions;
    late ExpressionEvaluator evaluator;

    setUp(() {
      memory = Memory();
      variables = VariableStorage(memory);
      tokenizer = Tokenizer();
      userFunctions = UserFunctionStorage();
      evaluator = ExpressionEvaluator(
        memory,
        variables,
        tokenizer,
        userFunctions,
      );

      // Initialize variable storage
      variables.initialize(0x0800);
    });

    test('should evaluate simple number', () {
      final tokens = tokenizer.tokenizeLine('42');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(42.0));
    });

    test('should evaluate decimal number', () {
      final tokens = tokenizer.tokenizeLine('3.14');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(3.14));
    });

    test('should evaluate string literal', () {
      final tokens = tokenizer.tokenizeLine('"HELLO"');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<StringValue>());
      expect((result.value as StringValue).value, equals('HELLO'));
    });

    test('should evaluate variable reference', () {
      variables.setVariable('X', const NumericValue(123.0));

      final tokens = tokenizer.tokenizeLine('X');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(123.0));
    });

    test('should evaluate string variable reference', () {
      variables.setVariable('A\$', const StringValue('TEST'));

      final tokens = tokenizer.tokenizeLine('A\$');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<StringValue>());
      expect((result.value as StringValue).value, equals('TEST'));
    });

    test('should evaluate simple addition', () {
      final tokens = tokenizer.tokenizeLine('2 + 3');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(5.0));
    });

    test('should evaluate simple subtraction', () {
      final tokens = tokenizer.tokenizeLine('10 - 4');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(6.0));
    });

    test('should evaluate simple multiplication', () {
      final tokens = tokenizer.tokenizeLine('6 * 7');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(42.0));
    });

    test('should evaluate simple division', () {
      final tokens = tokenizer.tokenizeLine('15 / 3');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(5.0));
    });

    test('should evaluate power operation', () {
      final tokens = tokenizer.tokenizeLine('2 ^ 3');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(8.0));
    });

    test('should handle operator precedence', () {
      final tokens = tokenizer.tokenizeLine('2 + 3 * 4');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(14.0)); // 2 + (3 * 4)
    });

    test('should handle parentheses', () {
      final tokens = tokenizer.tokenizeLine('(2 + 3) * 4');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(20.0)); // (2 + 3) * 4
    });

    test('should handle unary minus', () {
      final tokens = tokenizer.tokenizeLine('-5');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(-5.0));
    });

    test('should handle unary plus', () {
      final tokens = tokenizer.tokenizeLine('+7');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(7.0));
    });

    test('should evaluate string concatenation', () {
      final tokens = tokenizer.tokenizeLine('"HELLO" + "WORLD"');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<StringValue>());
      expect((result.value as StringValue).value, equals('HELLOWORLD'));
    });

    test('should evaluate comparison operators', () {
      var tokens = tokenizer.tokenizeLine('5 = 5');
      var result = evaluator.evaluateExpression(tokens, 0);
      expect((result.value as NumericValue).value, equals(1.0)); // True

      tokens = tokenizer.tokenizeLine('3 < 5');
      result = evaluator.evaluateExpression(tokens, 0);
      expect((result.value as NumericValue).value, equals(1.0)); // True

      tokens = tokenizer.tokenizeLine('7 > 5');
      result = evaluator.evaluateExpression(tokens, 0);
      expect((result.value as NumericValue).value, equals(1.0)); // True

      tokens = tokenizer.tokenizeLine('3 > 5');
      result = evaluator.evaluateExpression(tokens, 0);
      expect((result.value as NumericValue).value, equals(0.0)); // False
    });

    test('should evaluate ABS function', () {
      final tokens = tokenizer.tokenizeLine('ABS(-5)');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(5.0));
    });

    test('should evaluate INT function', () {
      final tokens = tokenizer.tokenizeLine('INT(3.7)');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(3.0));
    });

    test('should evaluate SGN function', () {
      var tokens = tokenizer.tokenizeLine('SGN(5)');
      var result = evaluator.evaluateExpression(tokens, 0);
      expect((result.value as NumericValue).value, equals(1.0));

      tokens = tokenizer.tokenizeLine('SGN(-3)');
      result = evaluator.evaluateExpression(tokens, 0);
      expect((result.value as NumericValue).value, equals(-1.0));

      tokens = tokenizer.tokenizeLine('SGN(0)');
      result = evaluator.evaluateExpression(tokens, 0);
      expect((result.value as NumericValue).value, equals(0.0));
    });

    test('should handle division by zero', () {
      final tokens = tokenizer.tokenizeLine('5 / 0');
      expect(
        () => evaluator.evaluateExpression(tokens, 0),
        throwsA(isA<ExpressionException>()),
      );
    });

    test('should handle type mismatch errors', () {
      final tokens = tokenizer.tokenizeLine('"STRING" * 5');
      expect(
        () => evaluator.evaluateExpression(tokens, 0),
        throwsA(isA<ExpressionException>()),
      );
    });

    test('should handle syntax errors', () {
      expect(
        () => evaluator.evaluateExpression(tokenizer.tokenizeLine('5 +'), 0),
        throwsA(isA<ExpressionException>()),
      );

      expect(
        () => evaluator.evaluateExpression(tokenizer.tokenizeLine('(5'), 0),
        throwsA(isA<ExpressionException>()),
      );
    });

    test('should handle complex expressions', () {
      variables.setVariable('A', const NumericValue(2.0));
      variables.setVariable('B', const NumericValue(3.0));

      final tokens = tokenizer.tokenizeLine('A * B + 10 / 2');
      final result = evaluator.evaluateExpression(tokens, 0);

      expect(result.value, isA<NumericValue>());
      expect(
        (result.value as NumericValue).value,
        equals(11.0),
      ); // 2 * 3 + 10 / 2 = 6 + 5 = 11
    });
  });
}

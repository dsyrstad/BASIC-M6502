import 'lib/interpreter/tokenizer.dart';
import 'lib/interpreter/expression_evaluator.dart';
import 'lib/memory/memory.dart';
import 'lib/memory/variables.dart';

void main() {
  final memory = Memory();
  final tokenizer = Tokenizer();
  final variables = VariableStorage(memory);
  final expressionEvaluator = ExpressionEvaluator(memory, variables, tokenizer);

  // Initialize variable storage
  variables.initialize(0x2000);

  // Test simple arithmetic expression
  final tokens = tokenizer.tokenizeLine('20 + 20');
  print('Tokenized: ${tokens.map((t) => t.toString()).join(', ')}');

  try {
    final result = expressionEvaluator.evaluateExpression(tokens, 0);
    print('Result: ${result.value} at position ${result.endPosition}');
    if (result.value is NumericValue) {
      print('Numeric value: ${(result.value as NumericValue).value}');
      print('As int: ${(result.value as NumericValue).value.toInt()}');
    }
  } catch (e) {
    print('Error evaluating expression: $e');
  }
}
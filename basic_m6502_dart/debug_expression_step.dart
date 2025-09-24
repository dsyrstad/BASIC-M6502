import 'lib/interpreter/tokenizer.dart';
import 'lib/interpreter/expression_evaluator.dart';
import 'lib/memory/memory.dart';
import 'lib/memory/variables.dart';

void main() {
  final memory = Memory();
  final tokenizer = Tokenizer();
  final variables = VariableStorage(memory);

  // Initialize variable storage
  variables.initialize(0x2000);

  // Create a custom expression evaluator for debugging
  final expressionEvaluator = DebugExpressionEvaluator(memory, variables, tokenizer);

  // Test the problematic expression
  print('=== Testing LEFT\$("HELLO", 3) + RIGHT\$("WORLD", 3) ===');
  final tokens = tokenizer.tokenizeLine('LEFT\$("HELLO", 3) + RIGHT\$("WORLD", 3)');
  print('Tokens: ${tokens.map((t) => t.toString()).join(' ')}');

  try {
    final result = expressionEvaluator.evaluateExpression(tokens, 0);
    print('Final result: ${result.value} (type: ${result.value.runtimeType})');
  } catch (e) {
    print('Error: $e');
  }
}

class DebugExpressionEvaluator extends ExpressionEvaluator {
  DebugExpressionEvaluator(memory, variables, tokenizer) : super(memory, variables, tokenizer);

  @override
  ExpressionResult evaluateExpression(List<int> tokens, int startPos) {
    print('>>> evaluateExpression called with startPos=$startPos, tokens length=${tokens.length}');
    final result = super.evaluateExpression(tokens, startPos);
    print('<<< evaluateExpression returning ${result.value} at position ${result.endPosition}');
    return result;
  }
}
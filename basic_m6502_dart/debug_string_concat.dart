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

  // Helper function to evaluate expression from string
  dynamic evaluateExpression(String expression) {
    print('Evaluating: $expression');
    final tokens = tokenizer.tokenizeLine(expression);
    print('Tokens: ${tokens.map((t) => t.toString()).join(' ')}');
    final result = expressionEvaluator.evaluateExpression(tokens, 0);
    print('Result: ${result.value} (type: ${result.value.runtimeType})');
    return result.value;
  }

  // Test individual parts
  print('\n=== Testing LEFT\$ ===');
  final left = evaluateExpression('LEFT\$("HELLO", 3)');

  print('\n=== Testing RIGHT\$ ===');
  final right = evaluateExpression('RIGHT\$("WORLD", 3)');

  print('\n=== Testing Simple String Concatenation ===');
  final simpleConcat = evaluateExpression('"HEL" + "RLD"');

  print('\n=== Testing Variable Concatenation ===');
  variables.setVariable('A\$', StringValue('HEL'));
  variables.setVariable('B\$', StringValue('RLD'));
  final varConcat = evaluateExpression('A\$ + B\$');

  print('\n=== Testing Concatenation ===');
  final concat = evaluateExpression('LEFT\$("HELLO", 3) + RIGHT\$("WORLD", 3)');

  print('\nFinal values:');
  print('LEFT\$: ${left.value}');
  print('RIGHT\$: ${right.value}');
  print('Simple concat: ${simpleConcat.value}');
  print('Variable concat: ${varConcat.value}');
  print('Function concat: ${concat.value}');
}

import 'lib/interpreter/interpreter.dart';
import 'lib/interpreter/tokenizer.dart';
import 'lib/interpreter/expression_evaluator.dart';
import 'lib/memory/memory.dart';
import 'lib/memory/variables.dart';

void main() {
  final memory = Memory();
  final tokenizer = Tokenizer();
  final variables = VariableStorage(memory);
  final expressionEvaluator = ExpressionEvaluator(memory, variables, tokenizer);
  final interpreter = Interpreter(memory, tokenizer, variables, expressionEvaluator);

  // Initialize variable storage
  variables.initialize(0x2000);

  print('Testing LET A = 42...');
  try {
    interpreter.executeLine('LET A = 42');
    final value = variables.getVariable('A');
    print('A = $value');
  } catch (e) {
    print('Error: $e');
  }

  print('\nTesting C = 100...');
  try {
    interpreter.executeLine('C = 100');
    final value = variables.getVariable('C');
    print('C = $value');
  } catch (e) {
    print('Error: $e');
  }

  print('\nTokenizing "C = 100":');
  final tokens = tokenizer.tokenizeLine('C = 100');
  print('Tokens: $tokens');
  for (int i = 0; i < tokens.length; i++) {
    print('  [$i]: ${tokens[i]} (${String.fromCharCode(tokens[i])})');
  }
}
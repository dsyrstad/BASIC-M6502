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

  print('Testing INVALID...');
  try {
    interpreter.executeLine('INVALID');
  } catch (e) {
    print('Error: $e');
  }

  print('\nTokenizing "INVALID":');
  final tokens = tokenizer.tokenizeLine('INVALID');
  print('Tokens: $tokens');
  for (int i = 0; i < tokens.length; i++) {
    if (tokens[i] >= 32 && tokens[i] <= 126) {
      print('  [$i]: ${tokens[i]} (${String.fromCharCode(tokens[i])})');
    } else {
      print('  [$i]: ${tokens[i]}');
    }
  }
}
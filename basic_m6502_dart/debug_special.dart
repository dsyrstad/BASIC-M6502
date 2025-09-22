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

  print('Testing @#\$%...');
  try {
    interpreter.executeLine('@#\$%');
  } catch (e) {
    print('Error: $e');
  }
}
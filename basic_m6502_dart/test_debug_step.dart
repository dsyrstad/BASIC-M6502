import 'lib/interpreter/interpreter.dart';
import 'lib/interpreter/tokenizer.dart';
import 'lib/interpreter/expression_evaluator.dart';
import 'lib/memory/memory.dart';
import 'lib/memory/variables.dart';
import 'lib/memory/program_storage.dart';
import 'lib/runtime/stack.dart';

void main() {
  final memory = Memory();
  final tokenizer = Tokenizer();
  final variables = VariableStorage(memory);
  final programStorage = ProgramStorage(memory);
  final expressionEvaluator = ExpressionEvaluator(memory, variables, tokenizer);
  final runtimeStack = RuntimeStack(memory, variables);
  final interpreter = Interpreter(memory, tokenizer, variables, expressionEvaluator, programStorage, runtimeStack);

  print('=== Step-by-step debugging ===\n');

  // Test two variables
  interpreter.executeLine('10 INPUT N\$, AGE');
  interpreter.executeLine('20 PRINT "Name: "; N\$; " Age: "; AGE');
  interpreter.executeLine('30 END');

  print('Program stored. Listing:');
  interpreter.executeLine('LIST');

  print('\nNow trying to run...');

  // Test RUN
  try {
    interpreter.executeLine('RUN');
  } catch (e) {
    print('Exception caught: $e');
    print('Exception type: ${e.runtimeType}');
  }
}
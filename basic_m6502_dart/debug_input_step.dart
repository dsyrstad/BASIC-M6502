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

  print('=== Debugging INPUT Statement ===\n');

  try {
    print('Adding line 10...');
    interpreter.executeLine('10 INPUT "Enter name: "; N\$');
    print('Success!\n');

    print('Adding line 20...');
    interpreter.executeLine('20 PRINT N\$');
    print('Success!\n');

    print('Adding line 30...');
    interpreter.executeLine('30 END');
    print('Success!\n');

    print('Listing program:');
    interpreter.executeLine('LIST');

    print('\nRunning...');
    // Don't actually run to avoid waiting for input
    // interpreter.executeLine('RUN');
  } catch (e) {
    print('Error: $e');
  }
}
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
  final expressionEvaluator = ExpressionEvaluator(memory, variables, tokenizer);
  final programStorage = ProgramStorage(memory);
  final runtimeStack = RuntimeStack(memory, variables);
  final interpreter = Interpreter(memory, tokenizer, variables, expressionEvaluator, programStorage, runtimeStack);

  // Initialize variable storage
  variables.initialize(0x2000);

  print('Testing FOR/NEXT in program mode...\n');

  // Test 1: Simple FOR loop
  print('=== Test 1: Simple FOR loop ===');
  try {
    interpreter.executeLine('10 FOR I = 1 TO 3');
    interpreter.executeLine('20 PRINT I');
    interpreter.executeLine('30 NEXT I');
    interpreter.executeLine('40 PRINT "DONE"');

    print('Program stored:');
    interpreter.executeLine('LIST');

    print('\nRunning program...');
    // Don't use RUN in mainLoop, manually start execution
    interpreter.executeLine('RUN');
  } catch (e) {
    print('Error: $e');
  }
}
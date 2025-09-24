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
  final interpreter = Interpreter(
    memory,
    tokenizer,
    variables,
    expressionEvaluator,
    programStorage,
    runtimeStack,
  );

  // Initialize variable storage
  variables.initialize(0x2000);

  print('Testing FOR/NEXT loops...\n');

  // Test 1: Simple FOR loop
  print('=== Test 1: Simple counting loop ===');
  try {
    interpreter.executeLine('10 FOR I = 1 TO 3');
    interpreter.executeLine('20 PRINT I');
    interpreter.executeLine('30 NEXT I');
    interpreter.executeLine('40 PRINT "DONE"');

    print('Program stored. Running...');
    interpreter.executeLine('RUN');
  } catch (e) {
    print('Error in test 1: $e');
  }

  print('\n=== Test 2: FOR with STEP ===');
  try {
    // Clear the program first
    interpreter.executeLine('NEW');

    interpreter.executeLine('10 FOR J = 5 TO 15 STEP 3');
    interpreter.executeLine('20 PRINT J');
    interpreter.executeLine('30 NEXT J');
    interpreter.executeLine('40 PRINT "FINISHED"');

    print('Program stored. Running...');
    interpreter.executeLine('RUN');
  } catch (e) {
    print('Error in test 2: $e');
  }

  print('\n=== Test 3: Negative STEP ===');
  try {
    // Clear the program first
    interpreter.executeLine('NEW');

    interpreter.executeLine('10 FOR K = 10 TO 1 STEP -2');
    interpreter.executeLine('20 PRINT K');
    interpreter.executeLine('30 NEXT K');
    interpreter.executeLine('40 PRINT "COUNTDOWN DONE"');

    print('Program stored. Running...');
    interpreter.executeLine('RUN');
  } catch (e) {
    print('Error in test 3: $e');
  }

  print('\n=== Test 4: Loop that doesn\'t execute ===');
  try {
    // Clear the program first
    interpreter.executeLine('NEW');

    interpreter.executeLine('10 FOR M = 10 TO 5');
    interpreter.executeLine('20 PRINT "SHOULD NOT PRINT"');
    interpreter.executeLine('30 NEXT M');
    interpreter.executeLine('40 PRINT "AFTER LOOP"');

    print('Program stored. Running...');
    interpreter.executeLine('RUN');
  } catch (e) {
    print('Error in test 4: $e');
  }
}

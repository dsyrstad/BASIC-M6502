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

  print('Testing step-by-step execution...\n');

  try {
    // Store the program
    interpreter.executeLine('10 PRINT "STARTING"');
    interpreter.executeLine('20 FOR I = 1 TO 3');
    interpreter.executeLine('30 PRINT I');
    interpreter.executeLine('40 NEXT I');
    interpreter.executeLine('50 PRINT "DONE"');

    print('Program stored:');
    interpreter.executeLine('LIST');

    print('\nProgram state: isRunning=${interpreter.isRunning}');
    print('Direct mode: ${interpreter.isInDirectMode}');
    print('Program mode: ${interpreter.isInProgramMode}');

    print('\nStarting RUN...');
    interpreter.executeLine('RUN');

    print('After RUN command:');
    print('Program state: isRunning=${interpreter.isRunning}');
    print('Direct mode: ${interpreter.isInDirectMode}');
    print('Program mode: ${interpreter.isInProgramMode}');

    // Try to manually step through the main loop
    print('\nAttempting main loop execution...');
    int steps = 0;
    while (interpreter.isRunning && interpreter.isInProgramMode && steps < 20) {
      print('Step ${steps + 1}...');
      // This should execute the next statement in program mode
      // But we need a way to step through the execution
      steps++;

      // The issue is that we need to call the main loop or have a step method
      break; // For now, just break to avoid infinite loop
    }

  } catch (e) {
    print('Error: $e');
    print('Stack trace: ${e.runtimeType}');
  }
}
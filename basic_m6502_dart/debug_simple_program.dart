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

  print('Testing simple program execution...\n');

  // Test 1: Simple program without loops
  print('=== Test 1: Simple program ===');
  try {
    interpreter.executeLine('10 PRINT "HELLO"');
    interpreter.executeLine('20 PRINT "WORLD"');
    interpreter.executeLine('LIST');

    print('\nRunning program...');
    interpreter.executeLine('RUN');
  } catch (e) {
    print('Error in test 1: $e');
  }

  print('\n=== Test 2: Variables ===');
  try {
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 LET A = 5');
    interpreter.executeLine('20 PRINT A');
    interpreter.executeLine('LIST');

    print('\nRunning program...');
    interpreter.executeLine('RUN');
  } catch (e) {
    print('Error in test 2: $e');
  }
}
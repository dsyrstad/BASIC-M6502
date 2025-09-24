import 'lib/interpreter/interpreter.dart';
import 'lib/interpreter/tokenizer.dart';
import 'lib/interpreter/expression_evaluator.dart';
import 'lib/memory/memory.dart';
import 'lib/memory/variables.dart';
import 'lib/memory/program_storage.dart';
import 'lib/runtime/stack.dart';
import 'lib/io/screen.dart';

void main() {
  final memory = Memory();
  final tokenizer = Tokenizer();
  final variables = VariableStorage(memory);
  final expressionEvaluator = ExpressionEvaluator(memory, variables, tokenizer);
  final programStorage = ProgramStorage(memory);
  final runtimeStack = RuntimeStack(memory, variables);
  final screen = Screen();
  final interpreter = Interpreter(
    memory,
    tokenizer,
    variables,
    expressionEvaluator,
    programStorage,
    runtimeStack,
    screen,
  );

  // Initialize variable storage
  variables.initialize(0x2000);

  print('Simple line editing test...\n');

  try {
    // Add a line
    print('Adding line 10...');
    interpreter.executeLine('10 PRINT "HELLO"');

    print('Listing...');
    interpreter.executeLine('LIST');

    // Replace the line
    print('\nReplacing line 10...');
    interpreter.executeLine('10 PRINT "GOODBYE"');

    print('Listing...');
    interpreter.executeLine('LIST');

    // Delete the line
    print('\nDeleting line 10...');
    interpreter.executeLine('10');

    print('Listing...');
    interpreter.executeLine('LIST');
  } catch (e) {
    print('Error: $e');
    print('Stack trace:');
    print(StackTrace.current);
  }
}

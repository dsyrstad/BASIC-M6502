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
  final interpreter = Interpreter(memory, tokenizer, variables, expressionEvaluator, programStorage, runtimeStack, screen);

  // Initialize variable storage
  variables.initialize(0x2000);

  // Test expression evaluation in GOTO context directly
  print('Testing direct execution of GOTO 20 + 20...');
  try {
    final tokens4 = tokenizer.tokenizeLine('PRINT "REACHED 40"');
    programStorage.storeLine(40, tokens4);

    print('Lines in program: ${programStorage.getAllLineNumbers()}');

    // Execute the GOTO statement directly
    interpreter.executeLine('GOTO 20 + 20');
  } catch (e) {
    print('Error: $e');
    print('Stack trace:');
    print(StackTrace.current);
  }
}
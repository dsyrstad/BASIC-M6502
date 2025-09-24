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
  final interpreter = Interpreter(
    memory,
    tokenizer,
    variables,
    expressionEvaluator,
    programStorage,
    runtimeStack,
  );

  print('=== Testing INPUT Statement ===\n');

  // Test 1: Simple INPUT with prompt
  print('Test 1: INPUT with prompt');
  interpreter.executeLine('10 INPUT "Enter your name: "; N\$');
  interpreter.executeLine('20 PRINT "Hello, "; N\$');
  interpreter.executeLine('30 END');

  interpreter.executeLine('RUN');

  // Clear program for next test
  interpreter.executeLine('NEW');
  interpreter.reset();

  print('\n\nTest 2: INPUT with multiple variables');
  interpreter.executeLine('10 INPUT "Enter name and age: "; NAME\$, AGE');
  interpreter.executeLine('20 PRINT "Name: "; NAME\$');
  interpreter.executeLine('30 PRINT "Age: "; AGE');
  interpreter.executeLine('40 END');

  interpreter.executeLine('RUN');

  // Clear program for next test
  interpreter.executeLine('NEW');
  interpreter.reset();

  print('\n\nTest 3: INPUT without prompt');
  interpreter.executeLine('10 PRINT "Please enter a number"');
  interpreter.executeLine('20 INPUT X');
  interpreter.executeLine('30 PRINT "You entered: "; X');
  interpreter.executeLine('40 END');

  interpreter.executeLine('RUN');

  print('\n=== INPUT tests complete ===');
}

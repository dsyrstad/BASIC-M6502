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

  print('=== Testing Mixed String/Numeric INPUT ===\n');

  // Test with string and numeric variables - using NO prompt for now
  interpreter.executeLine('10 INPUT N\$, AGE');
  interpreter.executeLine('20 PRINT "Hello "; N\$; ", you are "; AGE; " years old."');
  interpreter.executeLine('30 END');

  interpreter.executeLine('LIST');
  print('\nRunning... (enter: name,age)\n');
  interpreter.executeLine('RUN');
}
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

  print('=== Testing Simple Program ===\n');

  // Simple test without INPUT
  interpreter.executeLine('10 PRINT "Hello"');
  interpreter.executeLine('20 END');

  interpreter.executeLine('LIST');
  print('\nRunning...\n');
  interpreter.executeLine('RUN');
}

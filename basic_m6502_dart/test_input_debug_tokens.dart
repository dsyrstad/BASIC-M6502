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

  print('=== Debugging INPUT tokenization ===\n');

  // Test tokenization directly
  final testLine = 'INPUT "Enter name and age: "; N\$, AGE';
  print('Original line: $testLine');

  final tokens = tokenizer.tokenizeLine(testLine);
  print('Tokenized: $tokens');

  // Check if INPUT token is present
  for (int i = 0; i < tokens.length; i++) {
    if (tokens[i] == Tokenizer.inputToken) {
      print('Found INPUT token (${Tokenizer.inputToken}) at position $i');
    }
  }

  print('INPUT token value: ${Tokenizer.inputToken}');
  print(
    'isStatement(${Tokenizer.inputToken}): ${tokenizer.isStatement(Tokenizer.inputToken)}',
  );

  // Now test the program execution
  interpreter.executeLine('10 $testLine');
  interpreter.executeLine('20 END');
  interpreter.executeLine('LIST');

  print('\nNow running the program...');
  try {
    interpreter.executeLine('RUN');
  } catch (e) {
    print('Error during RUN: $e');
  }
}

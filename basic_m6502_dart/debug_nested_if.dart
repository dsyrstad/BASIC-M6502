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

  print('Testing nested IF statements...');

  // Test 1: Both conditions true
  print('\nTest 1: Both conditions true');
  try {
    final tokens1 = tokenizer.tokenizeLine('A = 1');
    programStorage.storeLine(10, tokens1);
    final tokens2 = tokenizer.tokenizeLine('B = 2');
    programStorage.storeLine(20, tokens2);
    final tokens3 = tokenizer.tokenizeLine(
      'IF A = 1 THEN IF B = 2 THEN PRINT "NESTED IF WORKS!"',
    );
    programStorage.storeLine(30, tokens3);

    interpreter.executeLine('RUN');

    // Check variable values
    print('A = ${(variables.getVariable('A') as NumericValue).value}');
    print('B = ${(variables.getVariable('B') as NumericValue).value}');
  } catch (e) {
    print('Error: $e');
  }

  // Test 2: First condition false
  print('\nTest 2: First condition false');
  try {
    interpreter.executeLine('NEW');

    final tokens1 = tokenizer.tokenizeLine('A = 2'); // Changed to 2
    programStorage.storeLine(10, tokens1);
    final tokens2 = tokenizer.tokenizeLine('B = 2');
    programStorage.storeLine(20, tokens2);
    final tokens3 = tokenizer.tokenizeLine(
      'IF A = 1 THEN IF B = 2 THEN PRINT "SHOULD NOT PRINT"',
    );
    programStorage.storeLine(30, tokens3);
    final tokens4 = tokenizer.tokenizeLine('PRINT "END OF PROGRAM"');
    programStorage.storeLine(40, tokens4);

    interpreter.executeLine('RUN');

    print('A = ${(variables.getVariable('A') as NumericValue).value}');
    print('B = ${(variables.getVariable('B') as NumericValue).value}');
  } catch (e) {
    print('Error: $e');
  }
}

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

  // Test simple arithmetic expression first
  print('Testing simple GOTO 20 + 20...');
  try {
    final tokens1 = tokenizer.tokenizeLine('PRINT "LINE 10"');
    programStorage.storeLine(10, tokens1);
    final tokens2 = tokenizer.tokenizeLine('GOTO 20 + 20');
    programStorage.storeLine(20, tokens2);
    final tokens3 = tokenizer.tokenizeLine('PRINT "LINE 30"');
    programStorage.storeLine(30, tokens3);
    final tokens4 = tokenizer.tokenizeLine('PRINT "LINE 40"');
    programStorage.storeLine(40, tokens4);

    interpreter.executeLine('RUN');
  } catch (e) {
    print('Error: $e');
  }

  print('\nTesting computed GOTO with variables...');
  try {
    // Clear program and start fresh
    interpreter.executeLine('NEW');

    // Set up variables
    interpreter.executeLine('A = 30');
    interpreter.executeLine('B = 10');
    print('A = ${variables.getVariable('A')}');
    print('B = ${variables.getVariable('B')}');

    // Now try the computed goto
    interpreter.executeLine('GOTO A + B');
  } catch (e) {
    print('Error: $e');
  }
}
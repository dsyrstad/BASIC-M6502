import 'lib/memory/memory.dart';
import 'lib/memory/variables.dart';
import 'lib/memory/program_storage.dart';
import 'lib/runtime/stack.dart';
import 'lib/interpreter/tokenizer.dart';
import 'lib/interpreter/expression_evaluator.dart';
import 'lib/interpreter/interpreter.dart';

void main() {
  print('=== BASIC M6502 GOSUB/RETURN Demo ===\n');

  // Initialize interpreter
  final memory = Memory();
  final variables = VariableStorage(memory);
  final programStorage = ProgramStorage(memory);
  final runtimeStack = RuntimeStack(memory, variables);
  final tokenizer = Tokenizer();
  final expressionEvaluator = ExpressionEvaluator(memory, variables, tokenizer);
  final interpreter = Interpreter(memory, tokenizer, variables, expressionEvaluator, programStorage, runtimeStack);

  print('Demo 1: Simple GOSUB and RETURN');
  print('Program:');
  print('10 PRINT "BEFORE GOSUB"');
  print('20 GOSUB 100');
  print('30 PRINT "AFTER GOSUB"');
  print('40 END');
  print('100 PRINT "IN SUBROUTINE"');
  print('110 RETURN');
  print('\nOutput:');

  // Enter the program
  interpreter.executeLine('10 PRINT "BEFORE GOSUB"');
  interpreter.executeLine('20 GOSUB 100');
  interpreter.executeLine('30 PRINT "AFTER GOSUB"');
  interpreter.executeLine('40 END');
  interpreter.executeLine('100 PRINT "IN SUBROUTINE"');
  interpreter.executeLine('110 RETURN');

  // Run the program
  interpreter.executeLine('RUN');

  print('\n===================\n');

  // Clear for next demo
  interpreter.executeLine('NEW');

  print('Demo 2: Nested GOSUB calls');
  print('Program:');
  print('10 PRINT "MAIN"');
  print('20 GOSUB 200');
  print('30 PRINT "BACK IN MAIN"');
  print('40 END');
  print('200 PRINT "SUB1"');
  print('210 GOSUB 300');
  print('220 PRINT "BACK IN SUB1"');
  print('230 RETURN');
  print('300 PRINT "SUB2"');
  print('310 RETURN');
  print('\nOutput:');

  // Enter the program
  interpreter.executeLine('10 PRINT "MAIN"');
  interpreter.executeLine('20 GOSUB 200');
  interpreter.executeLine('30 PRINT "BACK IN MAIN"');
  interpreter.executeLine('40 END');
  interpreter.executeLine('200 PRINT "SUB1"');
  interpreter.executeLine('210 GOSUB 300');
  interpreter.executeLine('220 PRINT "BACK IN SUB1"');
  interpreter.executeLine('230 RETURN');
  interpreter.executeLine('300 PRINT "SUB2"');
  interpreter.executeLine('310 RETURN');

  // Run the program
  interpreter.executeLine('RUN');

  print('\n===================\n');

  // Clear for next demo
  interpreter.executeLine('NEW');

  print('Demo 3: GOSUB with variables');
  print('Program:');
  print('10 A = 5');
  print('20 PRINT "A ="; A');
  print('30 GOSUB 100');
  print('40 PRINT "A ="; A');
  print('50 END');
  print('100 A = A + 1');
  print('110 PRINT "IN SUB: A ="; A');
  print('120 RETURN');
  print('\nOutput:');

  // Enter the program
  interpreter.executeLine('10 A = 5');
  interpreter.executeLine('20 PRINT "A ="; A');
  interpreter.executeLine('30 GOSUB 100');
  interpreter.executeLine('40 PRINT "A ="; A');
  interpreter.executeLine('50 END');
  interpreter.executeLine('100 A = A + 1');
  interpreter.executeLine('110 PRINT "IN SUB: A ="; A');
  interpreter.executeLine('120 RETURN');

  // Run the program
  interpreter.executeLine('RUN');

  print('\n=== Demo complete ===');
}
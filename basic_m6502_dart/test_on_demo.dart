import 'lib/memory/memory.dart';
import 'lib/memory/variables.dart';
import 'lib/memory/program_storage.dart';
import 'lib/runtime/stack.dart';
import 'lib/interpreter/tokenizer.dart';
import 'lib/interpreter/expression_evaluator.dart';
import 'lib/interpreter/interpreter.dart';

void main() {
  print('=== BASIC M6502 ON Statement Demo ===\n');

  // Initialize interpreter
  final memory = Memory();
  final variables = VariableStorage(memory);
  final programStorage = ProgramStorage(memory);
  final runtimeStack = RuntimeStack(memory, variables);
  final tokenizer = Tokenizer();
  final expressionEvaluator = ExpressionEvaluator(memory, variables, tokenizer);
  final interpreter = Interpreter(
    memory,
    tokenizer,
    variables,
    expressionEvaluator,
    programStorage,
    runtimeStack,
  );

  print('Demo 1: ON GOTO with menu selection');
  print('Program:');
  print('10 PRINT "MENU:"');
  print('20 PRINT "1. FIRST OPTION"');
  print('30 PRINT "2. SECOND OPTION"');
  print('40 PRINT "3. THIRD OPTION"');
  print('50 C = 2');
  print('60 ON C GOTO 100, 200, 300');
  print('70 PRINT "INVALID CHOICE"');
  print('80 END');
  print('100 PRINT "YOU CHOSE FIRST"');
  print('110 END');
  print('200 PRINT "YOU CHOSE SECOND"');
  print('210 END');
  print('300 PRINT "YOU CHOSE THIRD"');
  print('310 END');
  print('\nOutput:');

  // Enter the program
  interpreter.executeLine('10 PRINT "MENU:"');
  interpreter.executeLine('20 PRINT "1. FIRST OPTION"');
  interpreter.executeLine('30 PRINT "2. SECOND OPTION"');
  interpreter.executeLine('40 PRINT "3. THIRD OPTION"');
  interpreter.executeLine('50 C = 2');
  interpreter.executeLine('60 ON C GOTO 100, 200, 300');
  interpreter.executeLine('70 PRINT "INVALID CHOICE"');
  interpreter.executeLine('80 END');
  interpreter.executeLine('100 PRINT "YOU CHOSE FIRST"');
  interpreter.executeLine('110 END');
  interpreter.executeLine('200 PRINT "YOU CHOSE SECOND"');
  interpreter.executeLine('210 END');
  interpreter.executeLine('300 PRINT "YOU CHOSE THIRD"');
  interpreter.executeLine('310 END');

  // Run the program
  interpreter.executeLine('RUN');

  print('\n===================\n');

  // Clear for next demo
  interpreter.executeLine('NEW');

  print('Demo 2: ON GOSUB with calculations');
  print('Program:');
  print('10 A = 5');
  print('20 B = 3');
  print('30 PRINT "A ="; A; "B ="; B');
  print('40 OP = 1');
  print('50 ON OP GOSUB 100, 200, 300, 400');
  print('60 PRINT "DONE"');
  print('70 END');
  print('100 PRINT "SUM ="; A + B');
  print('110 RETURN');
  print('200 PRINT "DIFFERENCE ="; A - B');
  print('210 RETURN');
  print('300 PRINT "PRODUCT ="; A * B');
  print('310 RETURN');
  print('400 PRINT "QUOTIENT ="; A / B');
  print('410 RETURN');
  print('\nOutput:');

  // Enter the program
  interpreter.executeLine('10 A = 5');
  interpreter.executeLine('20 B = 3');
  interpreter.executeLine('30 PRINT "A ="; A; "B ="; B');
  interpreter.executeLine('40 OP = 1');
  interpreter.executeLine('50 ON OP GOSUB 100, 200, 300, 400');
  interpreter.executeLine('60 PRINT "DONE"');
  interpreter.executeLine('70 END');
  interpreter.executeLine('100 PRINT "SUM ="; A + B');
  interpreter.executeLine('110 RETURN');
  interpreter.executeLine('200 PRINT "DIFFERENCE ="; A - B');
  interpreter.executeLine('210 RETURN');
  interpreter.executeLine('300 PRINT "PRODUCT ="; A * B');
  interpreter.executeLine('310 RETURN');
  interpreter.executeLine('400 PRINT "QUOTIENT ="; A / B');
  interpreter.executeLine('410 RETURN');

  // Run the program
  interpreter.executeLine('RUN');

  print('\n===================\n');

  // Clear for next demo
  interpreter.executeLine('NEW');

  print('Demo 3: ON with expression and out-of-range handling');
  print('Program:');
  print('10 FOR I = 0 TO 4');
  print('20 PRINT "I ="; I; ": ";');
  print('30 ON I GOTO 100, 200, 300');
  print('40 PRINT "OUT OF RANGE"');
  print('50 GOTO 80');
  print('60 PRINT "ERROR"');
  print('70 GOTO 80');
  print('80 NEXT I');
  print('90 END');
  print('100 PRINT "FIRST"');
  print('110 GOTO 80');
  print('200 PRINT "SECOND"');
  print('210 GOTO 80');
  print('300 PRINT "THIRD"');
  print('310 GOTO 80');
  print('\nOutput:');

  // Enter the program
  interpreter.executeLine('10 FOR I = 0 TO 4');
  interpreter.executeLine('20 PRINT "I ="; I; ": ";');
  interpreter.executeLine('30 ON I GOTO 100, 200, 300');
  interpreter.executeLine('40 PRINT "OUT OF RANGE"');
  interpreter.executeLine('50 GOTO 80');
  interpreter.executeLine('60 PRINT "ERROR"');
  interpreter.executeLine('70 GOTO 80');
  interpreter.executeLine('80 NEXT I');
  interpreter.executeLine('90 END');
  interpreter.executeLine('100 PRINT "FIRST"');
  interpreter.executeLine('110 GOTO 80');
  interpreter.executeLine('200 PRINT "SECOND"');
  interpreter.executeLine('210 GOTO 80');
  interpreter.executeLine('300 PRINT "THIRD"');
  interpreter.executeLine('310 GOTO 80');

  // Run the program
  interpreter.executeLine('RUN');

  print('\n=== Demo complete ===');
}

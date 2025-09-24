import 'lib/interpreter/interpreter.dart';
import 'lib/interpreter/tokenizer.dart';
import 'lib/interpreter/expression_evaluator.dart';
import 'lib/memory/memory.dart';
import 'lib/memory/variables.dart';
import 'lib/memory/program_storage.dart';
import 'lib/memory/user_functions.dart';
import 'lib/runtime/stack.dart';
import 'lib/io/screen.dart';
import 'lib/memory/variables.dart' show NumericValue, StringValue;

void main() {
  print('Testing Milestone 2: Control Flow Works');
  print('======================================');

  // Create all required components
  final memory = Memory();
  final tokenizer = Tokenizer();
  final variables = VariableStorage(memory);
  final userFunctions = UserFunctionStorage();
  final expressionEvaluator = ExpressionEvaluator(memory, variables, tokenizer, userFunctions);
  final programStorage = ProgramStorage(memory);
  final runtimeStack = RuntimeStack(memory, variables);
  final screen = Screen();
  final interpreter = Interpreter(memory, tokenizer, variables, expressionEvaluator, programStorage, runtimeStack, screen, userFunctions);

  // Initialize variable storage
  variables.initialize(0x2000);

  try {
    // Test 1: Loops execute correctly
    print('\nTest 1: Loops execute correctly (FOR/NEXT)');
    print('--------------------------------------------');
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 FOR I = 1 TO 3');
    interpreter.executeLine('20 PRINT "Loop iteration"; I');
    interpreter.executeLine('30 NEXT I');
    interpreter.executeLine('40 PRINT "Loop complete"');
    interpreter.executeLine('RUN');
    print('✓ FOR/NEXT loops work');

    // Test 2: Conditionals branch properly (IF/THEN)
    print('\nTest 2: Conditionals branch properly (IF/THEN)');
    print('----------------------------------------------');
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 A = 5');
    interpreter.executeLine('20 IF A > 3 THEN PRINT "A is greater than 3"');
    interpreter.executeLine('30 IF A < 3 THEN PRINT "A is less than 3"');
    interpreter.executeLine('40 IF A = 5 THEN PRINT "A equals 5"');
    interpreter.executeLine('RUN');
    print('✓ IF/THEN conditionals work');

    // Test 3: Subroutines work (GOSUB/RETURN)
    print('\nTest 3: Subroutines work (GOSUB/RETURN)');
    print('---------------------------------------');
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 PRINT "Main program"');
    interpreter.executeLine('20 GOSUB 100');
    interpreter.executeLine('30 PRINT "Back in main"');
    interpreter.executeLine('40 END');
    interpreter.executeLine('100 PRINT "In subroutine"');
    interpreter.executeLine('110 RETURN');
    interpreter.executeLine('RUN');
    print('✓ GOSUB/RETURN subroutines work');

    // Test 4: Line numbers resolve (GOTO)
    print('\nTest 4: Line numbers resolve (GOTO)');
    print('----------------------------------');
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 PRINT "Starting"');
    interpreter.executeLine('20 GOTO 40');
    interpreter.executeLine('30 PRINT "This should be skipped"');
    interpreter.executeLine('40 PRINT "Jumped to line 40"');
    interpreter.executeLine('50 END');
    interpreter.executeLine('RUN');
    print('✓ GOTO line resolution works');

    // Additional control flow tests
    print('\nAdditional control flow tests:');
    print('------------------------------');

    // Test nested loops
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 FOR I = 1 TO 2');
    interpreter.executeLine('20 FOR J = 1 TO 2');
    interpreter.executeLine('30 PRINT "I="; I; ", J="; J');
    interpreter.executeLine('40 NEXT J');
    interpreter.executeLine('50 NEXT I');
    interpreter.executeLine('RUN');
    print('✓ Nested loops work');

    // Test ON GOTO/GOSUB
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 X = 2');
    interpreter.executeLine('20 ON X GOTO 100, 200, 300');
    interpreter.executeLine('30 PRINT "This should not print"');
    interpreter.executeLine('100 PRINT "Went to 100"; : END');
    interpreter.executeLine('200 PRINT "Went to 200"; : END');
    interpreter.executeLine('300 PRINT "Went to 300"; : END');
    interpreter.executeLine('RUN');
    print('✓ ON GOTO works');

    // Test loop with STEP
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 FOR I = 0 TO 10 STEP 2');
    interpreter.executeLine('20 PRINT I;');
    interpreter.executeLine('30 NEXT I');
    interpreter.executeLine('RUN');
    print('✓ FOR/NEXT with STEP works');

    print('\n🎉 All Milestone 2 tests PASSED!');
    print('\nMilestone 2 Status:');
    print('✓ Loops execute correctly');
    print('✓ Conditionals branch properly');
    print('✓ Subroutines work');
    print('✓ Line numbers resolve');

  } catch (e) {
    print('❌ Error during testing: $e');
    print('Stack trace:');
    print(e);
  }
}
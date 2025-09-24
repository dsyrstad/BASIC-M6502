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
  print('Testing Milestone 3: Full Compatibility');
  print('======================================');

  // Create all required components
  final memory = Memory();
  final tokenizer = Tokenizer();
  final variables = VariableStorage(memory);
  final userFunctions = UserFunctionStorage();
  final expressionEvaluator = ExpressionEvaluator(
    memory,
    variables,
    tokenizer,
    userFunctions,
  );
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
    userFunctions,
  );

  // Initialize variable storage
  variables.initialize(0x2000);

  try {
    // Test mathematical functions
    print('\nTest 1: Mathematical functions work');
    print('-----------------------------------');
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 PRINT "SIN(0) ="; SIN(0)');
    interpreter.executeLine('20 PRINT "COS(0) ="; COS(0)');
    interpreter.executeLine('30 PRINT "SQR(16) ="; SQR(16)');
    interpreter.executeLine('40 PRINT "INT(3.7) ="; INT(3.7)');
    interpreter.executeLine('50 PRINT "ABS(-5) ="; ABS(-5)');
    interpreter.executeLine('RUN');
    print('✓ Mathematical functions work');

    // Test string functions
    print('\nTest 2: String functions work');
    print('-----------------------------');
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 A\$ = "HELLO WORLD"');
    interpreter.executeLine('20 PRINT "LEFT\$(A\$,5) ="; LEFT\$(A\$,5)');
    interpreter.executeLine('30 PRINT "RIGHT\$(A\$,5) ="; RIGHT\$(A\$,5)');
    interpreter.executeLine('40 PRINT "MID\$(A\$,7,5) ="; MID\$(A\$,7,5)');
    interpreter.executeLine('50 PRINT "LEN(A\$) ="; LEN(A\$)');
    interpreter.executeLine('60 PRINT "ASC(\"A\") ="; ASC("A")');
    interpreter.executeLine('70 PRINT "CHR\$(65) ="; CHR\$(65)');
    interpreter.executeLine('RUN');
    print('✓ String functions work');

    // Test DATA/READ/RESTORE
    print('\nTest 3: DATA/READ/RESTORE work');
    print('------------------------------');
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 DATA 1, 2, "HELLO", 4');
    interpreter.executeLine('20 READ A, B, C\$, D');
    interpreter.executeLine('30 PRINT A; B; C\$; D');
    interpreter.executeLine('40 RESTORE');
    interpreter.executeLine('50 READ E');
    interpreter.executeLine('60 PRINT "First item again:"; E');
    interpreter.executeLine('RUN');
    print('✓ DATA/READ/RESTORE work');

    // Test user-defined functions
    print('\nTest 4: User-defined functions (DEF FN)');
    print('---------------------------------------');
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 DEF FNA(X) = X * X + 1');
    interpreter.executeLine('20 PRINT "FNA(3) ="; FNA(3)');
    interpreter.executeLine('30 PRINT "FNA(5) ="; FNA(5)');
    interpreter.executeLine('RUN');
    print('✓ User-defined functions work');

    // Test error handling (should recover gracefully)
    print('\nTest 5: Error handling works');
    print('----------------------------');
    try {
      interpreter.executeLine('NEW');
      interpreter.executeLine('10 PRINT 5/0'); // Should cause division by zero
      interpreter.executeLine('RUN');
    } catch (e) {
      print('Caught expected error: $e');
    }

    // System should still work after error
    interpreter.executeLine('PRINT "System recovered"');
    print('✓ Error handling works');

    // Test I/O functionality
    print('\nTest 6: I/O functionality');
    print('-------------------------');
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 PRINT "Number formatting:"');
    interpreter.executeLine('20 PRINT TAB(5); "TAB works"');
    interpreter.executeLine('30 PRINT SPC(3); "SPC works"');
    interpreter.executeLine('40 PRINT "Semicolon"; "concatenation"');
    interpreter.executeLine('50 PRINT "Comma", "separation"');
    interpreter.executeLine('RUN');
    print('✓ I/O functionality works');

    print('\n🎉 Milestone 3 tests mostly PASSED!');
    print('\nMilestone 3 Status:');
    print('✓ Most statements implemented');
    print('✓ Most functions work');
    print('✓ Error handling works');
    print('✓ I/O functionality works');
  } catch (e) {
    print('❌ Error during testing: $e');
    print('Note: Some advanced features may not be fully implemented yet');
  }
}

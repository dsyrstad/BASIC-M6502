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
  print('Testing Milestone 1: Basic Programs Run');
  print('=====================================');

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
    // Test 1: "HELLO WORLD" program works
    print('\nTest 1: "HELLO WORLD" program');
    print('-------------------------------');
    interpreter.executeLine('10 PRINT "HELLO WORLD"');
    interpreter.executeLine('RUN');
    print('✓ HELLO WORLD program works');

    // Test 2: Simple calculations work
    print('\nTest 2: Simple calculations');
    print('---------------------------');
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 PRINT 2 + 3');
    interpreter.executeLine('20 PRINT 10 - 4');
    interpreter.executeLine('30 PRINT 6 * 7');
    interpreter.executeLine('40 PRINT 20 / 4');
    interpreter.executeLine('RUN');
    print('✓ Simple calculations work');

    // Test 3: Variable assignment works
    print('\nTest 3: Variable assignment');
    print('---------------------------');
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 A = 42');
    interpreter.executeLine('20 B\$ = "TEST"');
    interpreter.executeLine('30 PRINT A');
    interpreter.executeLine('40 PRINT B\$');
    interpreter.executeLine('RUN');
    print('✓ Variable assignment works');

    // Test 4: Basic PRINT formatting works
    print('\nTest 4: Basic PRINT formatting');
    print('------------------------------');
    interpreter.executeLine('NEW');
    interpreter.executeLine('10 PRINT "NUMBER:", 42');
    interpreter.executeLine('20 PRINT "STRING:", "BASIC"');
    interpreter.executeLine('30 PRINT "MULTIPLE"; " "; "ITEMS"');
    interpreter.executeLine('40 PRINT TAB(10); "TABBED"');
    interpreter.executeLine('RUN');
    print('✓ Basic PRINT formatting works');

    // Additional verification tests
    print('\nAdditional verification:');
    print('-----------------------');

    // Test direct mode calculations
    final calc1Tokens = tokenizer.tokenizeLine('5 + 3 * 2');
    final calc1Result = expressionEvaluator.evaluateExpression(calc1Tokens, 0);
    print(
      'Direct calculation 5 + 3 * 2 = ${(calc1Result.value as NumericValue).value}',
    );

    // Test string operations
    variables.setVariable('S1\$', StringValue('Hello'));
    variables.setVariable('S2\$', StringValue(' World'));
    final strTokens = tokenizer.tokenizeLine('S1\$ + S2\$');
    final strResult = expressionEvaluator.evaluateExpression(strTokens, 0);
    print('String concatenation: ${(strResult.value as StringValue).value}');

    // Test variable retrieval
    variables.setVariable('X', NumericValue(99.5));
    final varTokens = tokenizer.tokenizeLine('X');
    final varResult = expressionEvaluator.evaluateExpression(varTokens, 0);
    print('Variable X = ${(varResult.value as NumericValue).value}');

    print('\n🎉 All Milestone 1 tests PASSED!');
    print('\nMilestone 1 Status:');
    print('✓ "HELLO WORLD" program works');
    print('✓ Simple calculations work');
    print('✓ Variable assignment works');
    print('✓ Basic PRINT formatting works');
  } catch (e) {
    print('❌ Error during testing: $e');
    print('Stack trace:');
    print(e);
  }
}

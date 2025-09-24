import 'lib/interpreter/interpreter.dart';
import 'lib/interpreter/tokenizer.dart';
import 'lib/interpreter/expression_evaluator.dart';
import 'lib/memory/memory.dart';
import 'lib/memory/variables.dart';
import 'lib/memory/program_storage.dart';
import 'lib/memory/user_functions.dart';
import 'lib/runtime/stack.dart';
import 'lib/io/screen.dart';

void main() {
  print('Testing DEF FN functionality...');

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
    // Test 1: Define a simple function
    print('Test 1: Define function FNA(X) = X * 2');
    final defTokens = tokenizer.tokenizeLine('DEF FNA(X) = X * 2');
    print('DEF tokens: ${defTokens.map((t) => tokenizer.getTokenName(t) ?? t.toString()).join(' ')}');

    interpreter.processDirectModeInput('DEF FNA(X) = X * 2');

    print('Function defined successfully');
    print('Defined functions: ${userFunctions.getDefinedFunctions()}');

    // Test 2: Call the function
    print('\nTest 2: Call FNA(5)');
    final result = interpreter.evaluateExpressionFromString('FNA(5)');
    print('Result: $result');

    // Test 3: Define a string function
    print('\nTest 3: Define string function FNS$(A$) = A$ + " world"');
    interpreter.processDirectModeInput('DEF FNS\$(A\$) = A\$ + " world"');
    print('String function defined successfully');

    // Test 4: Call the string function
    print('\nTest 4: Call FNS$("hello")');
    variables.setVariable('B\$', StringValue('hello'));
    final stringResult = interpreter.evaluateExpressionFromString('FNS\$(B\$)');
    print('Result: $stringResult');

    print('\nAll DEF FN tests completed successfully!');

  } catch (e) {
    print('Error during test: $e');
  }
}
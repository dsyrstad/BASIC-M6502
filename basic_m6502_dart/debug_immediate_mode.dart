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

  print('Testing immediate mode functionality...\n');

  // Test 1: Immediate variable assignment
  print('Test 1: Immediate variable assignment');
  try {
    interpreter.executeLine('A = 42');
    final varA = variables.getVariable('A');
    print('A = ${(varA as NumericValue).value}'); // Should print 42.0
  } catch (e) {
    print('Error: $e');
  }

  // Test 2: Immediate PRINT statement
  print('\nTest 2: Immediate PRINT statement');
  try {
    interpreter.executeLine('PRINT "HELLO FROM IMMEDIATE MODE"');
  } catch (e) {
    print('Error: $e');
  }

  // Test 3: Immediate expression evaluation
  print('\nTest 3: Immediate expression evaluation');
  try {
    interpreter.executeLine('PRINT A + 8'); // Should print 50
  } catch (e) {
    print('Error: $e');
  }

  // Test 4: Store a program line (should not execute immediately)
  print('\nTest 4: Store program line');
  try {
    interpreter.executeLine('10 PRINT "THIS IS A PROGRAM LINE"');
    print('Program lines: ${programStorage.getAllLineNumbers()}');
  } catch (e) {
    print('Error: $e');
  }

  // Test 5: Run the stored program
  print('\nTest 5: Run stored program');
  try {
    interpreter.executeLine('RUN');
  } catch (e) {
    print('Error: $e');
  }

  // Test 6: Back to immediate mode after program
  print('\nTest 6: Back to immediate mode');
  try {
    interpreter.executeLine('PRINT "BACK IN IMMEDIATE MODE"');
  } catch (e) {
    print('Error: $e');
  }

  // Test 7: LIST command in immediate mode
  print('\nTest 7: LIST command');
  try {
    interpreter.executeLine('LIST');
  } catch (e) {
    print('Error: $e');
  }
}

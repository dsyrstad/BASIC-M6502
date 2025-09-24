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
  final expressionEvaluator = ExpressionEvaluator(memory, variables, tokenizer);
  final programStorage = ProgramStorage(memory);
  final runtimeStack = RuntimeStack(memory, variables);
  final interpreter = Interpreter(memory, tokenizer, variables, expressionEvaluator, programStorage, runtimeStack);

  // Initialize variable storage
  variables.initialize(0x2000);

  print('Testing direct mode execution...\n');

  // Test direct mode commands
  print('=== Test 1: Direct variable assignment ===');
  try {
    interpreter.executeLine('A = 42');
    print('A = ${variables.getVariable("A")}');
  } catch (e) {
    print('Error: $e');
  }

  print('\n=== Test 2: Direct PRINT ===');
  try {
    interpreter.executeLine('PRINT "HELLO"');
  } catch (e) {
    print('Error: $e');
  }

  print('\n=== Test 3: Direct PRINT variable ===');
  try {
    interpreter.executeLine('PRINT A');
  } catch (e) {
    print('Error: $e');
  }

  print('\n=== Test 4: Direct FOR loop ===');
  try {
    interpreter.executeLine('FOR I = 1 TO 3');
    print('Stack depth after FOR: ${runtimeStack.depth}');
    print('I = ${variables.getVariable("I")}');

    interpreter.executeLine('NEXT I');
    print('Stack depth after first NEXT: ${runtimeStack.depth}');
    print('I = ${variables.getVariable("I")}');
  } catch (e) {
    print('Error: $e');
  }
}
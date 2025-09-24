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

  print('Testing line editing functionality...\n');

  // Test 1: Add some program lines
  print('Test 1: Adding program lines');
  try {
    interpreter.executeLine('10 PRINT "LINE 10"');
    interpreter.executeLine('20 PRINT "LINE 20"');
    interpreter.executeLine('30 PRINT "LINE 30"');

    print('Added lines 10, 20, 30');
    interpreter.executeLine('LIST');
  } catch (e) {
    print('Error: $e');
  }

  // Test 2: Replace a line
  print('\nTest 2: Replace line 20');
  try {
    interpreter.executeLine('20 PRINT "REPLACED LINE 20"');
    interpreter.executeLine('LIST');
  } catch (e) {
    print('Error: $e');
  }

  // Test 3: Delete a line by line number only
  print('\nTest 3: Delete line 20');
  try {
    interpreter.executeLine('20');
    interpreter.executeLine('LIST');
  } catch (e) {
    print('Error: $e');
  }

  // Test 4: Insert a line in the middle
  print('\nTest 4: Insert line 15');
  try {
    interpreter.executeLine('15 PRINT "INSERTED LINE 15"');
    interpreter.executeLine('LIST');
  } catch (e) {
    print('Error: $e');
  }

  // Test 5: Try to delete a non-existent line
  print('\nTest 5: Delete non-existent line 25');
  try {
    interpreter.executeLine('25');
    interpreter.executeLine('LIST');
  } catch (e) {
    print('Error: $e');
  }

  // Test 6: Run the program to verify it still works
  print('\nTest 6: Run the program');
  try {
    interpreter.executeLine('RUN');
  } catch (e) {
    print('Error: $e');
  }
}
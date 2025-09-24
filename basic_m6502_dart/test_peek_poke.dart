import 'lib/memory/memory.dart';
import 'lib/memory/variables.dart';
import 'lib/memory/program_storage.dart';
import 'lib/runtime/stack.dart';
import 'lib/io/screen.dart';
import 'lib/interpreter/tokenizer.dart';
import 'lib/interpreter/expression_evaluator.dart';
import 'lib/interpreter/interpreter.dart';

void main() {
  print('Testing PEEK and POKE functionality...');

  // Set up the interpreter components
  final memory = Memory();
  final tokenizer = Tokenizer();
  final variables = VariableStorage(memory);
  final programStorage = ProgramStorage(memory);
  final runtimeStack = RuntimeStack(memory, variables);
  final screen = Screen();
  final expressionEvaluator = ExpressionEvaluator(memory, variables, tokenizer);
  final interpreter = Interpreter(
    memory,
    tokenizer,
    variables,
    expressionEvaluator,
    programStorage,
    runtimeStack,
    screen,
  );

  try {
    // Test 1: Basic POKE and PEEK
    print('\nTest 1: Basic POKE and PEEK');
    interpreter.executeLine('POKE 1000, 42');
    final result1 = interpreter.evaluateExpression('PEEK(1000)');
    print('POKE 1000, 42 then PEEK(1000) = $result1');
    assert(result1 == 42.0, 'Expected 42, got $result1');

    // Test 2: Multiple memory locations
    print('\nTest 2: Multiple memory locations');
    interpreter.executeLine('POKE 2000, 100');
    interpreter.executeLine('POKE 2001, 200');
    final result2a = interpreter.evaluateExpression('PEEK(2000)');
    final result2b = interpreter.evaluateExpression('PEEK(2001)');
    print(
      'POKE 2000,100; POKE 2001,200 then PEEK(2000)=$result2a, PEEK(2001)=$result2b',
    );
    assert(result2a == 100.0, 'Expected 100, got $result2a');
    assert(result2b == 200.0, 'Expected 200, got $result2b');

    // Test 3: POKE with expressions
    print('\nTest 3: POKE with expressions');
    interpreter.executeLine('POKE 1500, 10+15');
    final result3 = interpreter.evaluateExpression('PEEK(1500)');
    print('POKE 1500, 10+15 then PEEK(1500) = $result3');
    assert(result3 == 25.0, 'Expected 25, got $result3');

    // Test 4: PEEK with expression address
    print('\nTest 4: PEEK with expression address');
    interpreter.executeLine('POKE 3000, 99');
    final result4 = interpreter.evaluateExpression('PEEK(3000+0)');
    print('POKE 3000,99 then PEEK(3000+0) = $result4');
    assert(result4 == 99.0, 'Expected 99, got $result4');

    // Test 5: Variable-based PEEK/POKE
    print('\nTest 5: Variable-based PEEK/POKE');
    interpreter.executeLine('A = 4000');
    interpreter.executeLine('B = 123');
    interpreter.executeLine('POKE A, B');
    final result5 = interpreter.evaluateExpression('PEEK(A)');
    print('A=4000; B=123; POKE A,B then PEEK(A) = $result5');
    assert(result5 == 123.0, 'Expected 123, got $result5');

    // Test 6: Boundary testing (0 and 65535)
    print('\nTest 6: Boundary testing');
    interpreter.executeLine('POKE 0, 255');
    interpreter.executeLine('POKE 65535, 1');
    final result6a = interpreter.evaluateExpression('PEEK(0)');
    final result6b = interpreter.evaluateExpression('PEEK(65535)');
    print(
      'POKE 0,255; POKE 65535,1 then PEEK(0)=$result6a, PEEK(65535)=$result6b',
    );
    assert(result6a == 255.0, 'Expected 255, got $result6a');
    assert(result6b == 1.0, 'Expected 1, got $result6b');

    print('\n✅ All PEEK/POKE tests passed!');

    // Test error conditions
    print('\nTesting error conditions...');

    // Test 7: POKE address out of range
    print('\nTest 7: POKE address out of range');
    try {
      interpreter.executeLine('POKE -1, 0');
      print('❌ Should have thrown error for negative address');
    } catch (e) {
      print('✅ Correctly caught error for negative address: $e');
    }

    try {
      interpreter.executeLine('POKE 65536, 0');
      print('❌ Should have thrown error for address too large');
    } catch (e) {
      print('✅ Correctly caught error for address too large: $e');
    }

    // Test 8: POKE value out of range
    print('\nTest 8: POKE value out of range');
    try {
      interpreter.executeLine('POKE 1000, -1');
      print('❌ Should have thrown error for negative value');
    } catch (e) {
      print('✅ Correctly caught error for negative value: $e');
    }

    try {
      interpreter.executeLine('POKE 1000, 256');
      print('❌ Should have thrown error for value too large');
    } catch (e) {
      print('✅ Correctly caught error for value too large: $e');
    }

    // Test 9: PEEK address out of range
    print('\nTest 9: PEEK address out of range');
    try {
      interpreter.evaluateExpression('PEEK(-1)');
      print('❌ Should have thrown error for negative PEEK address');
    } catch (e) {
      print('✅ Correctly caught error for negative PEEK address: $e');
    }

    try {
      interpreter.evaluateExpression('PEEK(65536)');
      print('❌ Should have thrown error for PEEK address too large');
    } catch (e) {
      print('✅ Correctly caught error for PEEK address too large: $e');
    }

    print('\n🎉 All tests completed successfully!');
  } catch (e) {
    print('❌ Test failed with error: $e');
  }
}

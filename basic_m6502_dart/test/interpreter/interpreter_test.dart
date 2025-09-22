import 'package:test/test.dart';
import '../../lib/interpreter/interpreter.dart';
import '../../lib/interpreter/tokenizer.dart';
import '../../lib/memory/memory.dart';

void main() {
  group('Interpreter', () {
    late Memory memory;
    late Tokenizer tokenizer;
    late Interpreter interpreter;

    setUp(() {
      memory = Memory();
      tokenizer = Tokenizer();
      interpreter = Interpreter(memory, tokenizer);
    });

    test('should initialize in direct mode', () {
      expect(interpreter.isInDirectMode, isTrue);
      expect(interpreter.isInProgramMode, isFalse);
    });

    test('should execute END statement', () {
      interpreter.executeLine('END');
      expect(interpreter.isRunning, isFalse);
    });

    test('should execute REM statement', () {
      // REM should not cause errors and should be ignored
      expect(() => interpreter.executeLine('REM THIS IS A COMMENT'),
             returnsNormally);
    });

    test('should handle empty line', () {
      expect(() => interpreter.executeLine(''), returnsNormally);
    });

    test('should handle line with only spaces', () {
      expect(() => interpreter.executeLine('   '), returnsNormally);
    });

    test('should detect program line entry', () {
      // Lines starting with numbers should be stored as program lines
      expect(() => interpreter.executeLine('10 PRINT "HELLO"'),
             returnsNormally);
    });

    test('should handle line deletion', () {
      // Line number without content should delete the line
      expect(() => interpreter.executeLine('10'), returnsNormally);
    });

    test('should handle invalid statement', () {
      expect(() => interpreter.executeLine('INVALID'),
             throwsA(isA<InterpreterException>()));
    });

    test('should reset to initial state', () {
      interpreter.executeLine('END');
      expect(interpreter.isRunning, isFalse);

      interpreter.reset();
      expect(interpreter.isInDirectMode, isTrue);
      expect(interpreter.isRunning, isTrue);
    });

    test('should execute basic PRINT statement', () {
      // Basic PRINT should work (output goes to stdout in this implementation)
      expect(() => interpreter.executeLine('PRINT "HELLO"'),
             returnsNormally);
    });

    test('should handle multiple statements on one line', () {
      // Statements separated by colons
      expect(() => interpreter.executeLine('PRINT "A": PRINT "B"'),
             returnsNormally);
    });
  });
}
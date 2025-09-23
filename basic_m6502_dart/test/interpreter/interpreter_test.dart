import 'package:test/test.dart';
import '../../lib/interpreter/interpreter.dart';
import '../../lib/interpreter/tokenizer.dart';
import '../../lib/interpreter/expression_evaluator.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';
import '../../lib/memory/program_storage.dart';
import '../../lib/runtime/stack.dart';
import '../../lib/io/screen.dart';

void main() {
  group('Interpreter', () {
    late Memory memory;
    late Tokenizer tokenizer;
    late VariableStorage variables;
    late ExpressionEvaluator expressionEvaluator;
    late ProgramStorage programStorage;
    late RuntimeStack runtimeStack;
    late Screen screen;
    late Interpreter interpreter;

    setUp(() {
      memory = Memory();
      tokenizer = Tokenizer();
      variables = VariableStorage(memory);
      expressionEvaluator = ExpressionEvaluator(memory, variables, tokenizer);
      programStorage = ProgramStorage(memory);
      runtimeStack = RuntimeStack(memory, variables);
      screen = Screen();
      interpreter = Interpreter(memory, tokenizer, variables, expressionEvaluator, programStorage, runtimeStack, screen);

      // Initialize variable storage
      variables.initialize(0x2000);
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
      // Use a truly invalid syntax - an unknown symbol
      expect(() => interpreter.executeLine('@#\$%'),
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

    group('LET statement', () {
      test('should assign numeric value with LET', () {
        interpreter.executeLine('LET A = 42');
        final value = variables.getVariable('A');
        expect(value, isA<NumericValue>());
        expect((value as NumericValue).value, equals(42.0));
      });

      test('should assign string value with LET', () {
        interpreter.executeLine('LET A\$ = "HELLO"');
        final value = variables.getVariable('A\$');
        expect(value, isA<StringValue>());
        expect((value as StringValue).value, equals('HELLO'));
      });

      test('should assign expression with LET', () {
        interpreter.executeLine('LET B = 3 + 4 * 5');
        final value = variables.getVariable('B');
        expect(value, isA<NumericValue>());
        expect((value as NumericValue).value, equals(23.0));
      });

      test('should support implicit LET (assignment without LET)', () {
        interpreter.executeLine('C = 100');
        final value = variables.getVariable('C');
        expect(value, isA<NumericValue>());
        expect((value as NumericValue).value, equals(100.0));
      });

      test('should support implicit string assignment', () {
        interpreter.executeLine('D\$ = "WORLD"');
        final value = variables.getVariable('D\$');
        expect(value, isA<StringValue>());
        expect((value as StringValue).value, equals('WORLD'));
      });

      test('should handle variable references in assignment', () {
        interpreter.executeLine('E = 10');
        interpreter.executeLine('F = E + 5');
        final value = variables.getVariable('F');
        expect(value, isA<NumericValue>());
        expect((value as NumericValue).value, equals(15.0));
      });

      test('should error on missing equals sign in LET', () {
        expect(() => interpreter.executeLine('LET G 42'),
               throwsA(isA<InterpreterException>()));
      });

      test('should error on invalid variable name', () {
        expect(() => interpreter.executeLine('LET 123 = 42'),
               throwsA(isA<InterpreterException>()));
      });

      test('should handle different variable types', () {
        // H and H$ are different variables in BASIC
        interpreter.executeLine('H = 42');
        interpreter.executeLine('H\$ = "TEST"');

        final numValue = variables.getVariable('H');
        final strValue = variables.getVariable('H\$');

        expect(numValue, isA<NumericValue>());
        expect((numValue as NumericValue).value, equals(42.0));
        expect(strValue, isA<StringValue>());
        expect((strValue as StringValue).value, equals('TEST'));
      });
    });
  });
}
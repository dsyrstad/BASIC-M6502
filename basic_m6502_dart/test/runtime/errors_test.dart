import 'package:test/test.dart';
import '../../lib/runtime/errors.dart';
import '../../lib/interpreter/interpreter.dart';
import '../../lib/interpreter/tokenizer.dart';
import '../../lib/interpreter/expression_evaluator.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';
import '../../lib/memory/program_storage.dart';
import '../../lib/memory/user_functions.dart';
import '../../lib/memory/arrays.dart';
import '../../lib/runtime/stack.dart';
import '../../lib/io/screen.dart';
import '../../lib/io/file_io.dart';
import '../../lib/memory/values.dart';

// Mock screen for testing
class MockScreen extends Screen {
  final StringBuffer _buffer = StringBuffer();

  String get output => _buffer.toString();

  void clearOutput() {
    _buffer.clear();
  }

  @override
  void printWithoutNewline(String text) {
    _buffer.write(text);
  }

  @override
  void printLine(String text) {
    _buffer.write(text);
    _buffer.write('\n');
  }
}

void main() {
  group('Error Handling', () {
    late Memory memory;
    late Tokenizer tokenizer;
    late VariableStorage variables;
    late UserFunctionStorage userFunctions;
    late ArrayManager arrays;
    late ExpressionEvaluator expressionEvaluator;
    late ProgramStorage programStorage;
    late RuntimeStack runtimeStack;
    late MockScreen screen;
    late FileIOManager fileIO;
    late Interpreter interpreter;

    setUp(() {
      memory = Memory();
      tokenizer = Tokenizer();
      variables = VariableStorage(memory);
      userFunctions = UserFunctionStorage();
      arrays = ArrayManager(memory);
      expressionEvaluator = ExpressionEvaluator(
        memory,
        variables,
        tokenizer,
        userFunctions,
      );
      programStorage = ProgramStorage(memory);
      runtimeStack = RuntimeStack(memory, variables);
      screen = MockScreen();
      fileIO = FileIOManager();
      interpreter = Interpreter(
        memory,
        tokenizer,
        variables,
        expressionEvaluator,
        programStorage,
        runtimeStack,
        screen,
        userFunctions,
        arrays,
        fileIO,
      );

      variables.initialize(0x2000);
      // Initialize string space top for arrays
      memory.writeWord(Memory.fretop, 0x8000);
    });

    group('BasicError', () {
      test('should create error with correct properties', () {
        final error = BasicError(
          BasicErrorCode.syntaxError,
          context: 'Invalid expression',
          lineNumber: 100,
        );

        expect(error.errorCode, equals(BasicErrorCode.syntaxError));
        expect(error.context, equals('Invalid expression'));
        expect(error.lineNumber, equals(100));
      });

      test('should format error message correctly', () {
        final error = BasicError(
          BasicErrorCode.syntaxError,
          context: 'Invalid expression',
          lineNumber: 100,
        );

        expect(
          error.message,
          equals('?SN ERROR in line 100: Invalid expression'),
        );
      });

      test('should format short error message correctly', () {
        final error = BasicError(BasicErrorCode.syntaxError, lineNumber: 100);

        expect(error.shortMessage, equals('?SN ERROR in 100'));
      });

      test('should handle error without line number', () {
        final error = BasicError(
          BasicErrorCode.typeMismatch,
          context: 'String expected',
        );

        expect(error.message, equals('?TM ERROR: String expected'));
      });

      test('should handle error without context', () {
        final error = BasicError(BasicErrorCode.overflow, lineNumber: 50);

        expect(error.message, equals('?OV ERROR in line 50'));
      });
    });

    group('ErrorHandler', () {
      late ErrorHandler errorHandler;

      setUp(() {
        errorHandler = ErrorHandler();
      });

      test('should start with no error', () {
        expect(errorHandler.hasError, isFalse);
        expect(errorHandler.currentError, isNull);
      });

      test('should set and clear errors', () {
        final error = BasicError(BasicErrorCode.syntaxError);

        errorHandler.setError(error);
        expect(errorHandler.hasError, isTrue);
        expect(errorHandler.currentError, equals(error));

        errorHandler.clearError();
        expect(errorHandler.hasError, isFalse);
        expect(errorHandler.currentError, isNull);
      });

      test('should handle ON ERROR GOTO', () {
        expect(errorHandler.onErrorLine, isNull);

        errorHandler.setOnErrorGoto(1000);
        expect(errorHandler.onErrorLine, equals(1000));

        errorHandler.clearOnError();
        expect(errorHandler.onErrorLine, isNull);
      });

      test('should reset properly', () {
        final error = BasicError(BasicErrorCode.overflow);
        errorHandler.setError(error);
        errorHandler.setOnErrorGoto(500);

        errorHandler.reset();
        expect(errorHandler.hasError, isFalse);
        expect(errorHandler.currentError, isNull);
        expect(errorHandler.onErrorLine, isNull);
      });
    });

    group('Error Creation Helpers', () {
      test('should create syntax error', () {
        final error = ErrorHandler.syntaxError('Bad token', 10);
        expect(error.errorCode, equals(BasicErrorCode.syntaxError));
        expect(error.context, equals('Bad token'));
        expect(error.lineNumber, equals(10));
      });

      test('should create type mismatch error', () {
        final error = ErrorHandler.typeMismatch('String vs numeric');
        expect(error.errorCode, equals(BasicErrorCode.typeMismatch));
        expect(error.context, equals('String vs numeric'));
      });

      test('should create division by zero error', () {
        final error = ErrorHandler.divisionByZero();
        expect(error.errorCode, equals(BasicErrorCode.divisionByZero));
      });
    });

    group('Runtime Error Scenarios', () {
      test('should throw syntax error for invalid statement', () {
        expect(
          () => interpreter.processDirectModeInput('BADCOMMAND'),
          throwsA(isA<BasicError>()),
        );
      });

      test('should throw division by zero error', () {
        expect(
          () => interpreter.evaluateExpressionFromString('5 / 0'),
          throwsA(isA<BasicError>()),
        );
      });

      test('should throw type mismatch for invalid operation', () {
        variables.setVariable('A\$', StringValue('hello'));

        expect(
          () => interpreter.evaluateExpressionFromString('A\$ + 5'),
          throwsA(isA<BasicError>()),
        );
      });

      test('should throw undefined line error for GOTO', () {
        expect(
          () => interpreter.processDirectModeInput('GOTO 9999'),
          throwsA(isA<BasicError>()),
        );
      });

      test('should throw NEXT without FOR error', () {
        expect(
          () => interpreter.processDirectModeInput('NEXT I'),
          throwsA(isA<BasicError>()),
        );
      });

      test('should throw RETURN without GOSUB error', () {
        expect(
          () => interpreter.processDirectModeInput('RETURN'),
          throwsA(isA<BasicError>()),
        );
      });

      test('should throw subscript out of range error', () {
        interpreter.processDirectModeInput('DIM A(5)');

        expect(
          () => interpreter.processDirectModeInput('A(10) = 5'),
          throwsA(isA<BasicError>()),
        );
      });

      test('should throw out of data error', () {
        programStorage.storeLine(10, tokenizer.tokenizeLine('DATA 1, 2'));
        programStorage.storeLine(20, tokenizer.tokenizeLine('READ A, B, C'));

        expect(
          () => {
            interpreter.processDirectModeInput('RESTORE'),
            interpreter.processDirectModeInput('READ A'),
            interpreter.processDirectModeInput('READ B'),
            interpreter.processDirectModeInput('READ C'), // This should throw
          },
          throwsA(isA<BasicError>()),
        );
      });

      test(
        'should throw illegal quantity error for negative array dimension',
        () {
          expect(
            () => interpreter.processDirectModeInput('DIM A(-5)'),
            throwsA(isA<BasicError>()),
          );
        },
      );

      test('should throw redimensioned array error', () {
        interpreter.processDirectModeInput('DIM A(5)');

        expect(
          () => interpreter.processDirectModeInput('DIM A(10)'),
          throwsA(isA<BasicError>()),
        );
      });

      test('should throw undefined function error', () {
        expect(
          () => interpreter.evaluateExpressionFromString('FNX(5)'),
          throwsA(isA<BasicError>()),
        );
      });

      test('should handle string too long error', () {
        // Create a very long string that exceeds limits
        final longString = 'A' * 300; // Assuming 255 char limit
        variables.setVariable('S\$', StringValue('test'));

        expect(
          () => interpreter.evaluateExpressionFromString('S\$ + "$longString"'),
          throwsA(isA<BasicError>()),
        );
      });
    });

    group('Error Messages', () {
      test('should have correct error codes and messages', () {
        expect(BasicErrorCode.syntaxError.code, equals(2));
        expect(BasicErrorCode.syntaxError.shortMessage, equals('SN'));
        expect(BasicErrorCode.syntaxError.longMessage, equals('Syntax error'));

        expect(BasicErrorCode.divisionByZero.code, equals(10));
        expect(BasicErrorCode.divisionByZero.shortMessage, equals('DZ'));
        expect(
          BasicErrorCode.divisionByZero.longMessage,
          equals('Division by zero'),
        );

        expect(BasicErrorCode.typeMismatch.code, equals(12));
        expect(BasicErrorCode.typeMismatch.shortMessage, equals('TM'));
        expect(
          BasicErrorCode.typeMismatch.longMessage,
          equals('Type mismatch'),
        );
      });

      test('should format complete error message', () {
        final error = BasicError(
          BasicErrorCode.nextWithoutFor,
          context: 'Variable I',
          lineNumber: 150,
        );

        expect(error.toString(), equals('?NF ERROR in line 150: Variable I'));
      });
    });

    group('Error Recovery', () {
      test('should clear variables on error in immediate mode', () {
        // This would test error recovery behavior
        // For now, just verify that errors don't crash the system
        try {
          interpreter.processDirectModeInput('5 / 0');
        } catch (e) {
          expect(e, isA<BasicError>());
        }

        // System should still be functional after error
        final result = interpreter.evaluateExpressionFromString('2 + 3');
        expect((result as NumericValue).value, equals(5.0));
      });

      test('should maintain stack integrity after error', () {
        try {
          interpreter.processDirectModeInput('RETURN'); // Should error
        } catch (e) {
          expect(e, isA<BasicError>());
        }

        // Should still be able to use GOSUB/RETURN normally
        interpreter.processDirectModeInput('10 GOSUB 30');
        interpreter.processDirectModeInput('20 END');
        interpreter.processDirectModeInput('30 PRINT "IN SUBROUTINE"');
        interpreter.processDirectModeInput('40 RETURN');

        // Run the program - should work without error
        screen.clearOutput();
        interpreter.executeLine('RUN');
        expect(screen.output, contains('IN SUBROUTINE'));
      });
    });
  });
}

import 'package:test/test.dart';
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

void main() {
  group('Line Editor', () {
    late Memory memory;
    late Tokenizer tokenizer;
    late VariableStorage variables;
    late UserFunctionStorage userFunctions;
    late ArrayManager arrays;
    late ExpressionEvaluator expressionEvaluator;
    late ProgramStorage programStorage;
    late RuntimeStack runtimeStack;
    late Screen screen;
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
      screen = Screen();
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

    test('should add new line to program', () {
      interpreter.processDirectModeInput('10 PRINT "HELLO"');

      final lines = programStorage.getAllLines();
      expect(lines, hasLength(1));
      expect(lines[10], isNotNull);

      final tokens = lines[10]!;
      expect(tokens, isNotEmpty);
      expect(tokens[0], equals(tokenizer.getTokenValue('PRINT')));
    });

    test('should insert line in correct order', () {
      interpreter.processDirectModeInput('30 PRINT "THIRD"');
      interpreter.processDirectModeInput('10 PRINT "FIRST"');
      interpreter.processDirectModeInput('20 PRINT "SECOND"');

      final lines = programStorage.getAllLines();
      final sortedLineNumbers = lines.keys.toList()..sort();

      expect(sortedLineNumbers, equals([10, 20, 30]));
    });

    test('should replace existing line', () {
      interpreter.processDirectModeInput('10 PRINT "OLD"');
      interpreter.processDirectModeInput('10 PRINT "NEW"');

      final lines = programStorage.getAllLines();
      expect(lines, hasLength(1));

      // Should contain NEW, not OLD
      final tokens = lines[10]!;
      final detokenized = tokenizer.detokenize(tokens);
      expect(detokenized, contains('NEW'));
      expect(detokenized, isNot(contains('OLD')));
    });

    test('should delete line when only line number given', () {
      interpreter.processDirectModeInput('10 PRINT "HELLO"');
      interpreter.processDirectModeInput('20 PRINT "WORLD"');

      expect(programStorage.getAllLines(), hasLength(2));

      // Delete line 10
      interpreter.processDirectModeInput('10');

      final lines = programStorage.getAllLines();
      expect(lines, hasLength(1));
      expect(lines.containsKey(10), isFalse);
      expect(lines.containsKey(20), isTrue);
    });

    test('should handle line insertion between existing lines', () {
      interpreter.processDirectModeInput('10 PRINT "FIRST"');
      interpreter.processDirectModeInput('30 PRINT "THIRD"');
      interpreter.processDirectModeInput('20 PRINT "SECOND"');

      final lines = programStorage.getAllLines();
      final sortedLineNumbers = lines.keys.toList()..sort();

      expect(sortedLineNumbers, equals([10, 20, 30]));

      // Verify content order
      final detokenized10 = tokenizer.detokenize(lines[10]!);
      final detokenized20 = tokenizer.detokenize(lines[20]!);
      final detokenized30 = tokenizer.detokenize(lines[30]!);

      expect(detokenized10, contains('FIRST'));
      expect(detokenized20, contains('SECOND'));
      expect(detokenized30, contains('THIRD'));
    });

    test('should handle immediate mode vs program mode', () {
      // Immediate mode (no line number)
      interpreter.processDirectModeInput('PRINT "IMMEDIATE"');

      // Should not add to program
      expect(programStorage.getAllLines(), isEmpty);

      // Program mode (with line number)
      interpreter.processDirectModeInput('10 PRINT "PROGRAM"');

      // Should add to program
      expect(programStorage.getAllLines(), hasLength(1));
    });

    test('should handle complex line with multiple statements', () {
      interpreter.processDirectModeInput(
        '100 FOR I = 1 TO 10: PRINT I: NEXT I',
      );

      final lines = programStorage.getAllLines();
      expect(lines, hasLength(1));

      final tokens = lines[100]!;
      final detokenized = tokenizer.detokenize(tokens);

      expect(detokenized, contains('FOR'));
      expect(detokenized, contains('TO'));
      expect(detokenized, contains('PRINT'));
      expect(detokenized, contains('NEXT'));
    });

    test('should handle line with string literals', () {
      interpreter.processDirectModeInput(
        '10 PRINT "Hello, World!"; " - "; "From BASIC"',
      );

      final lines = programStorage.getAllLines();
      final tokens = lines[10]!;
      final detokenized = tokenizer.detokenize(tokens);

      expect(detokenized, contains('Hello, World!'));
      expect(detokenized, contains('From BASIC'));
    });

    test('should handle line with numeric constants', () {
      interpreter.processDirectModeInput('10 X = 3.14159: Y = -42: Z = 1.5E10');

      final lines = programStorage.getAllLines();
      final tokens = lines[10]!;
      final detokenized = tokenizer.detokenize(tokens);

      expect(detokenized, contains('3.14159'));
      expect(detokenized, contains('-42'));
      expect(detokenized, contains('1.5E10'));
    });

    test('should maintain program integrity during editing', () {
      // Build a simple program
      interpreter.processDirectModeInput('10 FOR I = 1 TO 5');
      interpreter.processDirectModeInput('20 PRINT I');
      interpreter.processDirectModeInput('30 NEXT I');
      interpreter.processDirectModeInput('40 END');

      // Modify middle line
      interpreter.processDirectModeInput('20 PRINT "Value:", I');

      // Verify program structure
      final lines = programStorage.getAllLines();
      expect(lines.keys.toList()..sort(), equals([10, 20, 30, 40]));

      // Verify modified line
      final detokenized20 = tokenizer.detokenize(lines[20]!);
      expect(detokenized20, contains('Value:'));
    });

    test('should handle line number edge cases', () {
      // Maximum line number
      interpreter.processDirectModeInput('65535 PRINT "MAX"');

      // Minimum line number
      interpreter.processDirectModeInput('1 PRINT "MIN"');

      final lines = programStorage.getAllLines();
      expect(lines.containsKey(1), isTrue);
      expect(lines.containsKey(65535), isTrue);
    });

    test('should handle empty line deletion', () {
      interpreter.processDirectModeInput('10 PRINT "HELLO"');
      interpreter.processDirectModeInput('20 REM COMMENT');

      expect(programStorage.getAllLines(), hasLength(2));

      // Delete using empty line
      interpreter.processDirectModeInput('10');

      expect(programStorage.getAllLines(), hasLength(1));
      expect(programStorage.getAllLines().containsKey(10), isFalse);
    });

    test('should preserve line links during editing', () {
      // Create a program with jumps
      interpreter.processDirectModeInput('10 GOTO 30');
      interpreter.processDirectModeInput('20 PRINT "SKIPPED"');
      interpreter.processDirectModeInput('30 PRINT "TARGET"');
      interpreter.processDirectModeInput('40 GOTO 10');

      // Modify a line that isn\'t a jump target
      interpreter.processDirectModeInput('20 PRINT "MODIFIED"');

      // Program should still be valid
      final lines = programStorage.getAllLines();
      expect(lines, hasLength(4));

      final detokenized20 = tokenizer.detokenize(lines[20]!);
      expect(detokenized20, contains('MODIFIED'));
    });

    test('should handle line editing with syntax errors gracefully', () {
      // Valid line first
      interpreter.processDirectModeInput('10 PRINT "HELLO"');

      expect(programStorage.getAllLines(), hasLength(1));

      // Replace with invalid syntax - BASIC stores it without error
      // (error only occurs when trying to RUN the program)
      interpreter.processDirectModeInput('10 BADCOMMAND');

      // The invalid line should replace the original
      expect(programStorage.getAllLines(), hasLength(1));

      // Error should occur when trying to RUN the program
      expect(() => interpreter.executeLine('RUN'), throwsA(isA<Exception>()));
    });

    test('should handle line replacement with different statement types', () {
      interpreter.processDirectModeInput('10 PRINT "ORIGINAL"');

      final originalTokens = programStorage.getAllLines()[10]!;
      expect(originalTokens[0], equals(tokenizer.getTokenValue('PRINT')));

      // Replace with different statement type
      interpreter.processDirectModeInput('10 FOR I = 1 TO 10');

      final newTokens = programStorage.getAllLines()[10]!;
      expect(newTokens[0], equals(tokenizer.getTokenValue('FOR')));
    });

    test('should handle multiple line operations in sequence', () {
      // Batch of operations
      interpreter.processDirectModeInput('100 PRINT "A"');
      interpreter.processDirectModeInput('200 PRINT "B"');
      interpreter.processDirectModeInput('150 PRINT "MIDDLE"');
      interpreter.processDirectModeInput('100'); // Delete
      interpreter.processDirectModeInput('300 PRINT "C"');
      interpreter.processDirectModeInput('200 PRINT "B MODIFIED"');

      final lines = programStorage.getAllLines();
      final sortedNumbers = lines.keys.toList()..sort();

      expect(sortedNumbers, equals([150, 200, 300]));

      expect(tokenizer.detokenize(lines[150]!), contains('MIDDLE'));
      expect(tokenizer.detokenize(lines[200]!), contains('B MODIFIED'));
      expect(tokenizer.detokenize(lines[300]!), contains('C'));
    });
  });
}

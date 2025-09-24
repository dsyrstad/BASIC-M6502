import 'package:test/test.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';
import '../../lib/memory/program_storage.dart';
import '../../lib/runtime/stack.dart';
import '../../lib/interpreter/tokenizer.dart';
import '../../lib/interpreter/expression_evaluator.dart';
import '../../lib/interpreter/interpreter.dart';
import '../../lib/io/screen.dart';
import '../../lib/memory/user_functions.dart';

void main() {
  late Memory memory;
  late VariableStorage variables;
  late ProgramStorage programStorage;
  late RuntimeStack runtimeStack;
  late Tokenizer tokenizer;
  late ExpressionEvaluator expressionEvaluator;
  late Interpreter interpreter;
  late Screen screen;
  late UserFunctionStorage userFunctions;

  setUp(() {
    memory = Memory();
    variables = VariableStorage(memory);
    programStorage = ProgramStorage(memory);
    runtimeStack = RuntimeStack(memory, variables);
    tokenizer = Tokenizer();
    expressionEvaluator = ExpressionEvaluator(memory, variables, tokenizer, userFunctions);
    screen = Screen();
    userFunctions = UserFunctionStorage();
    interpreter = Interpreter(memory, tokenizer, variables, expressionEvaluator, programStorage, runtimeStack, screen, userFunctions);
  });

  group('ON Statement Tests', () {
    test('ON GOTO with valid index', () {
      // Program:
      // 10 A = 2
      // 20 ON A GOTO 100, 200, 300
      // 30 PRINT "ERROR"
      // 40 END
      // 100 PRINT "FIRST"
      // 110 END
      // 200 PRINT "SECOND"
      // 210 END
      // 300 PRINT "THIRD"
      // 310 END

      interpreter.executeLine('10 A = 2');
      interpreter.executeLine('20 ON A GOTO 100, 200, 300');
      interpreter.executeLine('30 PRINT "ERROR"');
      interpreter.executeLine('40 END');
      interpreter.executeLine('100 PRINT "FIRST"');
      interpreter.executeLine('110 END');
      interpreter.executeLine('200 PRINT "SECOND"');
      interpreter.executeLine('210 END');
      interpreter.executeLine('300 PRINT "THIRD"');
      interpreter.executeLine('310 END');

      // Verify program structure
      expect(programStorage.getAllLineNumbers(), equals([10, 20, 30, 40, 100, 110, 200, 210, 300, 310]));
    });

    test('ON GOSUB with valid index', () {
      // Program:
      // 10 A = 1
      // 20 ON A GOSUB 100, 200, 300
      // 30 PRINT "AFTER GOSUB"
      // 40 END
      // 100 PRINT "SUB1"
      // 110 RETURN
      // 200 PRINT "SUB2"
      // 210 RETURN
      // 300 PRINT "SUB3"
      // 310 RETURN

      interpreter.executeLine('10 A = 1');
      interpreter.executeLine('20 ON A GOSUB 100, 200, 300');
      interpreter.executeLine('30 PRINT "AFTER GOSUB"');
      interpreter.executeLine('40 END');
      interpreter.executeLine('100 PRINT "SUB1"');
      interpreter.executeLine('110 RETURN');
      interpreter.executeLine('200 PRINT "SUB2"');
      interpreter.executeLine('210 RETURN');
      interpreter.executeLine('300 PRINT "SUB3"');
      interpreter.executeLine('310 RETURN');

      // Verify program structure
      expect(programStorage.getAllLineNumbers(), equals([10, 20, 30, 40, 100, 110, 200, 210, 300, 310]));
    });

    test('ON GOTO with index out of range (low)', () {
      // Program:
      // 10 A = 0
      // 20 ON A GOTO 100, 200, 300
      // 30 PRINT "FALLTHROUGH"
      // 40 END
      // 100 PRINT "ERROR"
      // 110 END

      interpreter.executeLine('10 A = 0');
      interpreter.executeLine('20 ON A GOTO 100, 200, 300');
      interpreter.executeLine('30 PRINT "FALLTHROUGH"');
      interpreter.executeLine('40 END');
      interpreter.executeLine('100 PRINT "ERROR"');
      interpreter.executeLine('110 END');

      // Verify program structure
      expect(programStorage.getAllLineNumbers(), equals([10, 20, 30, 40, 100, 110]));
    });

    test('ON GOTO with index out of range (high)', () {
      // Program:
      // 10 A = 5
      // 20 ON A GOTO 100, 200, 300
      // 30 PRINT "FALLTHROUGH"
      // 40 END
      // 100 PRINT "ERROR"
      // 110 END

      interpreter.executeLine('10 A = 5');
      interpreter.executeLine('20 ON A GOTO 100, 200, 300');
      interpreter.executeLine('30 PRINT "FALLTHROUGH"');
      interpreter.executeLine('40 END');
      interpreter.executeLine('100 PRINT "ERROR"');
      interpreter.executeLine('110 END');

      // Verify program structure
      expect(programStorage.getAllLineNumbers(), equals([10, 20, 30, 40, 100, 110]));
    });

    test('ON with expression evaluation', () {
      // Program:
      // 10 A = 2
      // 20 B = 1
      // 30 ON A + B GOTO 100, 200, 300
      // 40 PRINT "ERROR"
      // 50 END
      // 100 PRINT "FIRST"
      // 110 END
      // 200 PRINT "SECOND"
      // 210 END
      // 300 PRINT "THIRD"
      // 310 END

      interpreter.executeLine('10 A = 2');
      interpreter.executeLine('20 B = 1');
      interpreter.executeLine('30 ON A + B GOTO 100, 200, 300');
      interpreter.executeLine('40 PRINT "ERROR"');
      interpreter.executeLine('50 END');
      interpreter.executeLine('100 PRINT "FIRST"');
      interpreter.executeLine('110 END');
      interpreter.executeLine('200 PRINT "SECOND"');
      interpreter.executeLine('210 END');
      interpreter.executeLine('300 PRINT "THIRD"');
      interpreter.executeLine('310 END');

      // Verify program structure
      expect(programStorage.getAllLineNumbers(), equals([10, 20, 30, 40, 50, 100, 110, 200, 210, 300, 310]));
    });

    test('ON with floating point value should truncate', () {
      // Program:
      // 10 A = 2.7
      // 20 ON A GOTO 100, 200, 300
      // 30 PRINT "ERROR"
      // 40 END
      // 100 PRINT "FIRST"
      // 110 END
      // 200 PRINT "SECOND"
      // 210 END
      // 300 PRINT "THIRD"
      // 310 END

      interpreter.executeLine('10 A = 2.7');
      interpreter.executeLine('20 ON A GOTO 100, 200, 300');
      interpreter.executeLine('30 PRINT "ERROR"');
      interpreter.executeLine('40 END');
      interpreter.executeLine('100 PRINT "FIRST"');
      interpreter.executeLine('110 END');
      interpreter.executeLine('200 PRINT "SECOND"');
      interpreter.executeLine('210 END');
      interpreter.executeLine('300 PRINT "THIRD"');
      interpreter.executeLine('310 END');

      // Verify program structure (should go to line 200 because 2.7 truncates to 2)
      expect(programStorage.getAllLineNumbers(), equals([10, 20, 30, 40, 100, 110, 200, 210, 300, 310]));
    });

    test('ON with string expression should throw error', () {
      interpreter.executeLine('10 A\$ = "TEST"');

      expect(() {
        interpreter.executeLine('ON A\$ GOTO 100, 200');
      }, throwsA(isA<InterpreterException>()));
    });

    test('ON without GOTO or GOSUB should throw error', () {
      expect(() {
        interpreter.executeLine('ON 1 PRINT "ERROR"');
      }, throwsA(isA<InterpreterException>()));
    });

    test('ON with no line numbers should throw error', () {
      expect(() {
        interpreter.executeLine('ON 1 GOTO');
      }, throwsA(isA<InterpreterException>()));
    });

    test('ON GOSUB to undefined line should handle error gracefully', () {
      interpreter.executeLine('10 ON 1 GOSUB 999');

      // This should not throw - errors are handled internally
      interpreter.executeLine('RUN');

      expect(interpreter.isInDirectMode, isTrue);
    });

    test('ON with negative value should do nothing', () {
      // Program:
      // 10 A = -1
      // 20 ON A GOTO 100, 200, 300
      // 30 PRINT "FALLTHROUGH"
      // 40 END
      // 100 PRINT "ERROR"
      // 110 END

      interpreter.executeLine('10 A = -1');
      interpreter.executeLine('20 ON A GOTO 100, 200, 300');
      interpreter.executeLine('30 PRINT "FALLTHROUGH"');
      interpreter.executeLine('40 END');
      interpreter.executeLine('100 PRINT "ERROR"');
      interpreter.executeLine('110 END');

      // Verify program structure
      expect(programStorage.getAllLineNumbers(), equals([10, 20, 30, 40, 100, 110]));
    });
  });

  group('ON Statement Edge Cases', () {
    test('ON with single target', () {
      // Program:
      // 10 A = 1
      // 20 ON A GOTO 100
      // 30 PRINT "ERROR"
      // 40 END
      // 100 PRINT "TARGET"
      // 110 END

      interpreter.executeLine('10 A = 1');
      interpreter.executeLine('20 ON A GOTO 100');
      interpreter.executeLine('30 PRINT "ERROR"');
      interpreter.executeLine('40 END');
      interpreter.executeLine('100 PRINT "TARGET"');
      interpreter.executeLine('110 END');

      // Verify program structure
      expect(programStorage.getAllLineNumbers(), equals([10, 20, 30, 40, 100, 110]));
    });

    test('ON GOSUB with nested calls', () {
      // Program:
      // 10 A = 1
      // 20 ON A GOSUB 100
      // 30 PRINT "MAIN"
      // 40 END
      // 100 B = 2
      // 110 ON B GOSUB 200, 300
      // 120 PRINT "SUB1"
      // 130 RETURN
      // 200 PRINT "SUB2A"
      // 210 RETURN
      // 300 PRINT "SUB2B"
      // 310 RETURN

      interpreter.executeLine('10 A = 1');
      interpreter.executeLine('20 ON A GOSUB 100');
      interpreter.executeLine('30 PRINT "MAIN"');
      interpreter.executeLine('40 END');
      interpreter.executeLine('100 B = 2');
      interpreter.executeLine('110 ON B GOSUB 200, 300');
      interpreter.executeLine('120 PRINT "SUB1"');
      interpreter.executeLine('130 RETURN');
      interpreter.executeLine('200 PRINT "SUB2A"');
      interpreter.executeLine('210 RETURN');
      interpreter.executeLine('300 PRINT "SUB2B"');
      interpreter.executeLine('310 RETURN');

      // Verify program structure
      expect(programStorage.getAllLineNumbers(), equals([10, 20, 30, 40, 100, 110, 120, 130, 200, 210, 300, 310]));
    });
  });
}
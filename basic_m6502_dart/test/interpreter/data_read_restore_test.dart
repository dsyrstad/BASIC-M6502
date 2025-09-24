import 'dart:io';
import 'package:test/test.dart';
import '../../lib/interpreter/interpreter.dart';
import '../../lib/interpreter/tokenizer.dart';
import '../../lib/interpreter/expression_evaluator.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';
import '../../lib/memory/program_storage.dart';
import '../../lib/runtime/stack.dart';
import '../../lib/io/screen.dart';
import '../../lib/memory/user_functions.dart';

void main() {
  late Memory memory;
  late Tokenizer tokenizer;
  late VariableStorage variables;
  late ExpressionEvaluator expressionEvaluator;
  late ProgramStorage programStorage;
  late RuntimeStack runtimeStack;
  late Screen screen;
  late UserFunctionStorage userFunctions;
  late Interpreter interpreter;

  setUp(() {
    memory = Memory();
    tokenizer = Tokenizer();
    variables = VariableStorage(memory);
    expressionEvaluator = ExpressionEvaluator(
      memory,
      variables,
      tokenizer,
      userFunctions,
    );
    programStorage = ProgramStorage(memory);
    runtimeStack = RuntimeStack(memory, variables);
    screen = Screen();
    userFunctions = UserFunctionStorage();
    interpreter = Interpreter(
      memory,
      tokenizer,
      variables,
      expressionEvaluator,
      programStorage,
      runtimeStack,
      screen,
      userFunctions,
    );

    // Initialize variable storage
    variables.initialize(0x2000);
  });

  group('DATA/READ/RESTORE statements', () {
    test('READ numeric values from DATA', () {
      final code = '''
10 DATA 10, 20, 30
20 READ A, B, C
30 PRINT A; B; C
40 END
''';

      // Parse and store the program
      final lines = code.trim().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final spaceIndex = line.indexOf(' ');
        if (spaceIndex > 0) {
          final lineNumber = int.parse(line.substring(0, spaceIndex));
          final content = line.substring(spaceIndex + 1);
          final tokenized = tokenizer.tokenizeLine(content);
          programStorage.storeLine(lineNumber, tokenized);
        }
      }

      // Run the program from line 10
      interpreter.executeLine('RUN 10');

      // Check variables were set correctly
      final varA = variables.getVariable('A') as NumericValue;
      final varB = variables.getVariable('B') as NumericValue;
      final varC = variables.getVariable('C') as NumericValue;
      expect(varA.value, 10.0);
      expect(varB.value, 20.0);
      expect(varC.value, 30.0);
    });

    test('READ string values from DATA', () {
      final code = '''
10 DATA "HELLO", "WORLD", "TEST"
20 READ A\$, B\$, C\$
30 PRINT A\$; B\$; C\$
40 END
''';

      // Parse and store the program
      final lines = code.trim().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final spaceIndex = line.indexOf(' ');
        if (spaceIndex > 0) {
          final lineNumber = int.parse(line.substring(0, spaceIndex));
          final content = line.substring(spaceIndex + 1);
          final tokenized = tokenizer.tokenizeLine(content);
          programStorage.storeLine(lineNumber, tokenized);
        }
      }

      // Run the program from line 10
      interpreter.executeLine('RUN 10');

      // Check variables were set correctly
      final varA = variables.getVariable('A\$') as StringValue;
      final varB = variables.getVariable('B\$') as StringValue;
      final varC = variables.getVariable('C\$') as StringValue;
      expect(varA.value, 'HELLO');
      expect(varB.value, 'WORLD');
      expect(varC.value, 'TEST');
    });

    test('READ mixed values from multiple DATA statements', () {
      final code = '''
10 DATA 100, "TEXT"
20 DATA 200, "MORE"
30 READ N1, S1\$
40 READ N2, S2\$
50 END
''';

      // Parse and store the program
      final lines = code.trim().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final spaceIndex = line.indexOf(' ');
        if (spaceIndex > 0) {
          final lineNumber = int.parse(line.substring(0, spaceIndex));
          final content = line.substring(spaceIndex + 1);
          final tokenized = tokenizer.tokenizeLine(content);
          programStorage.storeLine(lineNumber, tokenized);
        }
      }

      // Run the program from line 10
      interpreter.executeLine('RUN 10');

      // Check variables were set correctly
      final varN1 = variables.getVariable('N1') as NumericValue;
      final varS1 = variables.getVariable('S1\$') as StringValue;
      final varN2 = variables.getVariable('N2') as NumericValue;
      final varS2 = variables.getVariable('S2\$') as StringValue;
      expect(varN1.value, 100.0);
      expect(varS1.value, 'TEXT');
      expect(varN2.value, 200.0);
      expect(varS2.value, 'MORE');
    });

    test('RESTORE resets data pointer', () {
      final code = '''
10 DATA 1, 2, 3
20 READ A
30 READ B
40 RESTORE
50 READ C
60 READ D
70 END
''';

      // Parse and store the program
      final lines = code.trim().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final spaceIndex = line.indexOf(' ');
        if (spaceIndex > 0) {
          final lineNumber = int.parse(line.substring(0, spaceIndex));
          final content = line.substring(spaceIndex + 1);
          final tokenized = tokenizer.tokenizeLine(content);
          programStorage.storeLine(lineNumber, tokenized);
        }
      }

      // Run the program from line 10
      interpreter.executeLine('RUN 10');

      // Check variables - C should be 1 (first value again), D should be 2
      final varA = variables.getVariable('A') as NumericValue;
      final varB = variables.getVariable('B') as NumericValue;
      final varC = variables.getVariable('C') as NumericValue;
      final varD = variables.getVariable('D') as NumericValue;
      expect(varA.value, 1.0);
      expect(varB.value, 2.0);
      expect(varC.value, 1.0);
      expect(varD.value, 2.0);
    });

    test('RESTORE with line number', () {
      final code = '''
10 DATA 1, 2, 3
20 DATA 4, 5, 6
30 READ A
40 RESTORE 20
50 READ B
60 END
''';

      // Parse and store the program
      final lines = code.trim().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final spaceIndex = line.indexOf(' ');
        if (spaceIndex > 0) {
          final lineNumber = int.parse(line.substring(0, spaceIndex));
          final content = line.substring(spaceIndex + 1);
          final tokenized = tokenizer.tokenizeLine(content);
          programStorage.storeLine(lineNumber, tokenized);
        }
      }

      // Run the program from line 10
      interpreter.executeLine('RUN 10');

      // Check variables - A should be 1, B should be 4 (from line 20)
      final varA = variables.getVariable('A') as NumericValue;
      final varB = variables.getVariable('B') as NumericValue;
      expect(varA.value, 1.0);
      expect(varB.value, 4.0);
    });

    test('OUT OF DATA error', () {
      final code = '''
10 DATA 1, 2
20 READ A, B, C, D
30 END
''';

      // Parse and store the program
      final lines = code.trim().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final spaceIndex = line.indexOf(' ');
        if (spaceIndex > 0) {
          final lineNumber = int.parse(line.substring(0, spaceIndex));
          final content = line.substring(spaceIndex + 1);
          final tokenized = tokenizer.tokenizeLine(content);
          programStorage.storeLine(lineNumber, tokenized);
        }
      }

      // Run the program - should throw OUT OF DATA error
      expect(
        () => interpreter.executeLine('RUN 10'),
        throwsA(
          isA<InterpreterException>().having(
            (e) => e.message,
            'message',
            contains('OUT OF DATA'),
          ),
        ),
      );
    });

    test('DATA with unquoted strings', () {
      final code = '''
10 DATA HELLO, WORLD, 123
20 READ A\$, B\$, C
30 END
''';

      // Parse and store the program
      final lines = code.trim().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final spaceIndex = line.indexOf(' ');
        if (spaceIndex > 0) {
          final lineNumber = int.parse(line.substring(0, spaceIndex));
          final content = line.substring(spaceIndex + 1);
          final tokenized = tokenizer.tokenizeLine(content);
          programStorage.storeLine(lineNumber, tokenized);
        }
      }

      // Run the program from line 10
      interpreter.executeLine('RUN 10');

      // Check variables were set correctly
      final varA = variables.getVariable('A\$') as StringValue;
      final varB = variables.getVariable('B\$') as StringValue;
      final varC = variables.getVariable('C') as NumericValue;
      expect(varA.value, 'HELLO');
      expect(varB.value, 'WORLD');
      expect(varC.value, 123.0);
    });

    test('DATA on multiple lines with colons', () {
      final code = '''
10 DATA 1, 2: DATA 3, 4
20 READ A, B, C, D
30 END
''';

      // Parse and store the program
      final lines = code.trim().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final spaceIndex = line.indexOf(' ');
        if (spaceIndex > 0) {
          final lineNumber = int.parse(line.substring(0, spaceIndex));
          final content = line.substring(spaceIndex + 1);
          final tokenized = tokenizer.tokenizeLine(content);
          programStorage.storeLine(lineNumber, tokenized);
        }
      }

      // Run the program from line 10
      interpreter.executeLine('RUN 10');

      // Check variables were set correctly
      final varA = variables.getVariable('A') as NumericValue;
      final varB = variables.getVariable('B') as NumericValue;
      final varC = variables.getVariable('C') as NumericValue;
      final varD = variables.getVariable('D') as NumericValue;
      expect(varA.value, 1.0);
      expect(varB.value, 2.0);
      expect(varC.value, 3.0);
      expect(varD.value, 4.0);
    });

    test('DATA with empty values', () {
      final code = '''
10 DATA ,, 3
20 READ A, B, C
30 END
''';

      // Parse and store the program
      final lines = code.trim().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final spaceIndex = line.indexOf(' ');
        if (spaceIndex > 0) {
          final lineNumber = int.parse(line.substring(0, spaceIndex));
          final content = line.substring(spaceIndex + 1);
          final tokenized = tokenizer.tokenizeLine(content);
          programStorage.storeLine(lineNumber, tokenized);
        }
      }

      // Run the program from line 10
      interpreter.executeLine('RUN 10');

      // Check variables - empty values should be 0 for numeric vars
      final varA = variables.getVariable('A') as NumericValue;
      final varB = variables.getVariable('B') as NumericValue;
      final varC = variables.getVariable('C') as NumericValue;
      expect(varA.value, 0.0);
      expect(varB.value, 0.0);
      expect(varC.value, 3.0);
    });

    test('READ in a loop with DATA', () {
      final code = '''
10 DATA 5, 10, 15, 20, 25
20 FOR I = 1 TO 5
30 READ X
40 PRINT X
50 NEXT I
60 END
''';

      // Parse and store the program
      final lines = code.trim().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final spaceIndex = line.indexOf(' ');
        if (spaceIndex > 0) {
          final lineNumber = int.parse(line.substring(0, spaceIndex));
          final content = line.substring(spaceIndex + 1);
          final tokenized = tokenizer.tokenizeLine(content);
          programStorage.storeLine(lineNumber, tokenized);
        }
      }

      // Run the program from line 10
      interpreter.executeLine('RUN 10');

      // After loop, X should contain the last value read
      final varX = variables.getVariable('X') as NumericValue;
      expect(varX.value, 25.0);
    });
  });
}

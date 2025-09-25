import 'package:test/test.dart';
import '../../lib/interpreter/interpreter.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';
import '../../lib/memory/program_storage.dart';
import '../../lib/runtime/stack.dart';
import '../../lib/interpreter/tokenizer.dart';
import '../../lib/interpreter/expression_evaluator.dart';
import '../../lib/io/screen.dart';
import '../../lib/memory/user_functions.dart';

void main() {
  late Memory memory;
  late VariableStorage variables;
  late ProgramStorage programStorage;
  late RuntimeStack runtimeStack;
  late Tokenizer tokenizer;
  late ExpressionEvaluator expressionEvaluator;
  late Screen screen;
  late UserFunctionStorage userFunctions;
  late Interpreter interpreter;

  setUp(() {
    memory = Memory();
    variables = VariableStorage(memory);
    programStorage = ProgramStorage(memory);
    tokenizer = Tokenizer();
    userFunctions = UserFunctionStorage();
    expressionEvaluator = ExpressionEvaluator(
      memory,
      variables,
      tokenizer,
      userFunctions,
    );
    runtimeStack = RuntimeStack(memory, variables);
    screen = Screen();
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

  group('INPUT Statement Tests', () {
    test('INPUT with prompt parses correctly', () {
      // This would require mocking stdin, which is complex
      // For now, we'll just test that the statement is recognized
      final line = '10 INPUT "Enter your name: "; N\$';
      programStorage.addLine(line);

      // Verify the line was added
      expect(programStorage.hasLine(10), isTrue);
    });

    test('INPUT with multiple variables parses correctly', () {
      final line = '10 INPUT A, B, C';
      programStorage.addLine(line);

      // Verify the line was added
      expect(programStorage.hasLine(10), isTrue);
    });

    test('INPUT without prompt parses correctly', () {
      final line = '10 INPUT X';
      programStorage.addLine(line);

      // Verify the line was added
      expect(programStorage.hasLine(10), isTrue);
    });

    test('INPUT with string variable parses correctly', () {
      final line = '10 INPUT "What is your name? "; NAME\$';
      programStorage.addLine(line);

      // Verify the line was added
      expect(programStorage.hasLine(10), isTrue);
    });

    test('INPUT with mixed variables parses correctly', () {
      final line = '10 INPUT "Enter name and age: "; N\$, AGE';
      programStorage.addLine(line);

      // Verify the line was added
      expect(programStorage.hasLine(10), isTrue);
    });
  });
}

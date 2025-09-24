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
  final interpreter = Interpreter(
    memory,
    tokenizer,
    variables,
    expressionEvaluator,
    programStorage,
    runtimeStack,
    screen,
  );

  // Initialize variable storage
  variables.initialize(0x2000);

  // Store a simple program with DATA and READ
  final code = '''
10 DATA 100, "TEXT", 200, "MORE"
20 READ N1
30 PRINT "After N1: "; N1
40 READ S1\$
50 PRINT "After S1\$: "; S1\$
60 READ N2
70 PRINT "After N2: "; N2
80 READ S2\$
90 PRINT "After S2\$: "; S2\$
100 END
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

  // Run the program
  print('Running program with individual READs:');
  interpreter.executeLine('RUN 10');
}

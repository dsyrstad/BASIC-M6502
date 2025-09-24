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

  // Store a simple program with GET
  final code = '''
10 PRINT "Press any key: ";
20 GET K\$
30 PRINT "You pressed: "; K\$
40 PRINT "ASCII code: ";
50 GET K
60 PRINT K
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

  // Run the program
  print('Running GET demo program...');
  print('This will wait for single key presses (press Ctrl+C to exit)');
  interpreter.executeLine('RUN 10');
}
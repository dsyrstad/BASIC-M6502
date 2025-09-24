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
20 READ N1, S1\$
30 PRINT "N1 = "; N1; " S1\$ = "; S1\$
40 READ N2, S2\$
50 PRINT "N2 = "; N2; " S2\$ = "; S2\$
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
      print('Line $lineNumber: $content');
      final tokenized = tokenizer.tokenizeLine(content);
      print('Tokenized: ${tokenized.map((b) => '$b').join(' ')}');
      programStorage.storeLine(lineNumber, tokenized);
    }
  }

  // Run the program
  print('\nRunning program...');
  interpreter.executeLine('RUN 10');

  // Check the values
  print('\nChecking variables:');
  final varN1 = variables.getVariable('N1') as NumericValue;
  final varS1 = variables.getVariable('S1\$') as StringValue;
  final varN2 = variables.getVariable('N2') as NumericValue;
  final varS2 = variables.getVariable('S2\$') as StringValue;

  print('N1 = ${varN1.value} (should be 100)');
  print('S1\$ = ${varS1.value} (should be TEXT)');
  print('N2 = ${varN2.value} (should be 200)');
  print('S2\$ = ${varS2.value} (should be MORE)');
}

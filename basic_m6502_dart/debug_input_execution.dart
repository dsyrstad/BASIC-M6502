import 'lib/interpreter/interpreter.dart';
import 'lib/interpreter/tokenizer.dart';
import 'lib/interpreter/expression_evaluator.dart';
import 'lib/memory/memory.dart';
import 'lib/memory/variables.dart';
import 'lib/memory/program_storage.dart';
import 'lib/runtime/stack.dart';

void main() {
  final tokenizer = Tokenizer();

  // Let's examine what tokens are generated
  final line = 'INPUT N\$, AGE';
  final tokens = tokenizer.tokenizeLine(line);

  print('Line: $line');
  print('Tokens: ');
  for (int i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    print(
      '  [$i]: $token (${token < 128 ? String.fromCharCode(token) : 'TOKEN'})',
    );
  }

  // Let's specifically look for the INPUT token
  print('\nLooking for INPUT token (132):');
  for (int i = 0; i < tokens.length; i++) {
    if (tokens[i] == 132) {
      print('Found INPUT token at position $i');
      print('Remaining tokens:');
      for (int j = i + 1; j < tokens.length; j++) {
        final token = tokens[j];
        print(
          '  [$j]: $token (${token < 128 ? String.fromCharCode(token) : 'TOKEN'})',
        );
      }
      break;
    }
  }
}

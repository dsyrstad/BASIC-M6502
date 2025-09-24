import 'lib/interpreter/tokenizer.dart';

void main() {
  final tokenizer = Tokenizer();

  print('=== Tokenization debugging ===\n');

  // Test the exact lines that are failing
  final testLines = [
    'INPUT N\$', // Works
    'INPUT N\$, AGE', // Fails
    '10 INPUT N\$', // Works
    '10 INPUT N\$, AGE', // Fails
  ];

  for (final line in testLines) {
    print('Line: $line');
    final tokens = tokenizer.tokenizeLine(line);
    print('Tokens: $tokens');
    print(
      'Tokens as chars: ${tokens.map((t) => t < 128 ? String.fromCharCode(t) : 'TOKEN($t)').join(' ')}',
    );
    print('');
  }
}

import 'lib/interpreter/tokenizer.dart';

void main() {
  final tokenizer = Tokenizer();

  // Test tokenizing INPUT with prompt
  final line = 'INPUT "Enter name and age: "; N\$, AGE';
  final tokens = tokenizer.tokenizeLine(line);

  print('Original line: $line');
  print(
    'Tokens: ${tokens.map((t) => '$t (${String.fromCharCode(t)})').join(' ')}',
  );

  // Test without prompt
  final line2 = 'INPUT N\$, AGE';
  final tokens2 = tokenizer.tokenizeLine(line2);

  print('\nOriginal line: $line2');
  print(
    'Tokens: ${tokens2.map((t) => '$t (${String.fromCharCode(t)})').join(' ')}',
  );
}

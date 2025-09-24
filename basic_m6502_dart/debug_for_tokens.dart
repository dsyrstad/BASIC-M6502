import 'lib/interpreter/tokenizer.dart';

void main() {
  final tokenizer = Tokenizer();

  print('Testing FOR statement tokenization...\n');

  // Test FOR statement tokenization
  final forStatement = 'FOR I = 1 TO 3';
  final tokens = tokenizer.tokenizeLine(forStatement);

  print('Input: "$forStatement"');
  print('Tokens: $tokens');
  for (int i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    if (token >= 32 && token <= 126) {
      print('  [$i]: $token (${String.fromCharCode(token)})');
    } else if (token == Tokenizer.forToken) {
      print('  [$i]: $token (FOR token)');
    } else if (token == Tokenizer.toToken) {
      print('  [$i]: $token (TO token)');
    } else if (token == Tokenizer.stepToken) {
      print('  [$i]: $token (STEP token)');
    } else if (token == Tokenizer.equalToken) {
      print('  [$i]: $token (EQUAL token)');
    } else {
      print('  [$i]: $token (unknown)');
    }
  }

  print('\nTesting FOR with STEP...');
  final forStepStatement = 'FOR J = 5 TO 15 STEP 3';
  final stepTokens = tokenizer.tokenizeLine(forStepStatement);

  print('Input: "$forStepStatement"');
  print('Tokens: $stepTokens');
  for (int i = 0; i < stepTokens.length; i++) {
    final token = stepTokens[i];
    if (token >= 32 && token <= 126) {
      print('  [$i]: $token (${String.fromCharCodes([token])})');
    } else if (token == Tokenizer.forToken) {
      print('  [$i]: $token (FOR token)');
    } else if (token == Tokenizer.toToken) {
      print('  [$i]: $token (TO token)');
    } else if (token == Tokenizer.stepToken) {
      print('  [$i]: $token (STEP token)');
    } else if (token == Tokenizer.equalToken) {
      print('  [$i]: $token (EQUAL token)');
    } else {
      print('  [$i]: $token (unknown)');
    }
  }
}

import 'package:test/test.dart';
import 'package:basic_m6502_dart/interpreter/tokenizer.dart';

void main() {
  group('Tokenizer', () {
    late Tokenizer tokenizer;

    setUp(() {
      tokenizer = Tokenizer();
    });

    group('Basic tokenization', () {
      test('should tokenize simple PRINT statement', () {
        final tokens = tokenizer.tokenizeLine('PRINT "HELLO"');
        expect(tokens[0], equals(Tokenizer.printToken));
        expect(tokens[1], equals(32)); // Space
        expect(tokens[2], equals(34)); // Quote
        expect(String.fromCharCodes(tokens.sublist(3, 8)), equals('HELLO'));
        expect(tokens[8], equals(34)); // Quote
      });

      test('should handle question mark as PRINT shortcut', () {
        final tokens = tokenizer.tokenizeLine('? "HELLO"');
        expect(tokens[0], equals(Tokenizer.printToken));
      });

      test('should tokenize FOR loop', () {
        final tokens = tokenizer.tokenizeLine('FOR I=1 TO 10');
        expect(tokens[0], equals(Tokenizer.forToken));
        expect(tokens[1], equals(32)); // Space
        expect(tokens[2], equals(73)); // 'I'
        expect(tokens[3], equals(Tokenizer.equalToken));
        expect(tokens[4], equals(49)); // '1'
        expect(tokens[5], equals(32)); // Space
        expect(tokens[6], equals(Tokenizer.toToken));
      });

      test('should tokenize mathematical operators', () {
        final tokens = tokenizer.tokenizeLine('A=B+C-D*E/F^G');
        expect(tokens[0], equals(65)); // 'A'
        expect(tokens[1], equals(Tokenizer.equalToken));
        expect(tokens[2], equals(66)); // 'B'
        expect(tokens[3], equals(Tokenizer.plusToken));
        expect(tokens[4], equals(67)); // 'C'
        expect(tokens[5], equals(Tokenizer.minusToken));
        expect(tokens[6], equals(68)); // 'D'
        expect(tokens[7], equals(Tokenizer.multiplyToken));
        expect(tokens[8], equals(69)); // 'E'
        expect(tokens[9], equals(Tokenizer.divideToken));
        expect(tokens[10], equals(70)); // 'F'
        expect(tokens[11], equals(Tokenizer.powerToken));
        expect(tokens[12], equals(71)); // 'G'
      });

      test('should tokenize comparison operators', () {
        final tokens = tokenizer.tokenizeLine('IF A>B AND C<D OR E=F THEN');
        expect(tokens[0], equals(Tokenizer.ifToken));
        expect(tokens[1], equals(32)); // Space
        expect(tokens[2], equals(65)); // 'A'
        expect(tokens[3], equals(Tokenizer.greaterToken));
        expect(tokens[4], equals(66)); // 'B'
        expect(tokens[5], equals(32)); // Space
        expect(tokens[6], equals(Tokenizer.andToken));
        expect(tokens[7], equals(32)); // Space
        expect(tokens[8], equals(67)); // 'C'
        expect(tokens[9], equals(Tokenizer.lessToken));
        expect(tokens[10], equals(68)); // 'D'
        expect(tokens[11], equals(32)); // Space
        expect(tokens[12], equals(Tokenizer.orToken));
        expect(tokens[13], equals(32)); // Space
        expect(tokens[14], equals(69)); // 'E'
        expect(tokens[15], equals(Tokenizer.equalToken));
        expect(tokens[16], equals(70)); // 'F'
        expect(tokens[17], equals(32)); // Space
        expect(tokens[18], equals(Tokenizer.thenToken));
      });
    });

    group('Special cases', () {
      test('should handle GO TO as single GOTO token', () {
        final tokens = tokenizer.tokenizeLine('GO TO 100');
        expect(tokens[0], equals(Tokenizer.gotoToken));
        expect(tokens[1], equals(32)); // Space
        expect(tokens[2], equals(49)); // '1'
        expect(tokens[3], equals(48)); // '0'
        expect(tokens[4], equals(48)); // '0'
      });

      test('should handle GO without TO separately', () {
        final tokens = tokenizer.tokenizeLine('GO SUB');
        expect(tokens[0], equals(Tokenizer.goToken));
        expect(tokens[1], equals(32)); // Space
        expect(tokens[2], equals(83)); // 'S'
        expect(tokens[3], equals(85)); // 'U'
        expect(tokens[4], equals(66)); // 'B'
      });

      test('should not tokenize inside quotes', () {
        final tokens = tokenizer.tokenizeLine('PRINT "FOR NEXT GOTO"');
        expect(tokens[0], equals(Tokenizer.printToken));
        expect(tokens[1], equals(32)); // Space
        expect(tokens[2], equals(34)); // Quote
        // The words inside quotes should not be tokenized
        expect(
          String.fromCharCodes(tokens.sublist(3, 16)),
          equals('FOR NEXT GOTO'),
        );
        expect(tokens[16], equals(34)); // Quote
      });

      test('should not tokenize after REM', () {
        final tokens = tokenizer.tokenizeLine('REM THIS IS A COMMENT FOR NEXT');
        expect(tokens[0], equals(Tokenizer.remToken));
        // Everything after REM should be literal
        expect(
          String.fromCharCodes(tokens.sublist(1)),
          equals(' THIS IS A COMMENT FOR NEXT'),
        );
      });

      test('should not tokenize DATA items until colon', () {
        final tokens = tokenizer.tokenizeLine('DATA FOR,NEXT,GOTO:PRINT');
        expect(tokens[0], equals(Tokenizer.dataToken));
        // Items after DATA should be literal until and including colon
        final dataSection = String.fromCharCodes(
          tokens.sublist(1, tokens.length - 1),
        );
        expect(dataSection, equals(' FOR,NEXT,GOTO:'));
        expect(tokens.last, equals(Tokenizer.printToken));
      });

      test('should handle case insensitive keywords', () {
        final tokens1 = tokenizer.tokenizeLine('print');
        final tokens2 = tokenizer.tokenizeLine('PRINT');
        final tokens3 = tokenizer.tokenizeLine('PrInT');
        expect(tokens1[0], equals(Tokenizer.printToken));
        expect(tokens2[0], equals(Tokenizer.printToken));
        expect(tokens3[0], equals(Tokenizer.printToken));
      });

      test('should not tokenize partial matches', () {
        final tokens = tokenizer.tokenizeLine('FORREST GOTO100');
        // FORREST should not match FOR
        expect(tokens[0], equals(70)); // 'F'
        expect(tokens[1], equals(79)); // 'O'
        expect(tokens[2], equals(82)); // 'R'
        expect(tokens[3], equals(82)); // 'R'
        expect(tokens[4], equals(69)); // 'E'
        expect(tokens[5], equals(83)); // 'S'
        expect(tokens[6], equals(84)); // 'T'
        expect(tokens[7], equals(32)); // Space
        // But GOTO100 should tokenize GOTO
        expect(tokens[8], equals(Tokenizer.gotoToken));
      });
    });

    group('Functions', () {
      test('should tokenize single-argument functions', () {
        final tokens = tokenizer.tokenizeLine('A=SIN(X)+COS(Y)');
        expect(tokens[0], equals(65)); // 'A'
        expect(tokens[1], equals(Tokenizer.equalToken));
        expect(tokens[2], equals(Tokenizer.sinToken));
        expect(tokens[3], equals(40)); // '('
        expect(tokens[4], equals(88)); // 'X'
        expect(tokens[5], equals(41)); // ')'
        expect(tokens[6], equals(Tokenizer.plusToken));
        expect(tokens[7], equals(Tokenizer.cosToken));
      });

      test('should tokenize string functions with dollar signs', () {
        final tokens = tokenizer.tokenizeLine('A\$=LEFT\$(B\$,5)');
        expect(tokens[0], equals(65)); // 'A'
        expect(tokens[1], equals(36)); // '$'
        expect(tokens[2], equals(Tokenizer.equalToken));
        expect(tokens[3], equals(Tokenizer.leftDollarToken));
        expect(tokens[4], equals(40)); // '('
        expect(tokens[5], equals(66)); // 'B'
        expect(tokens[6], equals(36)); // '$'
        expect(tokens[7], equals(44)); // ','
        expect(tokens[8], equals(53)); // '5'
        expect(tokens[9], equals(41)); // ')'
      });

      test('should tokenize TAB and SPC with parentheses', () {
        final tokens = tokenizer.tokenizeLine('PRINT TAB(10);SPC(5)');
        expect(tokens[0], equals(Tokenizer.printToken));
        expect(tokens[1], equals(32)); // Space
        expect(tokens[2], equals(Tokenizer.tabToken));
        expect(tokens[3], equals(49)); // '1'
        expect(tokens[4], equals(48)); // '0'
        expect(tokens[5], equals(41)); // ')'
        expect(tokens[6], equals(59)); // ';'
        expect(tokens[7], equals(Tokenizer.spcToken));
        expect(tokens[8], equals(53)); // '5'
        expect(tokens[9], equals(41)); // ')'
      });
    });

    group('Detokenization', () {
      test('should detokenize tokens back to text', () {
        final original = 'PRINT "HELLO"';
        final tokens = tokenizer.tokenizeLine(original);
        final detokenized = tokenizer.detokenize(tokens);
        expect(detokenized, equals(original));
      });

      test('should detokenize complex statement', () {
        final original = 'FOR I=1 TO 10:PRINT I:NEXT';
        final tokens = tokenizer.tokenizeLine(original);
        final detokenized = tokenizer.detokenize(tokens);
        expect(detokenized, equals(original));
      });

      test('should detokenize functions correctly', () {
        final original = 'A=SIN(X)+COS(Y)*TAN(Z)';
        final tokens = tokenizer.tokenizeLine(original);
        final detokenized = tokenizer.detokenize(tokens);
        expect(detokenized, equals(original));
      });
    });

    group('Token classification', () {
      test('should identify statement tokens', () {
        expect(tokenizer.isStatement(Tokenizer.printToken), isTrue);
        expect(tokenizer.isStatement(Tokenizer.forToken), isTrue);
        expect(tokenizer.isStatement(Tokenizer.gotoToken), isTrue);
        expect(tokenizer.isStatement(Tokenizer.sinToken), isFalse);
        expect(tokenizer.isStatement(Tokenizer.plusToken), isFalse);
      });

      test('should identify single-argument functions', () {
        expect(tokenizer.isSingleArgFunction(Tokenizer.sinToken), isTrue);
        expect(tokenizer.isSingleArgFunction(Tokenizer.cosToken), isTrue);
        expect(tokenizer.isSingleArgFunction(Tokenizer.absToken), isTrue);
        expect(tokenizer.isSingleArgFunction(Tokenizer.chrDollarToken), isTrue);
        expect(
          tokenizer.isSingleArgFunction(Tokenizer.leftDollarToken),
          isFalse,
        );
        expect(tokenizer.isSingleArgFunction(Tokenizer.printToken), isFalse);
      });

      test('should identify operators', () {
        expect(tokenizer.isOperator(Tokenizer.plusToken), isTrue);
        expect(tokenizer.isOperator(Tokenizer.minusToken), isTrue);
        expect(tokenizer.isOperator(Tokenizer.andToken), isTrue);
        expect(tokenizer.isOperator(Tokenizer.lessToken), isTrue);
        expect(tokenizer.isOperator(Tokenizer.printToken), isFalse);
        expect(tokenizer.isOperator(Tokenizer.sinToken), isFalse);
      });
    });

    group('Token names', () {
      test('should return correct token names', () {
        expect(tokenizer.getTokenName(Tokenizer.printToken), equals('PRINT'));
        expect(tokenizer.getTokenName(Tokenizer.forToken), equals('FOR'));
        expect(tokenizer.getTokenName(Tokenizer.sinToken), equals('SIN'));
        expect(tokenizer.getTokenName(Tokenizer.plusToken), equals('+'));
        expect(tokenizer.getTokenName(255), startsWith('UNKNOWN'));
      });
    });
  });
}

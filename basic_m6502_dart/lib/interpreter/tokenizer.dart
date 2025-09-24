/// Tokenizer for Microsoft BASIC 6502.
///
/// Converts BASIC source code to tokens as per the original
/// CRUNCH routine. Reserved words are tokenized to values
/// 128-255, with the most significant bit set.
class Tokenizer {
  /// Token values for reserved words (128-255)
  static const int tokenBase = 128;

  /// Statement tokens
  static const int endToken = 128;
  static const int forToken = 129;
  static const int nextToken = 130;
  static const int dataToken = 131;
  static const int inputToken = 132;
  static const int dimToken = 133;
  static const int readToken = 134;
  static const int letToken = 135;
  static const int gotoToken = 136;
  static const int runToken = 137;
  static const int ifToken = 138;
  static const int restoreToken = 139;
  static const int gosubToken = 140;
  static const int returnToken = 141;
  static const int remToken = 142;
  static const int stopToken = 143;
  static const int onToken = 144;
  static const int waitToken = 145;
  static const int loadToken = 146;
  static const int saveToken = 147;
  static const int verifyToken = 148;
  static const int defToken = 149;
  static const int pokeToken = 150;
  static const int printToken = 151;
  static const int contToken = 152;
  static const int listToken = 153;
  static const int clrToken = 154;
  static const int cmdToken = 155;
  static const int sysToken = 156;
  static const int openToken = 157;
  static const int closeToken = 158;
  static const int getToken = 159;
  static const int newToken = 160;

  /// Special tokens
  static const int tabToken = 161;
  static const int toToken = 162;
  static const int fnToken = 163;
  static const int spcToken = 164;
  static const int thenToken = 165;
  static const int notToken = 166;
  static const int stepToken = 167;

  /// Operator tokens
  static const int plusToken = 168;
  static const int minusToken = 169;
  static const int multiplyToken = 170;
  static const int divideToken = 171;
  static const int powerToken = 172;
  static const int andToken = 173;
  static const int orToken = 174;
  static const int greaterToken = 175;
  static const int equalToken = 176;
  static const int lessToken = 177;

  /// Function tokens (single argument functions start here)
  static const int sgnToken = 178;
  static const int intToken = 179;
  static const int absToken = 180;
  static const int usrToken = 181;
  static const int freToken = 182;
  static const int posToken = 183;
  static const int sqrToken = 184;
  static const int rndToken = 185;
  static const int logToken = 186;
  static const int expToken = 187;
  static const int cosToken = 188;
  static const int sinToken = 189;
  static const int tanToken = 190;
  static const int atnToken = 191;
  static const int peekToken = 192;
  static const int lenToken = 193;
  static const int strDollarToken = 194; // STR$
  static const int valToken = 195;
  static const int ascToken = 196;
  static const int chrDollarToken = 197; // CHR$

  /// Multi-argument function tokens
  static const int leftDollarToken = 198; // LEFT$
  static const int rightDollarToken = 199; // RIGHT$
  static const int midDollarToken = 200; // MID$

  /// Special "GO" token for "GO TO"
  static const int goToken = 201;

  /// CLEAR command token
  static const int clearToken = 202;

  /// Last function that takes one argument
  static const int lastSingleArgFunction = chrDollarToken;

  /// Reserved word list matching original RESLST order
  static final List<TokenEntry> _reservedWords = [
    TokenEntry('END', endToken),
    TokenEntry('FOR', forToken),
    TokenEntry('NEXT', nextToken),
    TokenEntry('DATA', dataToken),
    TokenEntry('INPUT', inputToken),
    TokenEntry('DIM', dimToken),
    TokenEntry('READ', readToken),
    TokenEntry('LET', letToken),
    TokenEntry('GOTO', gotoToken),
    TokenEntry('RUN', runToken),
    TokenEntry('IF', ifToken),
    TokenEntry('RESTORE', restoreToken),
    TokenEntry('GOSUB', gosubToken),
    TokenEntry('RETURN', returnToken),
    TokenEntry('REM', remToken),
    TokenEntry('STOP', stopToken),
    TokenEntry('ON', onToken),
    TokenEntry('WAIT', waitToken),
    TokenEntry('LOAD', loadToken),
    TokenEntry('SAVE', saveToken),
    TokenEntry('VERIFY', verifyToken),
    TokenEntry('DEF', defToken),
    TokenEntry('POKE', pokeToken),
    TokenEntry('PRINT', printToken),
    TokenEntry('CONT', contToken),
    TokenEntry('LIST', listToken),
    TokenEntry('CLR', clrToken),
    TokenEntry('CMD', cmdToken),
    TokenEntry('SYS', sysToken),
    TokenEntry('OPEN', openToken),
    TokenEntry('CLOSE', closeToken),
    TokenEntry('GET', getToken),
    TokenEntry('NEW', newToken),
    TokenEntry('CLEAR', clearToken),
    TokenEntry('TAB(', tabToken),
    TokenEntry('TO', toToken),
    TokenEntry('FN', fnToken),
    TokenEntry('SPC(', spcToken),
    TokenEntry('THEN', thenToken),
    TokenEntry('NOT', notToken),
    TokenEntry('STEP', stepToken),
    TokenEntry('+', plusToken),
    TokenEntry('-', minusToken),
    TokenEntry('*', multiplyToken),
    TokenEntry('/', divideToken),
    TokenEntry('^', powerToken),
    TokenEntry('AND', andToken),
    TokenEntry('OR', orToken),
    TokenEntry('>', greaterToken),
    TokenEntry('=', equalToken),
    TokenEntry('<', lessToken),
    TokenEntry('SGN', sgnToken),
    TokenEntry('INT', intToken),
    TokenEntry('ABS', absToken),
    TokenEntry('USR', usrToken),
    TokenEntry('FRE', freToken),
    TokenEntry('POS', posToken),
    TokenEntry('SQR', sqrToken),
    TokenEntry('RND', rndToken),
    TokenEntry('LOG', logToken),
    TokenEntry('EXP', expToken),
    TokenEntry('COS', cosToken),
    TokenEntry('SIN', sinToken),
    TokenEntry('TAN', tanToken),
    TokenEntry('ATN', atnToken),
    TokenEntry('PEEK', peekToken),
    TokenEntry('LEN', lenToken),
    TokenEntry('STR\$', strDollarToken),
    TokenEntry('VAL', valToken),
    TokenEntry('ASC', ascToken),
    TokenEntry('CHR\$', chrDollarToken),
    TokenEntry('LEFT\$', leftDollarToken),
    TokenEntry('RIGHT\$', rightDollarToken),
    TokenEntry('MID\$', midDollarToken),
    TokenEntry('GO', goToken), // Special for "GO TO"
  ];

  /// Tokenize a line of BASIC code (CRUNCH equivalent)
  List<int> tokenizeLine(String line) {
    final result = <int>[];
    var pos = 0;
    var insideQuotes = false;
    var afterData = false; // After DATA, don't tokenize until colon
    var afterRem = false; // After REM, don't tokenize rest of line

    while (pos < line.length) {
      final ch = line.codeUnitAt(pos);

      // Handle special cases
      if (ch == 34) {
        // Double quote (ASCII 34)
        insideQuotes = !insideQuotes;
        result.add(ch);
        pos++;
        continue;
      }

      if (insideQuotes || afterRem) {
        // Don't tokenize inside quotes or after REM
        result.add(ch);
        pos++;
        continue;
      }

      if (afterData) {
        // After DATA, don't tokenize until colon
        if (ch == 58) {
          // Colon (ASCII 58) - reset DATA mode but add the colon
          afterData = false;
        }
        result.add(ch);
        pos++;
        continue;
      }

      // Handle question mark as shortcut for PRINT
      if (ch == 63) {
        // ? (ASCII 63)
        result.add(printToken);
        pos++;
        continue;
      }

      // Skip numeric characters and spaces
      if ((ch >= 48 && ch <= 57) || ch == 32) {
        // 0-9 or space
        result.add(ch);
        pos++;
        continue;
      }

      // Try to match a reserved word
      var matched = false;
      for (final entry in _reservedWords) {
        if (_matchesAt(line, pos, entry.word)) {
          result.add(entry.token);
          pos += entry.word.length;
          matched = true;

          // Check for special tokens that affect parsing
          if (entry.token == remToken) {
            afterRem = true;
          } else if (entry.token == dataToken) {
            afterData = true;
          }

          // Special handling for "GO TO" as single token
          if (entry.token == goToken) {
            // Check if followed by space(s) and "TO"
            var tempPos = pos;
            while (tempPos < line.length && line.codeUnitAt(tempPos) == 32) {
              tempPos++;
            }
            if (tempPos + 2 <= line.length &&
                line.substring(tempPos, tempPos + 2).toUpperCase() == 'TO') {
              // Replace GO token with GOTO token
              result[result.length - 1] = gotoToken;
              pos = tempPos + 2;
            }
          }
          break;
        }
      }

      if (!matched) {
        // Not a reserved word, just copy the character
        result.add(ch);
        pos++;
      }
    }

    return result;
  }

  /// Check if a word matches at the given position (case-insensitive)
  bool _matchesAt(String text, int pos, String word) {
    if (pos + word.length > text.length) {
      return false;
    }

    for (int i = 0; i < word.length; i++) {
      final textChar = text.codeUnitAt(pos + i);
      final wordChar = word.codeUnitAt(i);

      // Case-insensitive comparison for letters
      if (wordChar >= 65 && wordChar <= 90) {
        // Word char is uppercase letter
        final textUpper = textChar >= 97 && textChar <= 122
            ? textChar - 32
            : textChar;
        if (textUpper != wordChar) {
          return false;
        }
      } else {
        // Not a letter, must match exactly
        if (textChar != wordChar) {
          return false;
        }
      }
    }

    // Make sure we're not matching a prefix of a longer word
    // (e.g., don't match "TO" in "TOP")
    if (pos + word.length < text.length) {
      final nextChar = text.codeUnitAt(pos + word.length);
      // If the word ends with a letter and next char is also a letter,
      // this is not a complete match
      final lastWordChar = word.codeUnitAt(word.length - 1);
      if (_isLetter(lastWordChar) && _isLetter(nextChar)) {
        return false;
      }
    }

    return true;
  }

  /// Check if character is a letter
  bool _isLetter(int ch) {
    return (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122);
  }

  /// Detokenize a list of tokens back to text (for LIST command)
  String detokenize(List<int> tokens) {
    final buffer = StringBuffer();

    for (final token in tokens) {
      if (token >= tokenBase) {
        // It's a token, find the corresponding text
        final entry = _findTokenEntry(token);
        if (entry != null) {
          buffer.write(entry.word);
        } else {
          // Unknown token, just output as-is
          buffer.writeCharCode(token);
        }
      } else {
        // Regular character
        buffer.writeCharCode(token);
      }
    }

    return buffer.toString();
  }

  /// Find the token entry for a given token value
  TokenEntry? _findTokenEntry(int token) {
    for (final entry in _reservedWords) {
      if (entry.token == token) {
        return entry;
      }
    }
    return null;
  }

  /// Get the name of a token (for debugging)
  String getTokenName(int token) {
    final entry = _findTokenEntry(token);
    return entry?.word ?? 'UNKNOWN(\${token.toRadixString(16)})';
  }

  /// Check if a token is a statement (as opposed to function/operator)
  bool isStatement(int token) {
    return (token >= endToken && token <= newToken) || token == clearToken;
  }

  /// Check if a token is a single-argument function
  bool isSingleArgFunction(int token) {
    return token >= sgnToken && token <= lastSingleArgFunction;
  }

  /// Check if a token is an operator
  bool isOperator(int token) {
    return token >= plusToken && token <= lessToken;
  }
}

/// Entry in the reserved word table
class TokenEntry {
  final String word;
  final int token;

  const TokenEntry(this.word, this.token);
}

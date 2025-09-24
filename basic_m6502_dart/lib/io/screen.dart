import 'dart:io';
import 'package:meta/meta.dart';

/// Screen emulation for 40-column BASIC output formatting.
///
/// Handles cursor positioning, tab zones, and screen formatting
/// to match original Commodore BASIC behavior.
class Screen {
  /// Screen width in characters (Commodore 40-column mode)
  static const int screenWidth = 40;

  /// Screen height in rows (typically 25 for Commodore)
  static const int screenHeight = 25;

  /// Tab zone width (typically 10 characters for BASIC)
  static const int tabZoneWidth = 10;

  /// Current cursor column (0-39)
  @protected
  int _cursorColumn = 0;

  /// Current cursor row
  @protected
  int _cursorRow = 0;

  /// Screen buffer for scrolling support (optional)
  final List<String> _screenBuffer = List.filled(screenHeight, '');

  /// Get current cursor column position
  int get cursorColumn => _cursorColumn;

  /// Get current cursor row position
  int get cursorRow => _cursorRow;

  /// Print text without newline, tracking cursor position
  void printWithoutNewline(String text) {
    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (char == '\n') {
        _newline();
      } else if (char == '\r') {
        _cursorColumn = 0;
      } else {
        // Print character and advance cursor
        stdout.write(char);
        _cursorColumn++;

        // Wrap at screen width
        if (_cursorColumn >= screenWidth) {
          _newline();
        }
      }
    }
  }

  /// Print text with newline
  void printLine(String text) {
    printWithoutNewline(text);
    _newline();
  }

  /// Move cursor to next line
  void _newline() {
    stdout.writeln();
    _cursorColumn = 0;
    _cursorRow++;
    _handleScrolling();
  }

  /// Tab to next tab zone (for comma separator in PRINT)
  void tabToNextZone() {
    // Calculate next tab position
    final nextTab = ((_cursorColumn ~/ tabZoneWidth) + 1) * tabZoneWidth;

    if (nextTab >= screenWidth) {
      // If next tab exceeds screen width, go to new line
      _newline();
    } else {
      // Print spaces to reach next tab position
      final spacesToPrint = nextTab - _cursorColumn;
      for (int i = 0; i < spacesToPrint; i++) {
        stdout.write(' ');
      }
      _cursorColumn = nextTab;
    }
  }

  /// Move cursor to specific column (TAB function)
  void tabToColumn(int column) {
    // Ensure column is within screen bounds
    column = column.clamp(0, screenWidth - 1);

    if (column <= _cursorColumn) {
      // If target is before current position, go to new line first
      _newline();
    }

    // Print spaces to reach target column
    final spacesToPrint = column - _cursorColumn;
    for (int i = 0; i < spacesToPrint; i++) {
      stdout.write(' ');
    }
    _cursorColumn = column;
  }

  /// Print specified number of spaces (SPC function)
  void printSpaces(int count) {
    for (int i = 0; i < count; i++) {
      stdout.write(' ');
      _cursorColumn++;

      // Wrap at screen width
      if (_cursorColumn >= screenWidth) {
        _newline();
      }
    }
  }

  /// Reset cursor to beginning of current line
  void carriageReturn() {
    stdout.write('\r');
    _cursorColumn = 0;
  }

  /// Clear screen and reset cursor (if needed)
  void clearScreen() {
    // ANSI escape sequence to clear screen
    stdout.write('\x1B[2J\x1B[H');
    _cursorColumn = 0;
    _cursorRow = 0;
    // Clear screen buffer
    for (int i = 0; i < _screenBuffer.length; i++) {
      _screenBuffer[i] = '';
    }
  }

  /// Move cursor to specific position
  void setCursorPosition(int row, int column) {
    row = row.clamp(0, screenHeight - 1);
    column = column.clamp(0, screenWidth - 1);

    // ANSI escape sequence to move cursor (1-indexed)
    stdout.write('\x1B[${row + 1};${column + 1}H');
    _cursorRow = row;
    _cursorColumn = column;
  }

  /// Handle screen scrolling when at bottom
  void _handleScrolling() {
    if (_cursorRow >= screenHeight) {
      // Scroll screen up by one line
      for (int i = 0; i < screenHeight - 1; i++) {
        _screenBuffer[i] = _screenBuffer[i + 1];
      }
      _screenBuffer[screenHeight - 1] = '';
      _cursorRow = screenHeight - 1;

      // ANSI escape sequence to scroll
      stdout.write('\x1B[S');
    }
  }

  /// Move cursor up one line
  void cursorUp() {
    if (_cursorRow > 0) {
      _cursorRow--;
      stdout.write('\x1B[A');
    }
  }

  /// Move cursor down one line
  void cursorDown() {
    if (_cursorRow < screenHeight - 1) {
      _cursorRow++;
      stdout.write('\x1B[B');
    }
  }

  /// Move cursor left one position
  void cursorLeft() {
    if (_cursorColumn > 0) {
      _cursorColumn--;
      stdout.write('\x1B[D');
    }
  }

  /// Move cursor right one position
  void cursorRight() {
    if (_cursorColumn < screenWidth - 1) {
      _cursorColumn++;
      stdout.write('\x1B[C');
    }
  }

  /// Home cursor (move to top-left)
  void homeCursor() {
    setCursorPosition(0, 0);
  }

  /// Clear from cursor to end of line
  void clearToEndOfLine() {
    stdout.write('\x1B[K');
  }

  /// Clear from cursor to end of screen
  void clearToEndOfScreen() {
    stdout.write('\x1B[J');
  }
}
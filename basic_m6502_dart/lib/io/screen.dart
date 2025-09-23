import 'dart:io';
import 'package:meta/meta.dart';

/// Screen emulation for 40-column BASIC output formatting.
///
/// Handles cursor positioning, tab zones, and screen formatting
/// to match original Commodore BASIC behavior.
class Screen {
  /// Screen width in characters (Commodore 40-column mode)
  static const int screenWidth = 40;

  /// Tab zone width (typically 10 characters for BASIC)
  static const int tabZoneWidth = 10;

  /// Current cursor column (0-39)
  @protected
  int _cursorColumn = 0;

  /// Current cursor row
  @protected
  int _cursorRow = 0;

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
  }
}
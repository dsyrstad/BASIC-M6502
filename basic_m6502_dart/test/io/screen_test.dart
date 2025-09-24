import 'package:test/test.dart';
import 'dart:io';
import 'package:basic_m6502_dart/io/screen.dart';

void main() {
  group('Screen', () {
    late Screen screen;

    setUp(() {
      screen = Screen();
    });

    group('Cursor Management', () {
      test('tracks cursor column position', () {
        expect(screen.cursorColumn, equals(0));

        // Simulate printing characters
        screen.printWithoutNewline('Hello');
        expect(screen.cursorColumn, equals(5));
      });

      test('tracks cursor row position', () {
        expect(screen.cursorRow, equals(0));

        // Print a line with newline
        screen.printLine('First line');
        expect(screen.cursorRow, equals(1));
        expect(screen.cursorColumn, equals(0));
      });

      test('wraps at screen width', () {
        // Print exactly 40 characters
        final text = 'X' * Screen.screenWidth;
        screen.printWithoutNewline(text);
        expect(screen.cursorRow, equals(1));
        expect(screen.cursorColumn, equals(0));
      });

      test('handles carriage return', () {
        screen.printWithoutNewline('Hello');
        expect(screen.cursorColumn, equals(5));

        screen.carriageReturn();
        expect(screen.cursorColumn, equals(0));
        expect(screen.cursorRow, equals(0)); // Should stay on same row
      });

      test('setCursorPosition clamps to screen bounds', () {
        // Test position beyond screen bounds
        screen.setCursorPosition(100, 100);
        expect(screen.cursorRow, equals(Screen.screenHeight - 1));
        expect(screen.cursorColumn, equals(Screen.screenWidth - 1));

        // Test negative positions
        screen.setCursorPosition(-5, -5);
        expect(screen.cursorRow, equals(0));
        expect(screen.cursorColumn, equals(0));
      });

      test('cursor movement functions respect boundaries', () {
        // Test cursor up at top
        screen.setCursorPosition(0, 10);
        screen.cursorUp();
        expect(screen.cursorRow, equals(0));

        // Test cursor down at bottom
        screen.setCursorPosition(Screen.screenHeight - 1, 10);
        screen.cursorDown();
        expect(screen.cursorRow, equals(Screen.screenHeight - 1));

        // Test cursor left at start
        screen.setCursorPosition(10, 0);
        screen.cursorLeft();
        expect(screen.cursorColumn, equals(0));

        // Test cursor right at end
        screen.setCursorPosition(10, Screen.screenWidth - 1);
        screen.cursorRight();
        expect(screen.cursorColumn, equals(Screen.screenWidth - 1));
      });

      test('home cursor moves to top-left', () {
        screen.setCursorPosition(10, 20);
        screen.homeCursor();
        expect(screen.cursorRow, equals(0));
        expect(screen.cursorColumn, equals(0));
      });
    });

    group('Tab Functions', () {
      test('tabs to next zone with comma separator', () {
        expect(screen.cursorColumn, equals(0));

        // First tab should go to column 10
        screen.tabToNextZone();
        expect(screen.cursorColumn, equals(10));

        // Second tab should go to column 20
        screen.tabToNextZone();
        expect(screen.cursorColumn, equals(20));

        // Third tab should go to column 30
        screen.tabToNextZone();
        expect(screen.cursorColumn, equals(30));
      });

      test('tabs wrap to new line at screen edge', () {
        // Position cursor at column 35
        screen.tabToColumn(35);

        // Next tab zone would be at 40, which exceeds screen width
        screen.tabToNextZone();
        expect(screen.cursorRow, equals(1));
        expect(screen.cursorColumn, equals(0));
      });

      test('tabs to specific column with TAB function', () {
        screen.tabToColumn(15);
        expect(screen.cursorColumn, equals(15));

        // Tab to earlier position should go to new line first
        screen.tabToColumn(10);
        expect(screen.cursorRow, equals(1));
        expect(screen.cursorColumn, equals(10));
      });

      test('TAB function clamps to screen width', () {
        screen.tabToColumn(100);
        expect(screen.cursorColumn, equals(Screen.screenWidth - 1));
      });

      test('prints spaces with SPC function', () {
        screen.printSpaces(5);
        expect(screen.cursorColumn, equals(5));

        // Test wrapping with spaces
        screen.tabToColumn(38);
        screen.printSpaces(5); // Should wrap after 2 spaces
        expect(screen.cursorRow, equals(1));
        expect(screen.cursorColumn, equals(3));
      });
    });

    group('Screen Clearing', () {
      test('clearScreen resets cursor position', () {
        screen.setCursorPosition(10, 20);
        screen.clearScreen();
        expect(screen.cursorRow, equals(0));
        expect(screen.cursorColumn, equals(0));
      });
    });

    group('Text Output', () {
      test('handles newline characters in text', () {
        screen.printWithoutNewline('Line1\nLine2');
        expect(screen.cursorRow, equals(1));
        expect(screen.cursorColumn, equals(5)); // "Line2" is 5 chars
      });

      test('handles carriage return in text', () {
        screen.printWithoutNewline('Hello\rWorld');
        expect(screen.cursorRow, equals(0));
        expect(screen.cursorColumn, equals(5)); // "World" overwrites "Hello"
      });

      test('printLine adds newline after text', () {
        screen.printLine('Hello');
        expect(screen.cursorRow, equals(1));
        expect(screen.cursorColumn, equals(0));
      });
    });

    group('40-Column Mode', () {
      test('enforces 40-column width', () {
        // Print a long line that should wrap
        final longText = 'A' * 45;
        screen.printWithoutNewline(longText);

        // Should be on second line with 5 characters
        expect(screen.cursorRow, equals(1));
        expect(screen.cursorColumn, equals(5));
      });

      test('tab zones are 10 columns wide', () {
        // Verify tab zone width constant
        expect(Screen.tabZoneWidth, equals(10));

        // Tab from column 5 should go to column 10
        screen.printWithoutNewline('Hello');
        screen.tabToNextZone();
        expect(screen.cursorColumn, equals(10));

        // Tab from column 11 should go to column 20
        screen.printWithoutNewline('X');
        screen.tabToNextZone();
        expect(screen.cursorColumn, equals(20));
      });
    });

    group('Screen Dimensions', () {
      test('has correct screen dimensions', () {
        expect(Screen.screenWidth, equals(40));
        expect(Screen.screenHeight, equals(25));
      });
    });
  });
}
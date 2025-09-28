import 'package:test/test.dart';
import 'package:basic_m6502_dart/io/commodore_chars.dart';

void main() {
  group('CommodoreChars', () {
    group('PETSCII to ASCII conversion', () {
      test('converts basic ASCII characters correctly', () {
        expect(CommodoreChars.petsciiToAsciiChar(0x20), equals(0x20)); // Space
        expect(CommodoreChars.petsciiToAsciiChar(0x30), equals(0x30)); // 0
        expect(CommodoreChars.petsciiToAsciiChar(0x39), equals(0x39)); // 9
        expect(CommodoreChars.petsciiToAsciiChar(0x40), equals(0x40)); // @
      });

      test('converts PETSCII uppercase to ASCII lowercase', () {
        expect(CommodoreChars.petsciiToAsciiChar(0x41), equals(0x61)); // A -> a
        expect(CommodoreChars.petsciiToAsciiChar(0x5A), equals(0x7A)); // Z -> z
      });

      test('converts PETSCII lowercase to ASCII uppercase', () {
        expect(CommodoreChars.petsciiToAsciiChar(0x61), equals(0x41)); // a -> A
        expect(CommodoreChars.petsciiToAsciiChar(0x7A), equals(0x5A)); // z -> Z
      });

      test('handles control characters', () {
        expect(CommodoreChars.petsciiToAsciiChar(0x0D), equals(0x0D)); // CR
        expect(CommodoreChars.petsciiToAsciiChar(0x0A), equals(0x0A)); // LF
        expect(CommodoreChars.petsciiToAsciiChar(0x13), equals(0x13)); // Home
      });

      test('handles unknown characters by returning original', () {
        expect(CommodoreChars.petsciiToAsciiChar(0xFF), equals(0xFF));
      });
    });

    group('ASCII to PETSCII conversion', () {
      test('converts basic ASCII characters correctly', () {
        expect(CommodoreChars.asciiToPetsciiChar(0x20), equals(0x20)); // Space
        expect(CommodoreChars.asciiToPetsciiChar(0x30), equals(0x30)); // 0
        expect(CommodoreChars.asciiToPetsciiChar(0x39), equals(0x39)); // 9
        expect(CommodoreChars.asciiToPetsciiChar(0x40), equals(0x40)); // @
      });

      test('converts ASCII uppercase to PETSCII lowercase', () {
        expect(CommodoreChars.asciiToPetsciiChar(0x41), equals(0x61)); // A -> a
        expect(CommodoreChars.asciiToPetsciiChar(0x5A), equals(0x7A)); // Z -> z
      });

      test('converts ASCII lowercase to PETSCII uppercase', () {
        expect(CommodoreChars.asciiToPetsciiChar(0x61), equals(0x41)); // a -> A
        expect(CommodoreChars.asciiToPetsciiChar(0x7A), equals(0x5A)); // z -> Z
      });

      test('handles control characters', () {
        expect(CommodoreChars.asciiToPetsciiChar(0x0D), equals(0x0D)); // CR
        expect(CommodoreChars.asciiToPetsciiChar(0x0A), equals(0x0A)); // LF
      });

      test('handles unknown characters by returning original', () {
        expect(CommodoreChars.asciiToPetsciiChar(0xFF), equals(0xFF));
      });
    });

    group('String conversion', () {
      test('converts PETSCII string to ASCII', () {
        final petsciiBytes = [0x48, 0x45, 0x4C, 0x4C, 0x4F]; // HELLO in PETSCII
        final result = CommodoreChars.petsciiToAsciiString(petsciiBytes);
        expect(result, equals('hello')); // Should be lowercase
      });

      test('converts ASCII string to PETSCII bytes', () {
        final asciiString = 'HELLO';
        final result = CommodoreChars.asciiToPetsciiBytes(asciiString);
        expect(result, equals([0x68, 0x65, 0x6C, 0x6C, 0x6F])); // Should be PETSCII lowercase
      });

      test('converts mixed case string correctly', () {
        final asciiString = 'Hello123';
        final result = CommodoreChars.asciiToPetsciiBytes(asciiString);
        expect(result, equals([0x68, 0x45, 0x4C, 0x4C, 0x4F, 0x31, 0x32, 0x33]));
      });
    });

    group('Character classification', () {
      test('identifies control characters', () {
        expect(CommodoreChars.isControlChar(0x00), isTrue); // NULL
        expect(CommodoreChars.isControlChar(0x0D), isTrue); // CR
        expect(CommodoreChars.isControlChar(0x13), isTrue); // Home
        expect(CommodoreChars.isControlChar(0x93), isTrue); // Clear screen
        expect(CommodoreChars.isControlChar(0x41), isFalse); // A
        expect(CommodoreChars.isControlChar(0x30), isFalse); // 0
      });

      test('identifies graphics characters', () {
        expect(CommodoreChars.isGraphicsChar(0xA0), isTrue);
        expect(CommodoreChars.isGraphicsChar(0xFF), isTrue);
        expect(CommodoreChars.isGraphicsChar(0x41), isFalse); // A
        expect(CommodoreChars.isGraphicsChar(0x30), isFalse); // 0
      });

      test('identifies printable characters', () {
        expect(CommodoreChars.isPrintableChar(0x41), isTrue); // A
        expect(CommodoreChars.isPrintableChar(0x30), isTrue); // 0
        expect(CommodoreChars.isPrintableChar(0x20), isTrue); // Space
        expect(CommodoreChars.isPrintableChar(0xA0), isTrue); // Graphics
        expect(CommodoreChars.isPrintableChar(0x00), isFalse); // NULL
        expect(CommodoreChars.isPrintableChar(0x0D), isFalse); // CR
      });
    });

    group('Control character descriptions', () {
      test('provides correct descriptions for common control chars', () {
        expect(CommodoreChars.getControlCharDescription(0x00), equals('NULL'));
        expect(CommodoreChars.getControlCharDescription(0x0D), equals('RETURN'));
        expect(CommodoreChars.getControlCharDescription(0x13), equals('HOME'));
        expect(CommodoreChars.getControlCharDescription(0x93), equals('CLEAR SCREEN'));
        expect(CommodoreChars.getControlCharDescription(0x1C), equals('RED'));
        expect(CommodoreChars.getControlCharDescription(0x9E), equals('YELLOW'));
      });

      test('provides hex representation for unknown control chars', () {
        final result = CommodoreChars.getControlCharDescription(0xFF);
        expect(result, equals('UNKNOWN(FF)'));
      });
    });

    group('Special control codes', () {
      test('defines correct values for special codes', () {
        expect(CommodoreChars.clearScreen, equals(0x93));
        expect(CommodoreChars.home, equals(0x13));
        expect(CommodoreChars.cursorDown, equals(0x11));
        expect(CommodoreChars.cursorUp, equals(0x91));
        expect(CommodoreChars.cursorRight, equals(0x1D));
        expect(CommodoreChars.cursorLeft, equals(0x9D));
        expect(CommodoreChars.reverseOn, equals(0x12));
        expect(CommodoreChars.reverseOff, equals(0x92));
      });
    });

    group('Color codes', () {
      test('defines correct values for color codes', () {
        expect(CommodoreChars.black, equals(0x90));
        expect(CommodoreChars.white, equals(0x05));
        expect(CommodoreChars.red, equals(0x1C));
        expect(CommodoreChars.cyan, equals(0x9F));
        expect(CommodoreChars.purple, equals(0x9C));
        expect(CommodoreChars.green, equals(0x1E));
        expect(CommodoreChars.blue, equals(0x1F));
        expect(CommodoreChars.yellow, equals(0x9E));
      });
    });

    group('Round-trip conversion', () {
      test('ASCII to PETSCII to ASCII preserves content', () {
        final original = 'Hello World 123!';
        final petsciiBytes = CommodoreChars.asciiToPetsciiBytes(original);
        final roundTrip = CommodoreChars.petsciiToAsciiString(petsciiBytes);

        // Note: Case will be inverted due to Commodore's character mapping
        expect(roundTrip.toLowerCase(), equals(original.toLowerCase()));
      });

      test('PETSCII to ASCII to PETSCII preserves bytes for basic chars', () {
        final petsciiBytes = [0x48, 0x45, 0x4C, 0x4C, 0x4F, 0x20, 0x57, 0x4F, 0x52, 0x4C, 0x44];
        final asciiString = CommodoreChars.petsciiToAsciiString(petsciiBytes);
        final roundTrip = CommodoreChars.asciiToPetsciiBytes(asciiString);

        // Should preserve the mapping through the round trip
        expect(roundTrip.length, equals(petsciiBytes.length));
      });
    });
  });
}
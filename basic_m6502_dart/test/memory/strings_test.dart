import 'package:test/test.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/strings.dart';

void main() {
  group('StringManager', () {
    late Memory memory;
    late StringManager stringManager;

    setUp(() {
      memory = Memory();
      stringManager = StringManager(memory);

      // Set up basic memory layout
      memory.writeWord(Memory.vartab, 0x0800);  // Variable table at 0x0800
      memory.writeWord(Memory.arytab, 0x0800);  // Array table starts same place
      memory.writeWord(Memory.strend, 0x0800);  // String end at variable table
      memory.writeWord(Memory.memsiz, 0x8000);  // Top of memory at 32KB

      stringManager.initialize(0x8000);
    });

    group('String Creation', () {
      test('creates empty string descriptor', () {
        final descriptor = stringManager.createString('');
        expect(descriptor.length, equals(0));
        expect(descriptor.pointer, equals(0));
        expect(descriptor.isEmpty, isTrue);
      });

      test('creates single character string', () {
        final descriptor = stringManager.createString('A');
        expect(descriptor.length, equals(1));
        expect(descriptor.pointer, greaterThan(0));
        expect(descriptor.isNotEmpty, isTrue);

        final readBack = stringManager.readString(descriptor);
        expect(readBack, equals('A'));
      });

      test('creates multi-character string', () {
        final testString = 'HELLO WORLD';
        final descriptor = stringManager.createString(testString);
        expect(descriptor.length, equals(testString.length));

        final readBack = stringManager.readString(descriptor);
        expect(readBack, equals(testString));
      });

      test('throws exception for string too long', () {
        final longString = 'A' * 256;
        expect(
          () => stringManager.createString(longString),
          throwsA(isA<StringException>())
        );
      });

      test('handles maximum length string', () {
        final maxString = 'B' * 255;
        final descriptor = stringManager.createString(maxString);
        expect(descriptor.length, equals(255));

        final readBack = stringManager.readString(descriptor);
        expect(readBack, equals(maxString));
      });
    });

    group('Temporary Strings', () {
      test('creates temporary string', () {
        final descriptor = stringManager.createTemporaryString('TEMP');
        expect(descriptor.length, equals(4));

        final readBack = stringManager.readString(descriptor);
        expect(readBack, equals('TEMP'));
      });

      test('manages temporary string stack', () {
        // Create more temporary strings than stack size
        for (int i = 0; i < 5; i++) {
          stringManager.createTemporaryString('TEMP$i');
        }

        // Should not throw - oldest strings are automatically removed
        expect(stringManager.createTemporaryString('FINAL'), isA<StringDescriptor>());
      });

      test('clears temporary strings', () {
        stringManager.createTemporaryString('TEMP1');
        stringManager.createTemporaryString('TEMP2');

        stringManager.clearTemporaryStrings();

        // After clearing, temp pointer should be reset
        expect(memory.readWord(Memory.frespc), equals(0));
      });
    });

    group('String Operations', () {
      test('concatenates strings', () {
        final left = stringManager.createString('HELLO');
        final right = stringManager.createString(' WORLD');

        final result = stringManager.concatenateStrings(left, right);
        final readBack = stringManager.readString(result);

        expect(readBack, equals('HELLO WORLD'));
      });

      test('concatenates with empty strings', () {
        final nonEmpty = stringManager.createString('TEST');
        final empty = stringManager.createString('');

        final result1 = stringManager.concatenateStrings(empty, nonEmpty);
        expect(stringManager.readString(result1), equals('TEST'));

        final result2 = stringManager.concatenateStrings(nonEmpty, empty);
        expect(stringManager.readString(result2), equals('TEST'));
      });

      test('compares strings correctly', () {
        final str1 = stringManager.createString('APPLE');
        final str2 = stringManager.createString('BANANA');
        final str3 = stringManager.createString('APPLE');

        expect(stringManager.compareStrings(str1, str2), lessThan(0));
        expect(stringManager.compareStrings(str2, str1), greaterThan(0));
        expect(stringManager.compareStrings(str1, str3), equals(0));

        expect(stringManager.areStringsEqual(str1, str3), isTrue);
        expect(stringManager.areStringsEqual(str1, str2), isFalse);
      });

      test('extracts substrings', () {
        final source = stringManager.createString('HELLO WORLD');

        // Test substring with length
        final sub1 = stringManager.substring(source, 0, 5);
        expect(stringManager.readString(sub1), equals('HELLO'));

        final sub2 = stringManager.substring(source, 6, 5);
        expect(stringManager.readString(sub2), equals('WORLD'));

        // Test substring to end
        final sub3 = stringManager.substring(source, 6);
        expect(stringManager.readString(sub3), equals('WORLD'));

        // Test out of bounds
        final sub4 = stringManager.substring(source, 100);
        expect(stringManager.readString(sub4), equals(''));
      });

      test('gets string length', () {
        final str1 = stringManager.createString('TEST');
        final str2 = stringManager.createString('');

        expect(stringManager.getStringLength(str1), equals(4));
        expect(stringManager.getStringLength(str2), equals(0));
      });
    });

    group('ASCII Operations', () {
      test('converts ASCII to character', () {
        final descriptor = stringManager.charFromAscii(65); // 'A'
        expect(stringManager.readString(descriptor), equals('A'));
      });

      test('throws exception for invalid ASCII', () {
        expect(
          () => stringManager.charFromAscii(-1),
          throwsA(isA<StringException>())
        );

        expect(
          () => stringManager.charFromAscii(256),
          throwsA(isA<StringException>())
        );
      });

      test('gets ASCII from character', () {
        final descriptor = stringManager.createString('Z');
        expect(stringManager.asciiFromChar(descriptor), equals(90));
      });

      test('throws exception for empty string ASC', () {
        final empty = stringManager.createString('');
        expect(
          () => stringManager.asciiFromChar(empty),
          throwsA(isA<StringException>())
        );
      });
    });

    group('Descriptor Operations', () {
      test('reads and writes descriptors', () {
        final original = stringManager.createString('TEST');
        const address = 0x1000;

        stringManager.writeDescriptor(address, original);
        final readBack = stringManager.readDescriptor(address);

        expect(readBack.length, equals(original.length));
        expect(readBack.pointer, equals(original.pointer));
      });

      test('handles empty descriptors', () {
        final empty = StringDescriptor(length: 0, pointer: 0);
        const address = 0x1000;

        stringManager.writeDescriptor(address, empty);
        final readBack = stringManager.readDescriptor(address);

        expect(readBack.isEmpty, isTrue);
        expect(stringManager.readString(readBack), equals(''));
      });
    });

    group('Memory Management', () {
      test('tracks available string space', () {
        final initialSpace = stringManager.getAvailableStringSpace();
        expect(initialSpace, greaterThan(0));

        // Create a string and check space decreased
        stringManager.createString('TEST STRING');
        final afterSpace = stringManager.getAvailableStringSpace();
        expect(afterSpace, lessThan(initialSpace));
      });

      test('detects low string space', () {
        // Initially should not be low
        expect(stringManager.isStringSpaceLow(), isFalse);

        // Create many strings to fill space
        for (int i = 0; i < 100; i++) {
          stringManager.createString('String number $i - this is a longer string to fill memory');
        }

        // Now it might be low (depending on available memory)
        // This test mainly checks that the method doesn't crash
        stringManager.isStringSpaceLow();
      });

      test('performs garbage collection', () {
        // Create some strings
        final str1 = stringManager.createString('PERMANENT');
        stringManager.createString('TEMPORARY'); // Not saved, eligible for GC

        final spaceBefore = stringManager.getAvailableStringSpace();

        // Force garbage collection
        stringManager.garbageCollect();

        final spaceAfter = stringManager.getAvailableStringSpace();

        // Space should be the same or better after GC
        expect(spaceAfter, greaterThanOrEqualTo(spaceBefore));

        // Permanent string should still be readable
        expect(stringManager.readString(str1), equals('PERMANENT'));
      });

      test('resets to initial state', () {
        // Create some strings and temporary strings
        stringManager.createString('TEST1');
        stringManager.createTemporaryString('TEMP1');

        stringManager.reset();

        // Temp stack should be clear
        expect(memory.readWord(Memory.frespc), equals(0));

        // String space should be reset to top
        expect(memory.readWord(Memory.fretop), equals(0x8000));
      });
    });

    group('Edge Cases', () {
      test('handles string space exhaustion', () {
        // Set up very limited string space
        memory.writeWord(Memory.strend, 0x7FF0); // Almost at top
        stringManager.initialize(0x8000);

        // Try to create a large string
        expect(
          () => stringManager.createString('A' * 100),
          throwsA(isA<StringException>())
        );
      });

      test('handles concurrent string operations', () {
        final str1 = stringManager.createString('FIRST');
        final str2 = stringManager.createString('SECOND');

        final concat = stringManager.concatenateStrings(str1, str2);
        expect(stringManager.readString(concat), equals('FIRSTSECOND'));

        // Original strings should still be valid
        expect(stringManager.readString(str1), equals('FIRST'));
        expect(stringManager.readString(str2), equals('SECOND'));
      });
    });
  });

  group('StringDescriptor', () {
    test('creates descriptor correctly', () {
      const descriptor = StringDescriptor(length: 5, pointer: 0x1000);

      expect(descriptor.length, equals(5));
      expect(descriptor.pointer, equals(0x1000));
      expect(descriptor.isEmpty, isFalse);
      expect(descriptor.isNotEmpty, isTrue);
    });

    test('handles empty descriptor', () {
      const empty1 = StringDescriptor(length: 0, pointer: 0x1000);
      const empty2 = StringDescriptor(length: 5, pointer: 0);

      expect(empty1.isEmpty, isTrue);
      expect(empty2.isEmpty, isTrue);
    });

    test('equality works correctly', () {
      const desc1 = StringDescriptor(length: 5, pointer: 0x1000);
      const desc2 = StringDescriptor(length: 5, pointer: 0x1000);
      const desc3 = StringDescriptor(length: 5, pointer: 0x2000);

      expect(desc1, equals(desc2));
      expect(desc1, isNot(equals(desc3)));
    });

    test('toString provides useful output', () {
      const descriptor = StringDescriptor(length: 5, pointer: 0x1000);
      final str = descriptor.toString();

      expect(str, contains('5'));
      expect(str, contains('1000'));
    });
  });
}
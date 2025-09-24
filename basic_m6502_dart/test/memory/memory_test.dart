import 'package:test/test.dart';
import 'package:basic_m6502_dart/memory/memory.dart';

void main() {
  group('Memory', () {
    late Memory memory;

    setUp(() {
      memory = Memory();
    });

    group('Byte operations', () {
      test('should read and write bytes correctly', () {
        memory.writeByte(0x1000, 0x42);
        expect(memory.readByte(0x1000), equals(0x42));

        memory.writeByte(0x00FF, 0xFF);
        expect(memory.readByte(0x00FF), equals(0xFF));

        memory.writeByte(0x0000, 0x00);
        expect(memory.readByte(0x0000), equals(0x00));
      });

      test('should throw on invalid address', () {
        expect(() => memory.readByte(-1), throwsA(isA<MemoryException>()));
        expect(() => memory.readByte(65536), throwsA(isA<MemoryException>()));
        expect(() => memory.writeByte(-1, 0), throwsA(isA<MemoryException>()));
        expect(
          () => memory.writeByte(65536, 0),
          throwsA(isA<MemoryException>()),
        );
      });

      test('should throw on invalid byte value', () {
        expect(
          () => memory.writeByte(0x1000, -1),
          throwsA(isA<MemoryException>()),
        );
        expect(
          () => memory.writeByte(0x1000, 256),
          throwsA(isA<MemoryException>()),
        );
      });
    });

    group('Word operations', () {
      test('should read and write words correctly (little-endian)', () {
        memory.writeWord(0x1000, 0x1234);
        expect(memory.readWord(0x1000), equals(0x1234));
        expect(memory.readByte(0x1000), equals(0x34)); // Low byte
        expect(memory.readByte(0x1001), equals(0x12)); // High byte

        memory.writeWord(0x2000, 0xFFFF);
        expect(memory.readWord(0x2000), equals(0xFFFF));
      });

      test('should handle zero page word operations', () {
        memory.writeWord(Memory.txtptr, 0x0800);
        expect(memory.readWord(Memory.txtptr), equals(0x0800));
      });

      test('should throw on invalid word address', () {
        expect(() => memory.readWord(-1), throwsA(isA<MemoryException>()));
        expect(() => memory.readWord(65535), throwsA(isA<MemoryException>()));
        expect(
          () => memory.writeWord(65535, 0),
          throwsA(isA<MemoryException>()),
        );
      });

      test('should throw on invalid word value', () {
        expect(
          () => memory.writeWord(0x1000, -1),
          throwsA(isA<MemoryException>()),
        );
        expect(
          () => memory.writeWord(0x1000, 0x10000),
          throwsA(isA<MemoryException>()),
        );
      });
    });

    group('String operations', () {
      test('should read and write null-terminated strings', () {
        const testStr = 'HELLO WORLD';
        memory.writeString(0x2000, testStr);
        expect(memory.readString(0x2000), equals(testStr));
        expect(
          memory.readByte(0x2000 + testStr.length),
          equals(0),
        ); // Null terminator
      });

      test('should handle empty strings', () {
        memory.writeString(0x3000, '');
        expect(memory.readString(0x3000), equals(''));
        expect(memory.readByte(0x3000), equals(0));
      });

      test('should stop reading at null terminator', () {
        memory.writeString(0x4000, 'HELLO');
        memory.writeString(0x4006, 'WORLD');
        expect(memory.readString(0x4000), equals('HELLO'));
        expect(memory.readString(0x4006), equals('WORLD'));
      });
    });

    group('Block operations', () {
      test('should copy memory blocks correctly', () {
        // Write test data
        for (int i = 0; i < 10; i++) {
          memory.writeByte(0x1000 + i, i);
        }

        // Copy to another location
        memory.copyBlock(0x1000, 0x2000, 10);

        // Verify copy
        for (int i = 0; i < 10; i++) {
          expect(memory.readByte(0x2000 + i), equals(i));
        }
      });

      test('should handle overlapping copies correctly', () {
        // Write test data
        for (int i = 0; i < 10; i++) {
          memory.writeByte(0x1000 + i, i);
        }

        // Copy with overlap (forward)
        memory.copyBlock(0x1000, 0x1005, 5);
        expect(memory.readByte(0x1005), equals(0));
        expect(memory.readByte(0x1006), equals(1));

        // Copy with overlap (backward)
        memory.copyBlock(0x1005, 0x1003, 5);
        expect(memory.readByte(0x1003), equals(0));
        expect(memory.readByte(0x1004), equals(1));
      });

      test('should fill memory blocks correctly', () {
        memory.fillBlock(0x3000, 100, 0xAA);

        for (int i = 0; i < 100; i++) {
          expect(memory.readByte(0x3000 + i), equals(0xAA));
        }

        // Check boundary
        expect(memory.readByte(0x2FFF), equals(0));
        expect(memory.readByte(0x3064), equals(0));
      });

      test('should throw on invalid block operations', () {
        expect(
          () => memory.copyBlock(-1, 0, 10),
          throwsA(isA<MemoryException>()),
        );
        expect(
          () => memory.copyBlock(0, 65530, 10),
          throwsA(isA<MemoryException>()),
        );
        expect(
          () => memory.fillBlock(65530, 10, 0),
          throwsA(isA<MemoryException>()),
        );
        expect(
          () => memory.fillBlock(0, 10, 256),
          throwsA(isA<MemoryException>()),
        );
      });
    });

    group('Debug utilities', () {
      test('should create memory view', () {
        for (int i = 0; i < 10; i++) {
          memory.writeByte(0x1000 + i, i * 10);
        }

        final view = memory.getMemoryView(0x1000, 10);
        expect(view.length, equals(10));
        for (int i = 0; i < 10; i++) {
          expect(view[i], equals(i * 10));
        }
      });

      test('should create hex dump', () {
        // Write recognizable pattern
        memory.writeString(0x1000, 'Hello World!');
        memory.writeByte(0x100C, 0xFF);
        memory.writeByte(0x100D, 0x00);
        memory.writeByte(0x100E, 0x42);

        final dump = memory.hexDump(0x1000, 16);
        expect(dump, contains('1000:'));
        expect(
          dump,
          contains('48 65 6c 6c 6f 20 57 6f 72 6c 64 21'),
        ); // "Hello World!" in hex
        expect(dump, contains('Hello World!'));
      });

      test('should reset memory', () {
        memory.writeByte(0x1000, 0x42);
        memory.writeByte(0x2000, 0x84);
        expect(memory.readByte(0x1000), equals(0x42));
        expect(memory.readByte(0x2000), equals(0x84));

        memory.reset();
        expect(memory.readByte(0x1000), equals(0));
        expect(memory.readByte(0x2000), equals(0));
      });
    });

    group('Memory regions', () {
      test('should identify zero page addresses', () {
        expect(memory.isZeroPage(0x00), isTrue);
        expect(memory.isZeroPage(0xFF), isTrue);
        expect(memory.isZeroPage(Memory.txtptr), isTrue);
        expect(memory.isZeroPage(0x100), isFalse);
        expect(memory.isZeroPage(0x1000), isFalse);
      });

      test('should identify stack addresses', () {
        expect(memory.isStack(0xFF), isFalse);
        expect(memory.isStack(0x100), isTrue);
        expect(memory.isStack(0x1FF), isTrue);
        expect(memory.isStack(0x200), isFalse);
      });

      test('should have correct zero page constants', () {
        // Verify key zero page locations match expected values
        expect(Memory.chrget, equals(0x70));
        expect(Memory.txtptr, equals(0x7A));
        expect(Memory.vartab, equals(0x2D));
        expect(Memory.facexp, equals(0x61));
        expect(Memory.argexp, equals(0x69));
      });
    });
  });
}

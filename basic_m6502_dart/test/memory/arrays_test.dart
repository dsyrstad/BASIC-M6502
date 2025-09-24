import 'package:test/test.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/arrays.dart';
import '../../lib/memory/variables.dart';

void main() {
  group('ArrayManager', () {
    late Memory memory;
    late ArrayManager arrayManager;

    setUp(() {
      memory = Memory();
      arrayManager = ArrayManager(memory);

      // Set up basic memory layout
      memory.writeWord(Memory.vartab, 0x0800);  // Variable table at 0x0800
      memory.writeWord(Memory.arytab, 0x0800);  // Array table starts same place
      memory.writeWord(Memory.strend, 0x0800);  // String end at array table
      memory.writeWord(Memory.fretop, 0x8000);  // String space at 32KB
      memory.writeWord(Memory.memsiz, 0x8000);  // Top of memory at 32KB
    });

    group('Array Creation', () {
      test('creates simple 1D numeric array', () {
        final descriptor = arrayManager.createArray('A', [10]);

        expect(descriptor.name, equals('A'));
        expect(descriptor.dimensionCount, equals(1));
        expect(descriptor.dimensions, equals([10]));
        expect(descriptor.isString, isFalse);
        expect(descriptor.elementSize, equals(4));

        // Check that array is findable
        final result = arrayManager.findArray('A');
        expect(result.found, isTrue);
        expect(result.name, equals('A'));
      });

      test('creates 1D string array', () {
        final descriptor = arrayManager.createArray('A\$', [5], isString: true);

        expect(descriptor.name, equals('A')); // Name without $ in descriptor
        expect(descriptor.dimensionCount, equals(1));
        expect(descriptor.dimensions, equals([5]));
        expect(descriptor.isString, isTrue);
        expect(descriptor.elementSize, equals(3));
      });

      test('creates multi-dimensional array', () {
        final descriptor = arrayManager.createArray('B', [5, 10, 3]);

        expect(descriptor.dimensionCount, equals(3));
        expect(descriptor.dimensions, equals([5, 10, 3]));

        // Total elements should be 6 * 11 * 4 = 264
        final elementCount = arrayManager.getArrayElementCount(descriptor);
        expect(elementCount, equals(264));
      });

      test('throws error for array already dimensioned', () {
        arrayManager.createArray('A', [10]);

        expect(
          () => arrayManager.createArray('A', [20]),
          throwsA(isA<ArrayException>())
        );
      });

      test('throws error for too many dimensions', () {
        final dimensions = List.filled(15, 5); // More than maxDimensions

        expect(
          () => arrayManager.createArray('A', dimensions),
          throwsA(isA<ArrayException>())
        );
      });

      test('throws error for invalid dimension size', () {
        expect(
          () => arrayManager.createArray('A', [-1]),
          throwsA(isA<ArrayException>())
        );

        expect(
          () => arrayManager.createArray('A', [100000]),
          throwsA(isA<ArrayException>())
        );
      });

      test('handles maximum dimensions', () {
        final dimensions = List.filled(10, 1); // Exactly maxDimensions, smaller size

        final descriptor = arrayManager.createArray('A', dimensions);
        expect(descriptor.dimensionCount, equals(10));
      });
    });

    group('Array Lookup', () {
      test('finds existing array', () {
        final original = arrayManager.createArray('TE', [5, 10]);

        final result = arrayManager.findArray('TE');
        expect(result.found, isTrue);
        expect(result.name, equals('TE'));
        expect(result.descriptor!.dimensions, equals([5, 10]));
      });

      test('normalizes array names', () {
        arrayManager.createArray('a', [5]);

        final result1 = arrayManager.findArray('A');
        final result2 = arrayManager.findArray('a(');

        expect(result1.found, isTrue);
        expect(result2.found, isTrue);
      });

      test('handles array not found', () {
        final result = arrayManager.findArray('NOTFOUND');
        expect(result.found, isFalse);
        expect(result.descriptor, isNull);
      });

      test('distinguishes string arrays', () {
        arrayManager.createArray('S\$', [5], isString: true);
        arrayManager.createArray('N', [5], isString: false);

        final stringResult = arrayManager.findArray('S\$');
        final numericResult = arrayManager.findArray('N');

        expect(stringResult.isString, isTrue);
        expect(numericResult.isString, isFalse);
      });
    });

    group('Array Element Access', () {
      test('calculates correct element addresses', () {
        final descriptor = arrayManager.createArray('A', [3, 4]); // 4x5 array

        // Test corner elements
        final addr00 = arrayManager.getElementAddress(descriptor, [0, 0]);
        final addr34 = arrayManager.getElementAddress(descriptor, [3, 4]);

        expect(addr00, equals(descriptor.address + descriptor.dataOffset));

        // Last element should be at offset (3*5 + 4) * 4 = 76 bytes from start
        final expectedLast = descriptor.address + descriptor.dataOffset + (19 * 4);
        expect(addr34, equals(expectedLast));
      });

      test('validates array indices', () {
        final descriptor = arrayManager.createArray('A', [5, 10]);

        // Valid indices
        expect(
          () => arrayManager.getElementAddress(descriptor, [0, 0]),
          returnsNormally
        );
        expect(
          () => arrayManager.getElementAddress(descriptor, [5, 10]),
          returnsNormally
        );

        // Invalid indices
        expect(
          () => arrayManager.getElementAddress(descriptor, [6, 5]),
          throwsA(isA<ArrayException>())
        );
        expect(
          () => arrayManager.getElementAddress(descriptor, [-1, 5]),
          throwsA(isA<ArrayException>())
        );
        expect(
          () => arrayManager.getElementAddress(descriptor, [3, 11]),
          throwsA(isA<ArrayException>())
        );
      });

      test('validates number of indices', () {
        final descriptor = arrayManager.createArray('A', [5, 10, 3]);

        expect(
          () => arrayManager.getElementAddress(descriptor, [1, 2]),
          throwsA(isA<ArrayException>())
        );
        expect(
          () => arrayManager.getElementAddress(descriptor, [1, 2, 3, 4]),
          throwsA(isA<ArrayException>())
        );
      });
    });

    group('Array Element Values', () {
      test('reads and writes numeric array elements', () {
        final descriptor = arrayManager.createArray('N', [3, 3]);

        // Set a value
        arrayManager.setArrayElement(descriptor, [1, 2], const NumericValue(42.5));

        // Read it back
        final value = arrayManager.getArrayElement(descriptor, [1, 2]);
        expect(value, isA<NumericValue>());
        expect((value as NumericValue).value, closeTo(42.5, 0.001));
      });

      test('initializes array elements to zero', () {
        final descriptor = arrayManager.createArray('Z', [2, 2]);

        // All elements should be zero initially
        for (int i = 0; i <= 2; i++) {
          for (int j = 0; j <= 2; j++) {
            final value = arrayManager.getArrayElement(descriptor, [i, j]);
            expect(value, isA<NumericValue>());
            expect((value as NumericValue).value, equals(0.0));
          }
        }
      });

      test('handles type mismatch errors', () {
        final numericArray = arrayManager.createArray('N', [5]);
        final stringArray = arrayManager.createArray('S\$', [5], isString: true);

        // Try to assign string to numeric array
        expect(
          () => arrayManager.setArrayElement(numericArray, [0], const StringValue('test')),
          throwsA(isA<ArrayException>())
        );

        // Try to assign numeric to string array
        expect(
          () => arrayManager.setArrayElement(stringArray, [0], const NumericValue(42)),
          throwsA(isA<ArrayException>())
        );
      });

      test('string array assignment throws not implemented', () {
        final descriptor = arrayManager.createArray('S\$', [3], isString: true);

        // String array assignment is not fully implemented yet
        expect(
          () => arrayManager.setArrayElement(descriptor, [0], const StringValue('test')),
          throwsA(isA<ArrayException>())
        );
      });
    });

    group('Multiple Arrays', () {
      test('manages multiple arrays independently', () {
        final array1 = arrayManager.createArray('A', [5]);
        final array2 = arrayManager.createArray('B', [10, 3]);
        final array3 = arrayManager.createArray('C\$', [7], isString: true);

        // All should be findable
        expect(arrayManager.findArray('A').found, isTrue);
        expect(arrayManager.findArray('B').found, isTrue);
        expect(arrayManager.findArray('C\$').found, isTrue);

        // Check properties
        expect(arrayManager.findArray('A').descriptor!.dimensions, equals([5]));
        expect(arrayManager.findArray('B').descriptor!.dimensions, equals([10, 3]));
        expect(arrayManager.findArray('C\$').descriptor!.isString, isTrue);
      });

      test('arrays have different memory addresses', () {
        final array1 = arrayManager.createArray('A', [5]);
        final array2 = arrayManager.createArray('B', [5]);
        final array3 = arrayManager.createArray('C', [5]);

        expect(array1.address, lessThan(array2.address));
        expect(array2.address, lessThan(array3.address));
      });
    });

    group('Memory Management', () {
      test('tracks memory usage correctly', () {
        final initialInfo = arrayManager.getMemoryInfo();
        expect(initialInfo.totalArrays, equals(0));
        expect(initialInfo.totalElements, equals(0));
        expect(initialInfo.memoryUsed, equals(0));

        arrayManager.createArray('A', [5]);
        arrayManager.createArray('B', [3, 4]);

        final finalInfo = arrayManager.getMemoryInfo();
        expect(finalInfo.totalArrays, equals(2));
        expect(finalInfo.totalElements, equals(6 + 12)); // 6 + 4*3 = 18
        expect(finalInfo.memoryUsed, greaterThan(0));
      });

      test('clears all arrays', () {
        arrayManager.createArray('A', [5]);
        arrayManager.createArray('B', [10]);

        arrayManager.clearArrays();

        expect(arrayManager.findArray('A').found, isFalse);
        expect(arrayManager.findArray('B').found, isFalse);

        final info = arrayManager.getMemoryInfo();
        expect(info.totalArrays, equals(0));
      });

      test('detects out of memory condition', () {
        // Set up very limited space
        memory.writeWord(Memory.fretop, 0x0900); // Only 256 bytes available

        // Try to create a large array
        expect(
          () => arrayManager.createArray('BIG', [100, 100]),
          throwsA(isA<ArrayException>())
        );
      });
    });

    group('Array Descriptor', () {
      test('creates descriptor with correct properties', () {
        final descriptor = arrayManager.createArray('TEST', [5, 10]);

        expect(descriptor.name, equals('TE'));
        expect(descriptor.dimensionCount, equals(2));
        expect(descriptor.dimensions, equals([5, 10]));
        expect(descriptor.isString, isFalse);
        expect(descriptor.elementSize, equals(4));
        expect(descriptor.totalSize, greaterThan(0));
      });

      test('handles single character names', () {
        final descriptor = arrayManager.createArray('X', [5]);
        expect(descriptor.name, equals('X'));
      });

      test('toString provides useful information', () {
        final descriptor = arrayManager.createArray('A', [5, 10]);
        final str = descriptor.toString();

        expect(str, contains('A'));
        expect(str, contains('[5, 10]'));
        expect(str, contains('isString: false'));
      });
    });

    group('Edge Cases', () {
      test('handles array with zero-size dimension', () {
        final descriptor = arrayManager.createArray('A', [0]);

        // Array with dimension [0] has 1 element (index 0)
        expect(arrayManager.getArrayElementCount(descriptor), equals(1));

        // Should be able to access element [0]
        expect(
          () => arrayManager.getElementAddress(descriptor, [0]),
          returnsNormally
        );

        // Should not be able to access element [1]
        expect(
          () => arrayManager.getElementAddress(descriptor, [1]),
          throwsA(isA<ArrayException>())
        );
      });

      test('handles large but valid arrays', () {
        // Create reasonably large array that should fit (use 2-char name)
        final descriptor = arrayManager.createArray('LA', [20, 10]);

        expect(descriptor.dimensionCount, equals(2));
        expect(arrayManager.getArrayElementCount(descriptor), equals(21 * 11));
      });

      test('validates array name format', () {
        expect(
          () => arrayManager.createArray('', [5]),
          throwsA(isA<ArrayException>())
        );

        // Long names are allowed - only first 2 chars are used
        final descriptor = arrayManager.createArray('TOOLONG', [5]);
        expect(descriptor.name, equals('TO'));
      });

      test('handles concurrent array operations', () {
        final descriptor1 = arrayManager.createArray('A', [3, 3]);
        final descriptor2 = arrayManager.createArray('B', [3, 3]);

        // Set values in both arrays
        arrayManager.setArrayElement(descriptor1, [1, 1], const NumericValue(11));
        arrayManager.setArrayElement(descriptor2, [1, 1], const NumericValue(22));

        // Check that values are independent
        final value1 = arrayManager.getArrayElement(descriptor1, [1, 1]);
        final value2 = arrayManager.getArrayElement(descriptor2, [1, 1]);

        expect((value1 as NumericValue).value, closeTo(11, 0.001));
        expect((value2 as NumericValue).value, closeTo(22, 0.001));
      });
    });
  });

  group('ArrayResult', () {
    test('creates result correctly', () {
      const result = ArrayResult(
        found: true,
        address: 0x1000,
        name: 'TEST',
        descriptor: null,
        isString: false,
      );

      expect(result.found, isTrue);
      expect(result.address, equals(0x1000));
      expect(result.name, equals('TEST'));
      expect(result.isString, isFalse);
    });
  });

  group('ArrayMemoryInfo', () {
    test('creates info correctly', () {
      const info = ArrayMemoryInfo(
        totalArrays: 5,
        totalElements: 100,
        memoryUsed: 1024,
        availableSpace: 2048,
      );

      expect(info.totalArrays, equals(5));
      expect(info.totalElements, equals(100));
      expect(info.memoryUsed, equals(1024));
      expect(info.availableSpace, equals(2048));
    });

    test('toString provides useful output', () {
      const info = ArrayMemoryInfo(
        totalArrays: 5,
        totalElements: 100,
        memoryUsed: 1024,
        availableSpace: 2048,
      );

      final str = info.toString();
      expect(str, contains('5'));
      expect(str, contains('100'));
      expect(str, contains('1024'));
      expect(str, contains('2048'));
    });
  });
}
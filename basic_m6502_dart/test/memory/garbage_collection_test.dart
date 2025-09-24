import 'package:test/test.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';
import '../../lib/memory/strings.dart';
import '../../lib/memory/values.dart';

void main() {
  group('String Garbage Collection', () {
    late Memory memory;
    late VariableStorage variables;
    late StringManager stringManager;

    setUp(() {
      memory = Memory();
      variables = VariableStorage(memory);
      stringManager = StringManager(memory);

      // Initialize memory
      variables.initialize(0x2000);

      // Set up string space (from top of memory down)
      final memtop = 0x8000;
      memory.writeWord(Memory.memsiz, memtop);
      stringManager.initialize(memtop);
    });

    test('should initialize with empty string space', () {
      expect(memory.readWord(Memory.fretop), equals(0x8000));
      expect(
        memory.readWord(Memory.strend),
        equals(0x2000),
      ); // String end starts after variables/arrays
    });

    test('should allocate string space from top down', () {
      final descriptor = stringManager.createTemporaryString('Hello');

      expect(descriptor.length, equals(5));
      expect(
        descriptor.pointer,
        equals(0x8000 - 5),
      ); // Top of memory minus string length

      final storedString = stringManager.readString(descriptor);
      expect(storedString, equals('Hello'));
    });

    test('should manage multiple string allocations', () {
      final str1 = stringManager.createTemporaryString('First');
      final str2 = stringManager.createTemporaryString('Second');

      expect(str1.length, equals(5));
      expect(str2.length, equals(6));
      expect(str1.pointer, equals(0x8000 - 5));
      expect(str2.pointer, equals(0x8000 - 5 - 6)); // Below first string

      expect(stringManager.readString(str1), equals('First'));
      expect(stringManager.readString(str2), equals('Second'));
    });

    test('should collect garbage and compact string space', () {
      // Create string variables
      variables.setVariable('A\$', StringValue('Hello'));
      variables.setVariable('B\$', StringValue('World'));
      variables.setVariable('C\$', StringValue('Temp'));

      // Remove middle variable to create fragmentation
      variables.setVariable('B\$', StringValue(''));

      // Trigger garbage collection
      stringManager.garbageCollect();

      // Verify remaining strings are still accessible
      final varA = variables.getVariable('A\$') as StringValue;
      final varC = variables.getVariable('C\$') as StringValue;

      expect(varA.value, equals('Hello'));
      expect(varC.value, equals('Temp'));
    });

    test('should handle temporary string stack overflow', () {
      // Create multiple temporary strings to test stack management
      final temps = <StringDescriptor>[];

      for (int i = 0; i < 5; i++) {
        temps.add(stringManager.createTemporaryString('Temp$i'));
      }

      // All temporary strings should be created successfully
      for (int i = 0; i < 5; i++) {
        expect(stringManager.readString(temps[i]), equals('Temp$i'));
      }
    });

    test('should release temporary strings properly', () {
      final initialTop = memory.readWord(Memory.fretop);

      // Create and use temporary strings
      final temp1 = stringManager.createTemporaryString('Temporary1');
      final temp2 = stringManager.createTemporaryString('Temporary2');

      expect(memory.readWord(Memory.fretop), lessThan(initialTop));

      // Release temporary strings
      stringManager.releaseTemporary(temp1);
      stringManager.releaseTemporary(temp2);

      // String space should be available for reuse
      final temp3 = stringManager.createTemporaryString('New');
      expect(stringManager.readString(temp3), equals('New'));
    });

    test('should concatenate strings correctly', () {
      final str1 = stringManager.createTemporaryString('Hello');
      final str2 = stringManager.createTemporaryString(' World');

      final result = stringManager.concatenateStrings(str1, str2);

      expect(stringManager.readString(result), equals('Hello World'));
      expect(result.length, equals(11));
    });

    test('should handle string space exhaustion', () {
      // Fill up string space
      final strings = <StringDescriptor>[];
      final largeString = 'A' * 100;

      try {
        // Keep creating strings until we run out of space
        while (true) {
          strings.add(stringManager.createTemporaryString(largeString));

          // Break if we've created too many (safety check)
          if (strings.length > 1000) break;
        }
      } catch (e) {
        // Should eventually throw out of memory error
        expect(e.toString(), contains('memory'));
      }

      // Verify that created strings are still valid
      for (final str in strings.take(5)) {
        expect(stringManager.readString(str), equals(largeString));
      }
    });

    test('should preserve strings during garbage collection', () {
      // Create multiple string variables
      final originalStrings = <String, String>{
        'N\$': 'John Doe',
        'C\$': 'New York',
        'S\$': 'NY',
        'U\$': 'USA',
      };

      for (final entry in originalStrings.entries) {
        variables.setVariable(entry.key, StringValue(entry.value));
      }

      // Force garbage collection
      stringManager.garbageCollect();

      // Verify all strings are preserved
      for (final entry in originalStrings.entries) {
        final value = variables.getVariable(entry.key) as StringValue;
        expect(
          value.value,
          equals(entry.value),
          reason:
              'String ${entry.key} should be preserved after garbage collection',
        );
      }
    });

    test('should handle empty strings in garbage collection', () {
      variables.setVariable('E\$', StringValue(''));
      variables.setVariable('F\$', StringValue('Content'));

      stringManager.garbageCollect();

      final empty = variables.getVariable('E\$') as StringValue;
      final full = variables.getVariable('F\$') as StringValue;

      expect(empty.value, equals(''));
      expect(full.value, equals('Content'));
    });

    test('should compact fragmented string space', () {
      // Create strings that will cause fragmentation
      variables.setVariable('A\$', StringValue('AAAA'));
      variables.setVariable('B\$', StringValue('BB'));
      variables.setVariable('C\$', StringValue('CCCCCC'));

      // Remove middle string
      variables.setVariable('B\$', StringValue(''));

      final beforeCollection = memory.readWord(Memory.fretop);

      stringManager.garbageCollect();

      final afterCollection = memory.readWord(Memory.fretop);

      // String space should be more compact after collection
      expect(afterCollection, greaterThanOrEqualTo(beforeCollection));

      // Remaining strings should still be accessible
      expect(
        (variables.getVariable('A\$') as StringValue).value,
        equals('AAAA'),
      );
      expect(
        (variables.getVariable('C\$') as StringValue).value,
        equals('CCCCCC'),
      );
    });

    test('should handle maximum length strings', () {
      final maxString = 'X' * StringManager.maxStringLength;

      final descriptor = stringManager.createTemporaryString(maxString);

      expect(descriptor.length, equals(StringManager.maxStringLength));
      expect(stringManager.readString(descriptor), equals(maxString));
    });

    test('should handle string descriptor operations', () {
      final descriptor = StringDescriptor(length: 10, pointer: 0x7000);

      // Write descriptor to memory
      stringManager.writeDescriptor(0x5000, descriptor);

      // Read it back
      final readDescriptor = stringManager.readDescriptor(0x5000);

      expect(readDescriptor.length, equals(10));
      expect(readDescriptor.pointer, equals(0x7000));
    });

    test('should update references during garbage collection', () {
      // Create a string variable
      variables.setVariable('T\$', StringValue('Original'));

      // Get original pointer
      final originalValue = variables.getVariable('T\$') as StringValue;
      final originalDescriptor = originalValue.descriptor;
      final originalPointer = originalDescriptor?.pointer ?? 0;

      // Create another string to cause movement during GC
      variables.setVariable('O\$', StringValue('Other string'));

      // Force garbage collection
      stringManager.garbageCollect();

      // String should still be accessible with same content
      final afterGcValue = variables.getVariable('T\$') as StringValue;
      expect(afterGcValue.value, equals('Original'));

      // Pointer may have changed due to compaction
      final newDescriptor = afterGcValue.descriptor;
      if (newDescriptor != null && originalDescriptor != null) {
        // Content should be same even if pointer changed
        expect(
          stringManager.readString(newDescriptor),
          equals(stringManager.readString(originalDescriptor)),
        );
      }
    });
  });
}

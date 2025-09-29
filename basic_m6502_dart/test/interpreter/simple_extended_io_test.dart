import 'dart:io';
import 'package:test/test.dart';
import '../../lib/basic_interpreter.dart';

void main() {
  group('Extended I/O Basic Tests', () {
    late BasicInterpreter interpreter;

    setUp(() {
      interpreter = BasicInterpreter();
    });

    test('should compile with Extended I/O features', () {
      // This test just verifies that our code compiles and basic functionality works
      final output = interpreter.executeLine('PRINT "Hello World"');
      expect(output, contains('Hello World'));
    });

    test('should handle OPEN statement syntax', () {
      // Test that OPEN statement doesn't crash with basic syntax
      expect(() {
        interpreter.executeLine('OPEN 1, 3, 0');
      }, returnsNormally);
    });

    test('should handle CLOSE statement syntax', () {
      // Test that CLOSE statement doesn't crash with basic syntax
      expect(() {
        interpreter.executeLine('CLOSE 1');
      }, throwsA(isA<Exception>())); // Should throw FILE NOT OPEN
    });

    test('should handle CMD statement syntax', () {
      // Test that CMD statement doesn't crash with basic syntax
      expect(() {
        interpreter.executeLine('CMD');
      }, returnsNormally);
    });

    test('should handle PRINT# syntax parsing', () {
      // Test that PRINT# is parsed correctly (even if file isn't open)
      expect(() {
        interpreter.executeLine('PRINT#1, "test"');
      }, throwsA(isA<Exception>())); // Should throw FILE NOT OPEN
    });

    test('should handle INPUT# syntax parsing', () {
      // Test that INPUT# is parsed correctly (even if file isn't open)
      expect(() {
        interpreter.executeLine('INPUT#1, A');
      }, throwsA(isA<Exception>())); // Should throw FILE NOT OPEN
    });

    tearDown(() {
      // Clean up any test files that might exist
      final testFiles = ['test.txt'];
      for (final filename in testFiles) {
        final file = File(filename);
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (e) {
            // Ignore cleanup errors
          }
        }
      }
    });
  });
}

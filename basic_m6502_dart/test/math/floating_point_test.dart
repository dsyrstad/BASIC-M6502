import 'package:test/test.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:matcher/matcher.dart';
import '../../lib/math/floating_point.dart';

void main() {
  group('MicrosoftFloat', () {
    test('pack and unpack zero', () {
      final packed = MicrosoftFloat.pack(0.0);
      expect(packed.length, equals(5));
      expect(packed.every((byte) => byte == 0), isTrue);

      final unpacked = MicrosoftFloat.unpack(packed);
      expect(unpacked, equals(0.0));
    });

    test('pack and unpack positive numbers', () {
      final testValues = [1.0, 2.0, 3.14159, 10.0, 100.0, 1000.0];

      for (final value in testValues) {
        final packed = MicrosoftFloat.pack(value);
        final unpacked = MicrosoftFloat.unpack(packed);

        // Allow for some precision loss in conversion
        expect(unpacked, closeTo(value, value * 1e-6));
      }
    });

    test('pack and unpack negative numbers', () {
      final testValues = [-1.0, -2.0, -3.14159, -10.0, -100.0, -1000.0];

      for (final value in testValues) {
        final packed = MicrosoftFloat.pack(value);
        final unpacked = MicrosoftFloat.unpack(packed);

        // Allow for some precision loss in conversion
        expect(unpacked, closeTo(value, value.abs() * 1e-6));
      }
    });

    test('pack and unpack small numbers', () {
      final testValues = [0.1, 0.01, 0.001, 0.0001];

      for (final value in testValues) {
        final packed = MicrosoftFloat.pack(value);
        final unpacked = MicrosoftFloat.unpack(packed);

        // Allow for more precision loss with small numbers
        expect(unpacked, closeTo(value, value * 1e-4));
      }
    });

    test('isZero detection', () {
      final zero = MicrosoftFloat.pack(0.0);
      expect(MicrosoftFloat.isZero(zero), isTrue);

      final nonZero = MicrosoftFloat.pack(1.0);
      expect(MicrosoftFloat.isZero(nonZero), isFalse);
    });

    test('sign detection', () {
      final positive = MicrosoftFloat.pack(1.0);
      expect(MicrosoftFloat.isNegative(positive), isFalse);

      final negative = MicrosoftFloat.pack(-1.0);
      expect(MicrosoftFloat.isNegative(negative), isTrue);

      final zero = MicrosoftFloat.pack(0.0);
      expect(MicrosoftFloat.isNegative(zero), isFalse);
    });

    test('normalization works correctly', () {
      // Create a normalized number
      final normal = MicrosoftFloat.pack(1.0);
      expect(MicrosoftFloat.isNormalized(normal), isTrue);

      final normalized = MicrosoftFloat.normalize(normal);
      // Should return the same bytes since it's already normalized
      expect(normalized, orderedEquals(normal));
    });

    test('normalization of denormalized number', () {
      // Create a manually denormalized number for testing
      final denormalized = Uint8List.fromList([
        128,
        0x20,
        0x00,
        0x00,
        0x00,
      ]); // Exponent 128, no leading bit

      final normalized = MicrosoftFloat.normalize(denormalized);
      expect(MicrosoftFloat.isNormalized(normalized), isTrue);
    });

    test('round-trip conversion accuracy', () {
      // Test round-trip conversion for powers of 2
      for (int i = -10; i <= 10; i++) {
        final value = math.pow(2.0, i).toDouble();
        final packed = MicrosoftFloat.pack(value);
        final unpacked = MicrosoftFloat.unpack(packed);

        // Powers of 2 should convert exactly
        expect(unpacked, equals(value));
      }
    });

    test('format validation', () {
      expect(() => MicrosoftFloat.unpack(Uint8List(4)), throwsArgumentError);
      expect(() => MicrosoftFloat.unpack(Uint8List(6)), throwsArgumentError);
      expect(() => MicrosoftFloat.normalize(Uint8List(4)), throwsArgumentError);
    });

    test('special value handling', () {
      // Test infinity handling
      expect(() => MicrosoftFloat.pack(double.infinity), throwsArgumentError);
      expect(
        () => MicrosoftFloat.pack(double.negativeInfinity),
        throwsArgumentError,
      );
      expect(() => MicrosoftFloat.pack(double.nan), throwsArgumentError);
    });

    test('debug string representation', () {
      final zero = MicrosoftFloat.pack(0.0);
      expect(MicrosoftFloat.toDebugString(zero), contains('Zero'));

      final one = MicrosoftFloat.pack(1.0);
      final debugStr = MicrosoftFloat.toDebugString(one);
      expect(debugStr, contains('Exp:'));
      expect(debugStr, contains('Sign:'));
      expect(debugStr, contains('Mantissa:'));
    });

    test('large numbers near format limits', () {
      // Test numbers near the format limits
      final largeValues = [1e10, 1e20, 1e30];

      for (final value in largeValues) {
        try {
          final packed = MicrosoftFloat.pack(value);
          final unpacked = MicrosoftFloat.unpack(packed);

          // Should be reasonably close
          expect(unpacked, closeTo(value, value * 1e-5));
        } catch (e) {
          // Some very large values may be out of range
          expect(e, isA<ArgumentError>());
        }
      }
    });

    test('very small numbers near format limits', () {
      // Test very small numbers
      final smallValues = [1e-10, 1e-20, 1e-30];

      for (final value in smallValues) {
        try {
          final packed = MicrosoftFloat.pack(value);
          final unpacked = MicrosoftFloat.unpack(packed);

          // Should be reasonably close or zero (underflow)
          if (unpacked != 0.0) {
            expect(unpacked, closeTo(value, value * 1e-3));
          }
        } catch (e) {
          // Some very small values may be out of range
          expect(e, isA<ArgumentError>());
        }
      }
    });
  });
}

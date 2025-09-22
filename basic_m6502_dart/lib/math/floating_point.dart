/// Microsoft BASIC 5-byte floating-point format implementation.
///
/// Format specification (from original source):
/// - 5 bytes total
/// - Byte 0: Exponent (biased by +200, 0 = number is zero)
/// - Byte 1: Sign bit (bit 7) + bits 2-8 of mantissa (bits 6-0)
///   (bit 1 of mantissa is always 1, implied)
/// - Byte 2: Bits 9-16 of mantissa
/// - Byte 3: Bits 17-24 of mantissa
/// - Byte 4: Additional precision byte (usually 0)
///
/// The mantissa is 24 bits with an implied leading 1.
/// Binary point is to the left of the MSB.
/// Number = mantissa * 2^(exponent - 200)

import 'dart:typed_data';
import 'dart:math' as math;

class MicrosoftFloat {
  static const int _bias = 200;
  static const int _mantissaBits = 24;
  static const int _impliedOne = 0x800000; // 2^23

  /// Convert a Dart double to Microsoft 5-byte format
  static Uint8List pack(double value) {
    final bytes = Uint8List(5);

    // Handle special cases
    if (value == 0.0) {
      return bytes; // All zeros for zero value
    }

    // Handle sign
    bool negative = value < 0;
    value = value.abs();

    // Handle special IEEE values
    if (value.isInfinite || value.isNaN) {
      throw ArgumentError('Cannot represent infinity or NaN in Microsoft format');
    }

    // Normalize the value to get mantissa in range [1.0, 2.0)
    int exponent = 0;
    double mantissa = value;

    // Scale up or down to get mantissa in [1.0, 2.0) range
    if (mantissa >= 2.0) {
      // Scale down for large numbers
      while (mantissa >= 2.0) {
        mantissa /= 2.0;
        exponent++;
      }
    } else if (mantissa < 1.0) {
      // Scale up for small numbers
      while (mantissa < 1.0) {
        mantissa *= 2.0;
        exponent--;
      }
    }
    // If mantissa is already in [1.0, 2.0), exponent stays 0

    // Add bias to exponent
    int microsoftExponent = exponent + _bias;

    // Check exponent range
    if (microsoftExponent <= 0 || microsoftExponent > 255) {
      throw ArgumentError('Value out of range for Microsoft float format: $value');
    }

    // Convert mantissa to 23-bit integer (remove implied leading 1)
    // mantissa is in range [1.0, 2.0), so subtract 1.0 and scale by 2^23
    int mantissaInt = ((mantissa - 1.0) * (1 << 23)).round();

    // Handle edge case where mantissa rounds to exactly 2.0
    if (mantissaInt >= (1 << 23)) {
      mantissaInt = 0;
      exponent++;
      microsoftExponent = exponent + _bias;

      // Check exponent range again after adjustment
      if (microsoftExponent <= 0 || microsoftExponent > 255) {
        throw ArgumentError('Value out of range for Microsoft float format: $value');
      }
    }

    // Pack into bytes
    bytes[0] = microsoftExponent;

    // Byte 1: Sign bit + bits 16-22 of mantissa (top 7 bits)
    int byte1 = (mantissaInt >> 16) & 0x7F;
    if (negative) {
      byte1 |= 0x80; // Set sign bit
    }
    bytes[1] = byte1;

    // Byte 2: Bits 8-15 of mantissa
    bytes[2] = (mantissaInt >> 8) & 0xFF;

    // Byte 3: Bits 0-7 of mantissa (bottom 8 bits)
    bytes[3] = mantissaInt & 0xFF;

    // Byte 4: Additional precision (usually 0)
    bytes[4] = 0;

    return bytes;
  }

  /// Convert Microsoft 5-byte format to Dart double
  static double unpack(Uint8List bytes) {
    if (bytes.length != 5) {
      throw ArgumentError('Microsoft float must be exactly 5 bytes');
    }

    int exponent = bytes[0];

    // Check for zero
    if (exponent == 0) {
      return 0.0;
    }

    // Extract sign
    bool negative = (bytes[1] & 0x80) != 0;

    // Extract mantissa parts
    int mantissaHigh = bytes[1] & 0x7F; // Top 7 bits of mantissa
    int mantissaMid = bytes[2];         // Middle 8 bits of mantissa
    int mantissaLow = bytes[3];         // Bottom 8 bits of mantissa

    // Reconstruct 23-bit mantissa and add implied leading 1
    int mantissaInt = (mantissaHigh << 16) | (mantissaMid << 8) | mantissaLow;
    double mantissa = 1.0 + mantissaInt.toDouble() / (1 << 23);

    // Apply exponent (subtract bias)
    double result = mantissa * math.pow(2.0, exponent - _bias);

    return negative ? -result : result;
  }

  /// Normalize a floating-point value in Microsoft format
  static Uint8List normalize(Uint8List bytes) {
    if (bytes.length != 5) {
      throw ArgumentError('Microsoft float must be exactly 5 bytes');
    }

    // In Microsoft format, numbers are already normalized by design
    // when created through pack(). If exponent is non-zero, it's normalized.
    // If exponent is zero, it represents the value zero.
    return Uint8List.fromList(bytes);
  }

  /// Check if a Microsoft float represents zero
  static bool isZero(Uint8List bytes) {
    return bytes[0] == 0;
  }

  /// Check if a Microsoft float is normalized
  static bool isNormalized(Uint8List bytes) {
    if (bytes[0] == 0) return true; // Zero is considered normalized

    // For Microsoft format, if we have a non-zero exponent, the number is normalized
    // because we always store the mantissa without the leading 1 bit
    return true;
  }

  /// Get the sign of a Microsoft float
  static bool isNegative(Uint8List bytes) {
    return (bytes[1] & 0x80) != 0;
  }

  /// Count leading zeros in a number (utility function)
  static int _countLeadingZeros(int value, int bitCount) {
    if (value == 0) return bitCount;

    int count = 0;
    int mask = 1 << (bitCount - 1);

    while ((value & mask) == 0 && count < bitCount) {
      count++;
      mask >>= 1;
    }

    return count;
  }

  /// Convert Microsoft float to string representation (for debugging)
  static String toDebugString(Uint8List bytes) {
    if (bytes.length != 5) return 'Invalid length';

    if (bytes[0] == 0) return 'Zero';

    int exponent = bytes[0];
    bool negative = (bytes[1] & 0x80) != 0;
    int mantissaHigh = bytes[1] & 0x7F;
    int mantissaMid = bytes[2];
    int mantissaLow = bytes[3];

    return 'Exp: $exponent, Sign: ${negative ? "-" : "+"}, '
           'Mantissa: ${mantissaHigh.toRadixString(16).padLeft(2, '0')}'
           '${mantissaMid.toRadixString(16).padLeft(2, '0')}'
           '${mantissaLow.toRadixString(16).padLeft(2, '0')}';
  }
}
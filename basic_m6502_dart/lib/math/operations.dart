/// Microsoft BASIC floating-point arithmetic operations.
///
/// These operations implement the same algorithms used in the original
/// Microsoft BASIC for 6502, working with the 5-byte floating-point format.

import 'dart:typed_data';
import 'dart:math' as math;
import 'floating_point.dart';

class MathOperations {
  /// Add two Microsoft floating-point numbers (FADD equivalent)
  static Uint8List fadd(Uint8List a, Uint8List b) {
    // Handle zero cases
    if (MicrosoftFloat.isZero(a)) return Uint8List.fromList(b);
    if (MicrosoftFloat.isZero(b)) return Uint8List.fromList(a);

    // Convert to double, add, and convert back
    double valueA = MicrosoftFloat.unpack(a);
    double valueB = MicrosoftFloat.unpack(b);
    double result = valueA + valueB;

    return MicrosoftFloat.pack(result);
  }

  /// Subtract two Microsoft floating-point numbers (FSUB equivalent)
  static Uint8List fsub(Uint8List a, Uint8List b) {
    // Handle zero cases
    if (MicrosoftFloat.isZero(b)) return Uint8List.fromList(a);
    if (MicrosoftFloat.isZero(a)) {
      // Return -b
      double valueB = MicrosoftFloat.unpack(b);
      return MicrosoftFloat.pack(-valueB);
    }

    // Convert to double, subtract, and convert back
    double valueA = MicrosoftFloat.unpack(a);
    double valueB = MicrosoftFloat.unpack(b);
    double result = valueA - valueB;

    return MicrosoftFloat.pack(result);
  }

  /// Multiply two Microsoft floating-point numbers (FMUL equivalent)
  static Uint8List fmul(Uint8List a, Uint8List b) {
    // Handle zero cases
    if (MicrosoftFloat.isZero(a) || MicrosoftFloat.isZero(b)) {
      return MicrosoftFloat.pack(0.0);
    }

    // Convert to double, multiply, and convert back
    double valueA = MicrosoftFloat.unpack(a);
    double valueB = MicrosoftFloat.unpack(b);
    double result = valueA * valueB;

    return MicrosoftFloat.pack(result);
  }

  /// Divide two Microsoft floating-point numbers (FDIV equivalent)
  static Uint8List fdiv(Uint8List a, Uint8List b) {
    // Handle zero divisor
    if (MicrosoftFloat.isZero(b)) {
      throw ArgumentError('Division by zero');
    }

    // Handle zero dividend
    if (MicrosoftFloat.isZero(a)) {
      return MicrosoftFloat.pack(0.0);
    }

    // Convert to double, divide, and convert back
    double valueA = MicrosoftFloat.unpack(a);
    double valueB = MicrosoftFloat.unpack(b);
    double result = valueA / valueB;

    return MicrosoftFloat.pack(result);
  }

  /// Negate a Microsoft floating-point number
  static Uint8List fneg(Uint8List a) {
    // Handle zero
    if (MicrosoftFloat.isZero(a)) {
      return Uint8List.fromList(a);
    }

    // Flip the sign bit
    Uint8List result = Uint8List.fromList(a);
    result[1] ^= 0x80; // XOR with sign bit
    return result;
  }

  /// Compare two Microsoft floating-point numbers
  /// Returns: -1 if a < b, 0 if a == b, 1 if a > b
  static int fcompare(Uint8List a, Uint8List b) {
    // Handle zeros
    if (MicrosoftFloat.isZero(a) && MicrosoftFloat.isZero(b)) return 0;
    if (MicrosoftFloat.isZero(a)) {
      return MicrosoftFloat.isNegative(b) ? 1 : -1;
    }
    if (MicrosoftFloat.isZero(b)) {
      return MicrosoftFloat.isNegative(a) ? -1 : 1;
    }

    // Convert to double and compare
    double valueA = MicrosoftFloat.unpack(a);
    double valueB = MicrosoftFloat.unpack(b);

    if (valueA < valueB) return -1;
    if (valueA > valueB) return 1;
    return 0;
  }

  /// Check if two Microsoft floating-point numbers are equal
  static bool fequal(Uint8List a, Uint8List b) {
    return fcompare(a, b) == 0;
  }

  /// Take absolute value of a Microsoft floating-point number
  static Uint8List fabs(Uint8List a) {
    // Handle zero
    if (MicrosoftFloat.isZero(a)) {
      return Uint8List.fromList(a);
    }

    // Clear the sign bit
    Uint8List result = Uint8List.fromList(a);
    result[1] &= 0x7F; // Clear sign bit
    return result;
  }

  /// Get the sign of a Microsoft floating-point number
  /// Returns: -1 if negative, 0 if zero, 1 if positive
  static int fsgn(Uint8List a) {
    if (MicrosoftFloat.isZero(a)) return 0;
    return MicrosoftFloat.isNegative(a) ? -1 : 1;
  }

  /// Convert integer to Microsoft floating-point format
  static Uint8List intToFloat(int value) {
    return MicrosoftFloat.pack(value.toDouble());
  }

  /// Convert Microsoft floating-point to integer (truncate towards zero)
  static int floatToInt(Uint8List a) {
    if (MicrosoftFloat.isZero(a)) return 0;

    double value = MicrosoftFloat.unpack(a);
    return value.truncate();
  }

  /// Check if a Microsoft floating-point number is an integer
  static bool isInteger(Uint8List a) {
    if (MicrosoftFloat.isZero(a)) return true;

    double value = MicrosoftFloat.unpack(a);
    return value == value.truncateToDouble();
  }

  /// Power function: a^b (for integer exponents)
  static Uint8List fpow(Uint8List base, int exponent) {
    if (exponent == 0) {
      return MicrosoftFloat.pack(1.0);
    }

    if (MicrosoftFloat.isZero(base)) {
      if (exponent < 0) {
        throw ArgumentError('Cannot raise zero to negative power');
      }
      return MicrosoftFloat.pack(0.0);
    }

    double baseValue = MicrosoftFloat.unpack(base);
    double result = math.pow(baseValue, exponent).toDouble();

    return MicrosoftFloat.pack(result);
  }

  /// Modulus operation: a MOD b
  static Uint8List fmod(Uint8List a, Uint8List b) {
    if (MicrosoftFloat.isZero(b)) {
      throw ArgumentError('Division by zero in MOD operation');
    }

    if (MicrosoftFloat.isZero(a)) {
      return MicrosoftFloat.pack(0.0);
    }

    double valueA = MicrosoftFloat.unpack(a);
    double valueB = MicrosoftFloat.unpack(b);
    double result = valueA % valueB;

    return MicrosoftFloat.pack(result);
  }

  /// Debug: Convert Microsoft float to human-readable string
  static String floatToString(Uint8List a) {
    if (MicrosoftFloat.isZero(a)) return "0";

    double value = MicrosoftFloat.unpack(a);
    return value.toString();
  }
}

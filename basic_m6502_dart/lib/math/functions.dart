/// Microsoft BASIC transcendental and utility math functions.
///
/// These functions implement the same mathematical operations available
/// in the original Microsoft BASIC for 6502.

import 'dart:typed_data';
import 'dart:math' as math;
import 'floating_point.dart';
import 'operations.dart';

class MathFunctions {
  static math.Random _random = math.Random();

  /// Sine function (SIN)
  static Uint8List sin(Uint8List angle) {
    if (MicrosoftFloat.isZero(angle)) {
      return MicrosoftFloat.pack(0.0);
    }

    double angleValue = MicrosoftFloat.unpack(angle);
    double result = math.sin(angleValue);
    return MicrosoftFloat.pack(result);
  }

  /// Cosine function (COS)
  static Uint8List cos(Uint8List angle) {
    double angleValue = MicrosoftFloat.unpack(angle);
    double result = math.cos(angleValue);
    return MicrosoftFloat.pack(result);
  }

  /// Tangent function (TAN)
  static Uint8List tan(Uint8List angle) {
    double angleValue = MicrosoftFloat.unpack(angle);
    double result = math.tan(angleValue);
    return MicrosoftFloat.pack(result);
  }

  /// Arctangent function (ATN)
  static Uint8List atn(Uint8List value) {
    double val = MicrosoftFloat.unpack(value);
    double result = math.atan(val);
    return MicrosoftFloat.pack(result);
  }

  /// Natural logarithm function (LOG)
  static Uint8List log(Uint8List value) {
    if (MicrosoftFloat.isZero(value) || MicrosoftFloat.isNegative(value)) {
      throw ArgumentError('Logarithm of zero or negative number');
    }

    double val = MicrosoftFloat.unpack(value);
    double result = math.log(val);
    return MicrosoftFloat.pack(result);
  }

  /// Exponential function (EXP)
  static Uint8List exp(Uint8List value) {
    double val = MicrosoftFloat.unpack(value);
    double result = math.exp(val);
    return MicrosoftFloat.pack(result);
  }

  /// Square root function (SQR)
  static Uint8List sqr(Uint8List value) {
    if (MicrosoftFloat.isNegative(value)) {
      throw ArgumentError('Square root of negative number');
    }

    if (MicrosoftFloat.isZero(value)) {
      return MicrosoftFloat.pack(0.0);
    }

    double val = MicrosoftFloat.unpack(value);
    double result = math.sqrt(val);
    return MicrosoftFloat.pack(result);
  }

  /// Random number function (RND)
  /// Returns a random number between 0 and 1
  static Uint8List rnd([Uint8List? seed]) {
    if (seed != null) {
      // If seed is provided, use it to seed the random number generator
      var seedValue = MathOperations.floatToInt(seed);
      if (seedValue < 0) {
        // Negative seed resets the generator
        _random = math.Random(seedValue.abs());
      } else if (seedValue == 0) {
        // Zero seed means use current time
        _random = math.Random(DateTime.now().millisecondsSinceEpoch);
      } else {
        // Positive seed sets a specific seed
        _random = math.Random(seedValue);
      }
    }

    double result = _random.nextDouble();
    return MicrosoftFloat.pack(result);
  }

  /// Integer function (INT) - returns largest integer <= value
  static Uint8List int(Uint8List value) {
    if (MicrosoftFloat.isZero(value)) {
      return MicrosoftFloat.pack(0.0);
    }

    double val = MicrosoftFloat.unpack(value);
    double result = val.floorToDouble();
    return MicrosoftFloat.pack(result);
  }

  /// Absolute value function (ABS)
  static Uint8List abs(Uint8List value) {
    return MathOperations.fabs(value);
  }

  /// Sign function (SGN)
  /// Returns -1, 0, or 1 depending on the sign of the value
  static Uint8List sgn(Uint8List value) {
    var sign = MathOperations.fsgn(value);
    return MicrosoftFloat.pack(sign.toDouble());
  }

  /// Fix function (FIX) - truncates towards zero (same as INT for positive numbers)
  static Uint8List fix(Uint8List value) {
    if (MicrosoftFloat.isZero(value)) {
      return MicrosoftFloat.pack(0.0);
    }

    double val = MicrosoftFloat.unpack(value);
    double result = val.truncateToDouble();
    return MicrosoftFloat.pack(result);
  }

  /// Power function using floating-point exponent (^)
  static Uint8List pow(Uint8List base, Uint8List exponent) {
    double baseVal = MicrosoftFloat.unpack(base);
    double expVal = MicrosoftFloat.unpack(exponent);

    // Handle special cases
    if (MicrosoftFloat.isZero(exponent)) {
      return MicrosoftFloat.pack(1.0); // Anything to the 0 power is 1
    }

    if (MicrosoftFloat.isZero(base)) {
      if (expVal < 0) {
        throw ArgumentError('Cannot raise zero to negative power');
      }
      return MicrosoftFloat.pack(0.0);
    }

    double result = math.pow(baseVal, expVal).toDouble();
    return MicrosoftFloat.pack(result);
  }

  /// Fraction function (FRAC) - returns fractional part of a number
  static Uint8List frac(Uint8List value) {
    if (MicrosoftFloat.isZero(value)) {
      return MicrosoftFloat.pack(0.0);
    }

    double val = MicrosoftFloat.unpack(value);
    double intPart = val.truncateToDouble();
    double fracPart = val - intPart;
    return MicrosoftFloat.pack(fracPart);
  }

  /// Round function (ROUND) - rounds to nearest integer
  static Uint8List round(Uint8List value) {
    if (MicrosoftFloat.isZero(value)) {
      return MicrosoftFloat.pack(0.0);
    }

    double val = MicrosoftFloat.unpack(value);
    double result = val.roundToDouble();
    return MicrosoftFloat.pack(result);
  }

  /// Degrees to radians conversion
  static Uint8List degToRad(Uint8List degrees) {
    double deg = MicrosoftFloat.unpack(degrees);
    double rad = deg * math.pi / 180.0;
    return MicrosoftFloat.pack(rad);
  }

  /// Radians to degrees conversion
  static Uint8List radToDeg(Uint8List radians) {
    double rad = MicrosoftFloat.unpack(radians);
    double deg = rad * 180.0 / math.pi;
    return MicrosoftFloat.pack(deg);
  }

  /// Pi constant
  static Uint8List pi() {
    return MicrosoftFloat.pack(math.pi);
  }

  /// E constant (Euler's number)
  static Uint8List e() {
    return MicrosoftFloat.pack(math.e);
  }

  /// Maximum of two values
  static Uint8List max(Uint8List a, Uint8List b) {
    var comparison = MathOperations.fcompare(a, b);
    return comparison >= 0 ? Uint8List.fromList(a) : Uint8List.fromList(b);
  }

  /// Minimum of two values
  static Uint8List min(Uint8List a, Uint8List b) {
    var comparison = MathOperations.fcompare(a, b);
    return comparison <= 0 ? Uint8List.fromList(a) : Uint8List.fromList(b);
  }

  /// Hyperbolic sine (SINH)
  static Uint8List sinh(Uint8List value) {
    double val = MicrosoftFloat.unpack(value);
    double result = (math.exp(val) - math.exp(-val)) / 2.0;
    return MicrosoftFloat.pack(result);
  }

  /// Hyperbolic cosine (COSH)
  static Uint8List cosh(Uint8List value) {
    double val = MicrosoftFloat.unpack(value);
    double result = (math.exp(val) + math.exp(-val)) / 2.0;
    return MicrosoftFloat.pack(result);
  }

  /// Hyperbolic tangent (TANH)
  static Uint8List tanh(Uint8List value) {
    double val = MicrosoftFloat.unpack(value);
    double expPos = math.exp(val);
    double expNeg = math.exp(-val);
    double result = (expPos - expNeg) / (expPos + expNeg);
    return MicrosoftFloat.pack(result);
  }

  /// Base-10 logarithm (LOG10)
  static Uint8List log10(Uint8List value) {
    if (MicrosoftFloat.isZero(value) || MicrosoftFloat.isNegative(value)) {
      throw ArgumentError('Logarithm of zero or negative number');
    }

    double val = MicrosoftFloat.unpack(value);
    double result = math.log(val) / math.ln10;
    return MicrosoftFloat.pack(result);
  }

  /// Power of 10 (10^x)
  static Uint8List exp10(Uint8List value) {
    double val = MicrosoftFloat.unpack(value);
    double result = math.pow(10.0, val).toDouble();
    return MicrosoftFloat.pack(result);
  }
}
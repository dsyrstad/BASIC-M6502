/// Number conversion functions for Microsoft BASIC.
///
/// Implements:
/// - FIN: Convert string to floating-point (like VAL)
/// - FOUT: Convert floating-point to string (like STR$)
/// - STR$: Convert number to string representation
/// - VAL: Convert string to number
///
/// Based on the original Microsoft BASIC 6502 implementation.

import 'dart:typed_data';
import 'dart:math' as math;
import '../memory/strings.dart';
import 'floating_point.dart';

class NumberConversions {
  /// Convert string to floating-point number (FIN routine)
  /// Equivalent to VAL function in BASIC
  static Uint8List stringToFloat(String input) {
    if (input.isEmpty) {
      return MicrosoftFloat.pack(0.0);
    }

    // Trim leading whitespace
    String trimmed = input.trimLeft();
    if (trimmed.isEmpty) {
      return MicrosoftFloat.pack(0.0);
    }

    // Parse sign
    bool negative = false;
    int pos = 0;
    if (trimmed[pos] == '+') {
      pos++;
    } else if (trimmed[pos] == '-') {
      negative = true;
      pos++;
    }

    double result = 0.0;
    bool hasDigits = false;
    bool hasDecimalPoint = false;
    int decimalPlaces = 0;

    // Parse integer part
    while (pos < trimmed.length && _isDigit(trimmed[pos])) {
      result = result * 10.0 + (trimmed.codeUnitAt(pos) - 48);
      hasDigits = true;
      pos++;
    }

    // Parse decimal point and fractional part
    if (pos < trimmed.length && trimmed[pos] == '.') {
      hasDecimalPoint = true;
      pos++;

      while (pos < trimmed.length && _isDigit(trimmed[pos])) {
        result = result * 10.0 + (trimmed.codeUnitAt(pos) - 48);
        decimalPlaces++;
        hasDigits = true;
        pos++;
      }
    }

    // If no digits found, return zero
    if (!hasDigits) {
      return MicrosoftFloat.pack(0.0);
    }

    // Apply decimal scaling
    if (decimalPlaces > 0) {
      result /= math.pow(10.0, decimalPlaces);
    }

    // Parse exponent
    if (pos < trimmed.length && (trimmed[pos] == 'E' || trimmed[pos] == 'e')) {
      pos++;

      // Parse exponent sign
      bool expNegative = false;
      if (pos < trimmed.length) {
        if (trimmed[pos] == '+') {
          pos++;
        } else if (trimmed[pos] == '-') {
          expNegative = true;
          pos++;
        }
      }

      // Parse exponent digits
      int exponent = 0;
      bool hasExpDigits = false;
      while (pos < trimmed.length && _isDigit(trimmed[pos])) {
        exponent = exponent * 10 + (trimmed.codeUnitAt(pos) - 48);
        hasExpDigits = true;
        pos++;
      }

      // Apply exponent if valid
      if (hasExpDigits) {
        if (expNegative) {
          exponent = -exponent;
        }
        result *= math.pow(10.0, exponent);
      }
    }

    // Apply sign
    if (negative) {
      result = -result;
    }

    return MicrosoftFloat.pack(result);
  }

  /// Convert floating-point number to string (FOUT routine)
  /// Equivalent to STR$ function in BASIC
  static String floatToString(Uint8List floatBytes) {
    double value = MicrosoftFloat.unpack(floatBytes);

    // Handle zero
    if (value == 0.0) {
      return ' 0';
    }

    // Determine if we need scientific notation
    double absValue = value.abs();
    bool useScientific = absValue >= 1e9 || (absValue > 0 && absValue < 1e-4);

    String result;
    if (useScientific) {
      result = _formatScientific(value);
    } else {
      result = _formatFixed(value);
    }

    // Add leading space for positive numbers (Microsoft BASIC convention)
    if (value >= 0 && !result.startsWith(' ')) {
      result = ' $result';
    }

    return result;
  }

  /// STR$ function - convert number to string
  static StringDescriptor str(
    Uint8List floatBytes,
    StringManager stringManager,
  ) {
    String result = floatToString(floatBytes);
    return stringManager.createTemporaryString(result);
  }

  /// VAL function - convert string to number
  static Uint8List val(
    StringDescriptor stringDesc,
    StringManager stringManager,
  ) {
    String input = stringManager.readString(stringDesc);
    return stringToFloat(input);
  }

  /// Helper function to check if character is a digit
  static bool _isDigit(String char) {
    int code = char.codeUnitAt(0);
    return code >= 48 && code <= 57; // '0' to '9'
  }

  /// Format number in fixed-point notation
  static String _formatFixed(double value) {
    // Round to reasonable precision to avoid floating-point artifacts
    double rounded = _roundToPrecision(value, 6);

    if (rounded == rounded.truncateToDouble()) {
      // Integer value - no decimal point needed
      return rounded.truncate().toString();
    } else {
      // Format with appropriate decimal places
      String result = rounded.toString();

      // Remove trailing zeros after decimal point
      if (result.contains('.')) {
        result = result.replaceAll(RegExp(r'0+$'), '');
        if (result.endsWith('.')) {
          result = result.substring(0, result.length - 1);
        }
      }

      return result;
    }
  }

  /// Format number in scientific notation
  static String _formatScientific(double value) {
    if (value == 0.0) return '0';

    bool negative = value < 0;
    value = value.abs();

    // Find the exponent
    int exponent = 0;
    double mantissa = value;

    if (mantissa >= 10.0) {
      while (mantissa >= 10.0) {
        mantissa /= 10.0;
        exponent++;
      }
    } else if (mantissa < 1.0) {
      while (mantissa < 1.0) {
        mantissa *= 10.0;
        exponent--;
      }
    }

    // Round mantissa to 6 significant digits
    mantissa = _roundToPrecision(mantissa, 6);

    // Handle case where rounding pushes mantissa to 10
    if (mantissa >= 10.0) {
      mantissa /= 10.0;
      exponent++;
    }

    // Format mantissa
    String mantissaStr = _formatFixed(mantissa);
    if (negative) {
      mantissaStr = '-$mantissaStr';
    }

    // Format exponent
    String expStr = exponent >= 0
        ? '+${exponent.toString().padLeft(2, '0')}'
        : '-${(-exponent).toString().padLeft(2, '0')}';

    return '${mantissaStr}E$expStr';
  }

  /// Round a number to specified number of significant digits
  static double _roundToPrecision(double value, int precision) {
    if (value == 0.0) return 0.0;

    double factor = math
        .pow(10.0, precision - (math.log(value.abs()) / math.ln10).floor() - 1)
        .toDouble();
    return (value * factor).round() / factor;
  }

  /// Parse a number from a string, handling Microsoft BASIC format
  /// Used internally by FIN
  static double _parseNumber(String input) {
    try {
      return double.parse(input);
    } catch (e) {
      return 0.0; // Microsoft BASIC returns 0 for invalid numbers
    }
  }

  /// Convert integer to floating-point format
  static Uint8List integerToFloat(int value) {
    return MicrosoftFloat.pack(value.toDouble());
  }

  /// Convert floating-point to integer (truncate)
  static int floatToInteger(Uint8List floatBytes) {
    double value = MicrosoftFloat.unpack(floatBytes);
    return value.truncate();
  }

  /// Check if a string represents a valid number
  static bool isValidNumber(String input) {
    if (input.isEmpty) return false;

    String trimmed = input.trim();
    if (trimmed.isEmpty) return false;

    // Try to parse using our FIN routine
    try {
      Uint8List result = stringToFloat(trimmed);
      return !MicrosoftFloat.isZero(result) || trimmed.contains('0');
    } catch (e) {
      return false;
    }
  }

  /// Format number with specified width (for PRINT USING if implemented)
  static String formatWithWidth(Uint8List floatBytes, int width) {
    String result = floatToString(floatBytes);

    if (result.length >= width) {
      return result;
    }

    // Pad with spaces on the left
    return result.padLeft(width);
  }

  /// Convert a number to its absolute value
  static Uint8List abs(Uint8List floatBytes) {
    double value = MicrosoftFloat.unpack(floatBytes);
    return MicrosoftFloat.pack(value.abs());
  }

  /// Get the sign of a number (-1, 0, or 1)
  static int sign(Uint8List floatBytes) {
    double value = MicrosoftFloat.unpack(floatBytes);
    if (value > 0) return 1;
    if (value < 0) return -1;
    return 0;
  }
}

import 'package:test/test.dart';
import 'dart:typed_data';
import '../../lib/math/conversions.dart';
import '../../lib/math/floating_point.dart';
import '../../lib/memory/strings.dart';
import '../../lib/memory/memory.dart';

void main() {
  group('NumberConversions', () {
    late Memory memory;
    late StringManager stringManager;

    setUp(() {
      // Initialize memory and string manager for each test
      memory = Memory();
      stringManager = StringManager(memory);
      stringManager.initialize(0xFFFF);
    });

    group('stringToFloat (FIN)', () {
      test('converts simple integers', () {
        var result = NumberConversions.stringToFloat('42');
        expect(MicrosoftFloat.unpack(result), closeTo(42.0, 0.001));

        result = NumberConversions.stringToFloat('0');
        expect(MicrosoftFloat.unpack(result), equals(0.0));

        result = NumberConversions.stringToFloat('123');
        expect(MicrosoftFloat.unpack(result), closeTo(123.0, 0.001));
      });

      test('handles negative numbers', () {
        var result = NumberConversions.stringToFloat('-42');
        expect(MicrosoftFloat.unpack(result), closeTo(-42.0, 0.001));

        result = NumberConversions.stringToFloat('-0');
        expect(MicrosoftFloat.unpack(result), equals(0.0));
      });

      test('handles positive sign', () {
        var result = NumberConversions.stringToFloat('+42');
        expect(MicrosoftFloat.unpack(result), closeTo(42.0, 0.001));

        result = NumberConversions.stringToFloat('+123.45');
        expect(MicrosoftFloat.unpack(result), closeTo(123.45, 0.001));
      });

      test('converts decimal numbers', () {
        var result = NumberConversions.stringToFloat('123.45');
        expect(MicrosoftFloat.unpack(result), closeTo(123.45, 0.001));

        result = NumberConversions.stringToFloat('0.5');
        expect(MicrosoftFloat.unpack(result), closeTo(0.5, 0.001));

        result = NumberConversions.stringToFloat('.25');
        expect(MicrosoftFloat.unpack(result), closeTo(0.25, 0.001));
      });

      test('handles scientific notation', () {
        var result = NumberConversions.stringToFloat('1.23E2');
        expect(MicrosoftFloat.unpack(result), closeTo(123.0, 0.001));

        result = NumberConversions.stringToFloat('1.5E-2');
        expect(MicrosoftFloat.unpack(result), closeTo(0.015, 0.001));

        result = NumberConversions.stringToFloat('2E3');
        expect(MicrosoftFloat.unpack(result), closeTo(2000.0, 0.001));
      });

      test('handles leading whitespace', () {
        var result = NumberConversions.stringToFloat('  42');
        expect(MicrosoftFloat.unpack(result), closeTo(42.0, 0.001));

        result = NumberConversions.stringToFloat('\t123.45');
        expect(MicrosoftFloat.unpack(result), closeTo(123.45, 0.001));
      });

      test('stops at first invalid character', () {
        var result = NumberConversions.stringToFloat('42ABC');
        expect(MicrosoftFloat.unpack(result), closeTo(42.0, 0.001));

        result = NumberConversions.stringToFloat('123.45XYZ');
        expect(MicrosoftFloat.unpack(result), closeTo(123.45, 0.001));
      });

      test('returns zero for invalid input', () {
        var result = NumberConversions.stringToFloat('');
        expect(MicrosoftFloat.unpack(result), equals(0.0));

        result = NumberConversions.stringToFloat('   ');
        expect(MicrosoftFloat.unpack(result), equals(0.0));

        result = NumberConversions.stringToFloat('ABC');
        expect(MicrosoftFloat.unpack(result), equals(0.0));
      });
    });

    group('floatToString (FOUT)', () {
      test('converts simple integers', () {
        var floatBytes = MicrosoftFloat.pack(42.0);
        var result = NumberConversions.floatToString(floatBytes);
        expect(result, equals(' 42'));

        floatBytes = MicrosoftFloat.pack(0.0);
        result = NumberConversions.floatToString(floatBytes);
        expect(result, equals(' 0'));
      });

      test('handles negative numbers', () {
        var floatBytes = MicrosoftFloat.pack(-42.0);
        var result = NumberConversions.floatToString(floatBytes);
        expect(result, equals('-42'));

        floatBytes = MicrosoftFloat.pack(-123.45);
        result = NumberConversions.floatToString(floatBytes);
        expect(result, startsWith('-123.45'));
      });

      test('converts decimal numbers', () {
        var floatBytes = MicrosoftFloat.pack(123.45);
        var result = NumberConversions.floatToString(floatBytes);
        expect(result, startsWith(' 123.45'));

        floatBytes = MicrosoftFloat.pack(0.5);
        result = NumberConversions.floatToString(floatBytes);
        expect(result, equals(' 0.5'));
      });

      test('uses scientific notation for large numbers', () {
        var floatBytes = MicrosoftFloat.pack(1000000000.0);
        var result = NumberConversions.floatToString(floatBytes);
        expect(result, contains('E'));

        floatBytes = MicrosoftFloat.pack(0.0001);
        result = NumberConversions.floatToString(floatBytes);
        expect(result, contains('E'));
      });

      test('removes trailing zeros', () {
        var floatBytes = MicrosoftFloat.pack(123.0);
        var result = NumberConversions.floatToString(floatBytes);
        expect(result, equals(' 123'));

        floatBytes = MicrosoftFloat.pack(1.5);
        result = NumberConversions.floatToString(floatBytes);
        expect(result, equals(' 1.5'));
      });
    });

    group('STR\$ function', () {
      test('converts number to string descriptor', () {
        var floatBytes = MicrosoftFloat.pack(42.0);
        var stringDesc = NumberConversions.str(floatBytes, stringManager);
        var result = stringManager.readString(stringDesc);
        expect(result, equals(' 42'));
      });

      test('handles negative numbers', () {
        var floatBytes = MicrosoftFloat.pack(-123.45);
        var stringDesc = NumberConversions.str(floatBytes, stringManager);
        var result = stringManager.readString(stringDesc);
        expect(result, startsWith('-123.45'));
      });
    });

    group('VAL function', () {
      test('converts string descriptor to number', () {
        var stringDesc = stringManager.createTemporaryString('42');
        var result = NumberConversions.val(stringDesc, stringManager);
        expect(MicrosoftFloat.unpack(result), closeTo(42.0, 0.001));
      });

      test('handles decimal strings', () {
        var stringDesc = stringManager.createTemporaryString('123.45');
        var result = NumberConversions.val(stringDesc, stringManager);
        expect(MicrosoftFloat.unpack(result), closeTo(123.45, 0.001));
      });

      test('handles negative strings', () {
        var stringDesc = stringManager.createTemporaryString('-42');
        var result = NumberConversions.val(stringDesc, stringManager);
        expect(MicrosoftFloat.unpack(result), closeTo(-42.0, 0.001));
      });
    });

    group('utility functions', () {
      test('integerToFloat converts integers', () {
        var result = NumberConversions.integerToFloat(42);
        expect(MicrosoftFloat.unpack(result), equals(42.0));

        result = NumberConversions.integerToFloat(-123);
        expect(MicrosoftFloat.unpack(result), equals(-123.0));
      });

      test('floatToInteger truncates decimals', () {
        var floatBytes = MicrosoftFloat.pack(42.7);
        var result = NumberConversions.floatToInteger(floatBytes);
        expect(result, equals(42));

        floatBytes = MicrosoftFloat.pack(-123.9);
        result = NumberConversions.floatToInteger(floatBytes);
        expect(result, equals(-123));
      });

      test('isValidNumber checks string validity', () {
        expect(NumberConversions.isValidNumber('42'), isTrue);
        expect(NumberConversions.isValidNumber('123.45'), isTrue);
        expect(NumberConversions.isValidNumber('-42'), isTrue);
        expect(NumberConversions.isValidNumber('1.23E2'), isTrue);
        expect(NumberConversions.isValidNumber(''), isFalse);
        expect(NumberConversions.isValidNumber('   '), isFalse);
        expect(NumberConversions.isValidNumber('ABC'), isFalse);
      });

      test('abs returns absolute value', () {
        var floatBytes = MicrosoftFloat.pack(-42.0);
        var result = NumberConversions.abs(floatBytes);
        expect(MicrosoftFloat.unpack(result), equals(42.0));

        floatBytes = MicrosoftFloat.pack(123.0);
        result = NumberConversions.abs(floatBytes);
        expect(MicrosoftFloat.unpack(result), equals(123.0));
      });

      test('sign returns correct sign', () {
        var floatBytes = MicrosoftFloat.pack(42.0);
        expect(NumberConversions.sign(floatBytes), equals(1));

        floatBytes = MicrosoftFloat.pack(-42.0);
        expect(NumberConversions.sign(floatBytes), equals(-1));

        floatBytes = MicrosoftFloat.pack(0.0);
        expect(NumberConversions.sign(floatBytes), equals(0));
      });

      test('formatWithWidth pads numbers', () {
        var floatBytes = MicrosoftFloat.pack(42.0);
        var result = NumberConversions.formatWithWidth(floatBytes, 10);
        expect(result.length, equals(10));
        expect(result.trim(), equals('42'));
      });
    });

    group('edge cases', () {
      test('handles very small numbers', () {
        var result = NumberConversions.stringToFloat('1E-20');
        var converted = MicrosoftFloat.unpack(result);
        expect(converted, greaterThan(0.0));
        expect(converted, lessThan(1E-19));
      });

      test('handles very large numbers', () {
        var result = NumberConversions.stringToFloat('1E10');
        var converted = MicrosoftFloat.unpack(result);
        expect(converted, greaterThan(1E9));
      });

      test('round-trip conversion preserves values', () {
        var testValues = [0.0, 1.0, -1.0, 123.45, -123.45, 1.23E6, 1.23E-6];

        for (var value in testValues) {
          var floatBytes = MicrosoftFloat.pack(value);
          var stringResult = NumberConversions.floatToString(floatBytes);
          var backToFloat = NumberConversions.stringToFloat(stringResult.trim());
          var finalValue = MicrosoftFloat.unpack(backToFloat);

          expect(finalValue, closeTo(value, value.abs() * 1E-6 + 1E-10));
        }
      });
    });
  });
}
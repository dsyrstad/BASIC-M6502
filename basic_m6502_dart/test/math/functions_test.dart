import 'package:test/test.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import '../../lib/math/floating_point.dart';
import '../../lib/math/functions.dart';

void main() {
  group('MathFunctions', () {
    test('trigonometric functions', () {
      // Test SIN
      final zero = MicrosoftFloat.pack(0.0);
      final sinZero = MathFunctions.sin(zero);
      expect(MicrosoftFloat.unpack(sinZero), closeTo(0.0, 1e-10));

      final piOver2 = MicrosoftFloat.pack(math.pi / 2);
      final sinPiOver2 = MathFunctions.sin(piOver2);
      expect(MicrosoftFloat.unpack(sinPiOver2), closeTo(1.0, 1e-6));

      // Test COS
      final cosZero = MathFunctions.cos(zero);
      expect(MicrosoftFloat.unpack(cosZero), closeTo(1.0, 1e-6));

      final cosPiOver2 = MathFunctions.cos(piOver2);
      expect(MicrosoftFloat.unpack(cosPiOver2), closeTo(0.0, 1e-6));

      // Test TAN
      final piOver4 = MicrosoftFloat.pack(math.pi / 4);
      final tanPiOver4 = MathFunctions.tan(piOver4);
      expect(MicrosoftFloat.unpack(tanPiOver4), closeTo(1.0, 1e-6));

      // Test ATN
      final one = MicrosoftFloat.pack(1.0);
      final atnOne = MathFunctions.atn(one);
      expect(MicrosoftFloat.unpack(atnOne), closeTo(math.pi / 4, 1e-6));
    });

    test('logarithmic and exponential functions', () {
      // Test LOG
      final e = MicrosoftFloat.pack(math.e);
      final logE = MathFunctions.log(e);
      expect(MicrosoftFloat.unpack(logE), closeTo(1.0, 1e-6));

      final one = MicrosoftFloat.pack(1.0);
      final logOne = MathFunctions.log(one);
      expect(MicrosoftFloat.unpack(logOne), closeTo(0.0, 1e-6));

      // Test EXP
      final expOne = MathFunctions.exp(one);
      expect(MicrosoftFloat.unpack(expOne), closeTo(math.e, 1e-6));

      final zero = MicrosoftFloat.pack(0.0);
      final expZero = MathFunctions.exp(zero);
      expect(MicrosoftFloat.unpack(expZero), closeTo(1.0, 1e-6));

      // Test error cases
      expect(() => MathFunctions.log(zero), throwsArgumentError);
      final negative = MicrosoftFloat.pack(-1.0);
      expect(() => MathFunctions.log(negative), throwsArgumentError);
    });

    test('square root function', () {
      final zero = MicrosoftFloat.pack(0.0);
      final sqrZero = MathFunctions.sqr(zero);
      expect(MicrosoftFloat.unpack(sqrZero), equals(0.0));

      final four = MicrosoftFloat.pack(4.0);
      final sqrFour = MathFunctions.sqr(four);
      expect(MicrosoftFloat.unpack(sqrFour), equals(2.0));

      final nine = MicrosoftFloat.pack(9.0);
      final sqrNine = MathFunctions.sqr(nine);
      expect(MicrosoftFloat.unpack(sqrNine), equals(3.0));

      // Test error case
      final negative = MicrosoftFloat.pack(-1.0);
      expect(() => MathFunctions.sqr(negative), throwsArgumentError);
    });

    test('random number function', () {
      // Test basic RND
      final rnd1 = MathFunctions.rnd();
      final value1 = MicrosoftFloat.unpack(rnd1);
      expect(value1, greaterThanOrEqualTo(0.0));
      expect(value1, lessThan(1.0));

      final rnd2 = MathFunctions.rnd();
      final value2 = MicrosoftFloat.unpack(rnd2);
      expect(value2, greaterThanOrEqualTo(0.0));
      expect(value2, lessThan(1.0));

      // Different calls should produce different results (usually)
      expect(value1, isNot(equals(value2)));

      // Test seeded RND
      final seed = MicrosoftFloat.pack(42.0);
      final seeded1 = MathFunctions.rnd(seed);
      final seeded2 = MathFunctions.rnd(seed);

      // After reseeding with same value, should get same sequence
      expect(MicrosoftFloat.unpack(seeded1), equals(MicrosoftFloat.unpack(seeded2)));
    });

    test('integer and utility functions', () {
      // Test INT
      final pi = MicrosoftFloat.pack(3.14159);
      final intPi = MathFunctions.int(pi);
      expect(MicrosoftFloat.unpack(intPi), equals(3.0));

      final negativeFloat = MicrosoftFloat.pack(-2.7);
      final intNeg = MathFunctions.int(negativeFloat);
      expect(MicrosoftFloat.unpack(intNeg), equals(-3.0)); // Floor operation

      // Test ABS
      final abs1 = MathFunctions.abs(negativeFloat);
      expect(MicrosoftFloat.unpack(abs1), closeTo(2.7, 1e-6));

      final positive = MicrosoftFloat.pack(5.0);
      final abs2 = MathFunctions.abs(positive);
      expect(MicrosoftFloat.unpack(abs2), equals(5.0));

      // Test SGN
      final sgn1 = MathFunctions.sgn(positive);
      expect(MicrosoftFloat.unpack(sgn1), equals(1.0));

      final sgn2 = MathFunctions.sgn(negativeFloat);
      expect(MicrosoftFloat.unpack(sgn2), equals(-1.0));

      final zero = MicrosoftFloat.pack(0.0);
      final sgn3 = MathFunctions.sgn(zero);
      expect(MicrosoftFloat.unpack(sgn3), equals(0.0));
    });

    test('additional utility functions', () {
      // Test FIX (truncate)
      final pi = MicrosoftFloat.pack(3.14159);
      final fixPi = MathFunctions.fix(pi);
      expect(MicrosoftFloat.unpack(fixPi), equals(3.0));

      final negativeFloat = MicrosoftFloat.pack(-2.7);
      final fixNeg = MathFunctions.fix(negativeFloat);
      expect(MicrosoftFloat.unpack(fixNeg), equals(-2.0)); // Truncate towards zero

      // Test FRAC (fractional part)
      final fracPi = MathFunctions.frac(pi);
      expect(MicrosoftFloat.unpack(fracPi), closeTo(0.14159, 1e-5));

      // Test ROUND
      final roundPi = MathFunctions.round(pi);
      expect(MicrosoftFloat.unpack(roundPi), equals(3.0));

      final roundUp = MicrosoftFloat.pack(3.6);
      final roundUpResult = MathFunctions.round(roundUp);
      expect(MicrosoftFloat.unpack(roundUpResult), equals(4.0));
    });

    test('power function', () {
      final base = MicrosoftFloat.pack(2.0);
      final exp3 = MicrosoftFloat.pack(3.0);
      final result = MathFunctions.pow(base, exp3);
      expect(MicrosoftFloat.unpack(result), equals(8.0));

      final zero = MicrosoftFloat.pack(0.0);
      final powZero = MathFunctions.pow(base, zero);
      expect(MicrosoftFloat.unpack(powZero), equals(1.0));

      // Test square root using fractional power
      final half = MicrosoftFloat.pack(0.5);
      final sqrt4 = MathFunctions.pow(MicrosoftFloat.pack(4.0), half);
      expect(MicrosoftFloat.unpack(sqrt4), closeTo(2.0, 1e-6));
    });

    test('conversion functions', () {
      // Test degree/radian conversion
      final degrees90 = MicrosoftFloat.pack(90.0);
      final radians = MathFunctions.degToRad(degrees90);
      expect(MicrosoftFloat.unpack(radians), closeTo(math.pi / 2, 1e-6));

      final backToDegrees = MathFunctions.radToDeg(radians);
      expect(MicrosoftFloat.unpack(backToDegrees), closeTo(90.0, 1e-6));

      // Test constants
      final piConst = MathFunctions.pi();
      expect(MicrosoftFloat.unpack(piConst), closeTo(math.pi, 1e-6));

      final eConst = MathFunctions.e();
      expect(MicrosoftFloat.unpack(eConst), closeTo(math.e, 1e-6));
    });

    test('min/max functions', () {
      final a = MicrosoftFloat.pack(3.0);
      final b = MicrosoftFloat.pack(5.0);

      final maxResult = MathFunctions.max(a, b);
      expect(MicrosoftFloat.unpack(maxResult), equals(5.0));

      final minResult = MathFunctions.min(a, b);
      expect(MicrosoftFloat.unpack(minResult), equals(3.0));

      // Test with equal values
      final c = MicrosoftFloat.pack(3.0);
      final maxEqual = MathFunctions.max(a, c);
      expect(MicrosoftFloat.unpack(maxEqual), equals(3.0));
    });

    test('hyperbolic functions', () {
      final zero = MicrosoftFloat.pack(0.0);

      // Test SINH(0) = 0
      final sinh0 = MathFunctions.sinh(zero);
      expect(MicrosoftFloat.unpack(sinh0), closeTo(0.0, 1e-10));

      // Test COSH(0) = 1
      final cosh0 = MathFunctions.cosh(zero);
      expect(MicrosoftFloat.unpack(cosh0), closeTo(1.0, 1e-10));

      // Test TANH(0) = 0
      final tanh0 = MathFunctions.tanh(zero);
      expect(MicrosoftFloat.unpack(tanh0), closeTo(0.0, 1e-10));

      // Test with non-zero value
      final one = MicrosoftFloat.pack(1.0);
      final sinh1 = MathFunctions.sinh(one);
      expect(MicrosoftFloat.unpack(sinh1), closeTo((math.e - 1/math.e) / 2, 1e-6));
    });

    test('base-10 logarithm and exponential', () {
      final ten = MicrosoftFloat.pack(10.0);
      final log10_10 = MathFunctions.log10(ten);
      expect(MicrosoftFloat.unpack(log10_10), closeTo(1.0, 1e-6));

      final hundred = MicrosoftFloat.pack(100.0);
      final log10_100 = MathFunctions.log10(hundred);
      expect(MicrosoftFloat.unpack(log10_100), closeTo(2.0, 1e-6));

      // Test EXP10
      final two = MicrosoftFloat.pack(2.0);
      final exp10_2 = MathFunctions.exp10(two);
      expect(MicrosoftFloat.unpack(exp10_2), closeTo(100.0, 1e-6));
    });
  });
}
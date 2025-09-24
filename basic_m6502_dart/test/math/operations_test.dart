import 'package:test/test.dart';
import 'dart:typed_data';
import '../../lib/math/floating_point.dart';
import '../../lib/math/operations.dart';

void main() {
  group('MathOperations', () {
    test('addition (FADD)', () {
      // Test simple addition
      final a = MicrosoftFloat.pack(1.0);
      final b = MicrosoftFloat.pack(2.0);
      final result = MathOperations.fadd(a, b);
      final unpacked = MicrosoftFloat.unpack(result);

      expect(unpacked, equals(3.0));

      // Test adding zero
      final zero = MicrosoftFloat.pack(0.0);
      final addZero = MathOperations.fadd(a, zero);
      expect(MicrosoftFloat.unpack(addZero), equals(1.0));

      // Test adding negative numbers
      final neg = MicrosoftFloat.pack(-1.0);
      final addNeg = MathOperations.fadd(a, neg);
      expect(MicrosoftFloat.unpack(addNeg), equals(0.0));
    });

    test('subtraction (FSUB)', () {
      // Test simple subtraction
      final a = MicrosoftFloat.pack(5.0);
      final b = MicrosoftFloat.pack(2.0);
      final result = MathOperations.fsub(a, b);
      final unpacked = MicrosoftFloat.unpack(result);

      expect(unpacked, equals(3.0));

      // Test subtracting zero
      final zero = MicrosoftFloat.pack(0.0);
      final subZero = MathOperations.fsub(a, zero);
      expect(MicrosoftFloat.unpack(subZero), equals(5.0));

      // Test zero minus something
      final zeroSub = MathOperations.fsub(zero, a);
      expect(MicrosoftFloat.unpack(zeroSub), equals(-5.0));
    });

    test('multiplication (FMUL)', () {
      // Test simple multiplication
      final a = MicrosoftFloat.pack(3.0);
      final b = MicrosoftFloat.pack(4.0);
      final result = MathOperations.fmul(a, b);
      final unpacked = MicrosoftFloat.unpack(result);

      expect(unpacked, equals(12.0));

      // Test multiplying by zero
      final zero = MicrosoftFloat.pack(0.0);
      final mulZero = MathOperations.fmul(a, zero);
      expect(MicrosoftFloat.unpack(mulZero), equals(0.0));

      // Test multiplying by one
      final one = MicrosoftFloat.pack(1.0);
      final mulOne = MathOperations.fmul(a, one);
      expect(MicrosoftFloat.unpack(mulOne), equals(3.0));

      // Test negative multiplication
      final neg = MicrosoftFloat.pack(-2.0);
      final mulNeg = MathOperations.fmul(a, neg);
      expect(MicrosoftFloat.unpack(mulNeg), equals(-6.0));
    });

    test('division (FDIV)', () {
      // Test simple division
      final a = MicrosoftFloat.pack(12.0);
      final b = MicrosoftFloat.pack(3.0);
      final result = MathOperations.fdiv(a, b);
      final unpacked = MicrosoftFloat.unpack(result);

      expect(unpacked, equals(4.0));

      // Test dividing zero
      final zero = MicrosoftFloat.pack(0.0);
      final divZero = MathOperations.fdiv(zero, a);
      expect(MicrosoftFloat.unpack(divZero), equals(0.0));

      // Test division by zero should throw
      expect(() => MathOperations.fdiv(a, zero), throwsArgumentError);

      // Test dividing by one
      final one = MicrosoftFloat.pack(1.0);
      final divOne = MathOperations.fdiv(a, one);
      expect(MicrosoftFloat.unpack(divOne), equals(12.0));
    });

    test('negation (FNEG)', () {
      final a = MicrosoftFloat.pack(5.0);
      final neg = MathOperations.fneg(a);
      expect(MicrosoftFloat.unpack(neg), equals(-5.0));

      // Test double negation
      final doubleNeg = MathOperations.fneg(neg);
      expect(MicrosoftFloat.unpack(doubleNeg), equals(5.0));

      // Test negating zero
      final zero = MicrosoftFloat.pack(0.0);
      final negZero = MathOperations.fneg(zero);
      expect(MicrosoftFloat.unpack(negZero), equals(0.0));
    });

    test('comparison (FCOMPARE)', () {
      final a = MicrosoftFloat.pack(3.0);
      final b = MicrosoftFloat.pack(5.0);
      final c = MicrosoftFloat.pack(3.0);
      final zero = MicrosoftFloat.pack(0.0);

      expect(MathOperations.fcompare(a, b), equals(-1)); // 3 < 5
      expect(MathOperations.fcompare(b, a), equals(1)); // 5 > 3
      expect(MathOperations.fcompare(a, c), equals(0)); // 3 == 3
      expect(MathOperations.fcompare(zero, zero), equals(0)); // 0 == 0

      // Test with negative numbers
      final neg = MicrosoftFloat.pack(-2.0);
      expect(MathOperations.fcompare(neg, a), equals(-1)); // -2 < 3
      expect(MathOperations.fcompare(a, neg), equals(1)); // 3 > -2
    });

    test('equality (FEQUAL)', () {
      final a = MicrosoftFloat.pack(3.0);
      final b = MicrosoftFloat.pack(3.0);
      final c = MicrosoftFloat.pack(5.0);

      expect(MathOperations.fequal(a, b), isTrue);
      expect(MathOperations.fequal(a, c), isFalse);
    });

    test('absolute value (FABS)', () {
      final pos = MicrosoftFloat.pack(5.0);
      final neg = MicrosoftFloat.pack(-5.0);
      final zero = MicrosoftFloat.pack(0.0);

      expect(MicrosoftFloat.unpack(MathOperations.fabs(pos)), equals(5.0));
      expect(MicrosoftFloat.unpack(MathOperations.fabs(neg)), equals(5.0));
      expect(MicrosoftFloat.unpack(MathOperations.fabs(zero)), equals(0.0));
    });

    test('sign (FSGN)', () {
      final pos = MicrosoftFloat.pack(5.0);
      final neg = MicrosoftFloat.pack(-5.0);
      final zero = MicrosoftFloat.pack(0.0);

      expect(MathOperations.fsgn(pos), equals(1));
      expect(MathOperations.fsgn(neg), equals(-1));
      expect(MathOperations.fsgn(zero), equals(0));
    });

    test('integer conversion', () {
      final a = MicrosoftFloat.pack(42.0);
      final b = MicrosoftFloat.pack(3.7);
      final c = MicrosoftFloat.pack(-2.9);

      expect(MathOperations.floatToInt(a), equals(42));
      expect(MathOperations.floatToInt(b), equals(3));
      expect(MathOperations.floatToInt(c), equals(-2));

      // Test integer to float
      final intFloat = MathOperations.intToFloat(42);
      expect(MicrosoftFloat.unpack(intFloat), equals(42.0));
    });

    test('integer check', () {
      final int1 = MicrosoftFloat.pack(42.0);
      final int2 = MicrosoftFloat.pack(-17.0);
      final float1 = MicrosoftFloat.pack(3.14);
      final zero = MicrosoftFloat.pack(0.0);

      expect(MathOperations.isInteger(int1), isTrue);
      expect(MathOperations.isInteger(int2), isTrue);
      expect(MathOperations.isInteger(float1), isFalse);
      expect(MathOperations.isInteger(zero), isTrue);
    });

    test('power function (FPOW)', () {
      final base = MicrosoftFloat.pack(2.0);

      // Test powers
      expect(MicrosoftFloat.unpack(MathOperations.fpow(base, 0)), equals(1.0));
      expect(MicrosoftFloat.unpack(MathOperations.fpow(base, 1)), equals(2.0));
      expect(MicrosoftFloat.unpack(MathOperations.fpow(base, 3)), equals(8.0));

      // Test negative power (should work for non-zero base)
      expect(MicrosoftFloat.unpack(MathOperations.fpow(base, -1)), equals(0.5));

      // Test zero base
      final zero = MicrosoftFloat.pack(0.0);
      expect(MicrosoftFloat.unpack(MathOperations.fpow(zero, 2)), equals(0.0));
      expect(() => MathOperations.fpow(zero, -1), throwsArgumentError);
    });

    test('modulus operation (FMOD)', () {
      final a = MicrosoftFloat.pack(10.0);
      final b = MicrosoftFloat.pack(3.0);

      final result = MathOperations.fmod(a, b);
      expect(MicrosoftFloat.unpack(result), equals(1.0));

      // Test zero dividend
      final zero = MicrosoftFloat.pack(0.0);
      final zeroMod = MathOperations.fmod(zero, b);
      expect(MicrosoftFloat.unpack(zeroMod), equals(0.0));

      // Test division by zero should throw
      expect(() => MathOperations.fmod(a, zero), throwsArgumentError);
    });

    test('float to string conversion', () {
      final a = MicrosoftFloat.pack(3.14);
      final zero = MicrosoftFloat.pack(0.0);
      final neg = MicrosoftFloat.pack(-42.0);

      expect(MathOperations.floatToString(zero), equals("0"));
      expect(MathOperations.floatToString(neg), equals("-42.0"));

      // Pi should be close to 3.14
      final piStr = MathOperations.floatToString(a);
      expect(piStr, contains("3.14"));
    });

    test('complex arithmetic expressions', () {
      // Test (2 + 3) * 4 = 20
      final two = MicrosoftFloat.pack(2.0);
      final three = MicrosoftFloat.pack(3.0);
      final four = MicrosoftFloat.pack(4.0);

      final sum = MathOperations.fadd(two, three);
      final result = MathOperations.fmul(sum, four);

      expect(MicrosoftFloat.unpack(result), equals(20.0));

      // Test 10 / 2 - 3 = 2
      final ten = MicrosoftFloat.pack(10.0);
      final div = MathOperations.fdiv(ten, two);
      final sub = MathOperations.fsub(div, three);

      expect(MicrosoftFloat.unpack(sub), equals(2.0));
    });
  });
}

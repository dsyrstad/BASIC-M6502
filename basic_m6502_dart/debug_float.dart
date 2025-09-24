import 'dart:typed_data';
import 'dart:math' as math;
import 'lib/math/floating_point.dart';
import 'lib/math/functions.dart';

void main() {
  print('Testing the fix:');
  final testValue = 0.999999999999999;
  print('Input: $testValue');

  final packed = MicrosoftFloat.pack(testValue);
  print('Packed: $packed');
  print('Debug: ${MicrosoftFloat.toDebugString(packed)}');

  final unpacked = MicrosoftFloat.unpack(packed);
  print('Unpacked: $unpacked');

  print('\nNow testing sin(pi/2) again:');
  final piOver2 = math.pi / 2;
  final packedPi = MicrosoftFloat.pack(piOver2);
  final sinResult = MathFunctions.sin(packedPi);
  final sinValue = MicrosoftFloat.unpack(sinResult);
  print('sin(pi/2) = $sinValue');
}

import 'package:test/test.dart';
import '../../lib/memory/memory.dart';
import '../../lib/memory/variables.dart';

void main() {
  group('VariableStorage', () {
    late Memory memory;
    late VariableStorage variables;

    setUp(() {
      memory = Memory();
      variables = VariableStorage(memory);

      // Initialize variable storage at a test location
      const startAddr = 0x0800;
      variables.initialize(startAddr);
    });

    test('should initialize variable storage', () {
      expect(memory.readWord(Memory.vartab), equals(0x0800));
      expect(memory.readWord(Memory.arytab), equals(0x0800));
      expect(memory.readWord(Memory.strend), equals(0x0800));
    });

    test('should normalize variable names', () {
      // Test finding variables with different name formats
      final result1 = variables.findVariable('A');
      expect(result1.name, equals('A '));

      final result2 = variables.findVariable('AB');
      expect(result2.name, equals('AB'));

      final result3 = variables.findVariable('a');
      expect(result3.name, equals('A '));
    });

    test('should handle string variables', () {
      final result = variables.findVariable('A\$');
      expect(result.isString, isTrue);
      expect(result.isArray, isFalse);
      expect(result.name, equals('A\$'));
    });

    test('should create new numeric variable', () {
      final result = variables.findVariable('X');
      expect(result.found, isFalse);
      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(0.0));
    });

    test('should create new string variable', () {
      final result = variables.findVariable('X\$');
      expect(result.found, isFalse);
      expect(result.value, isA<StringValue>());
      expect((result.value as StringValue).value, equals(''));
    });

    test('should set and get numeric variables', () {
      variables.setVariable('A', const NumericValue(42.5));
      final value = variables.getVariable('A');
      expect(value, isA<NumericValue>());
      expect((value as NumericValue).value, equals(42.5));
    });

    test('should set and get string variables', () {
      variables.setVariable('B\$', const StringValue('HELLO'));
      final value = variables.getVariable('B\$');
      expect(value, isA<StringValue>());
      expect((value as StringValue).value, equals('HELLO'));
    });

    test('should find existing variables', () {
      variables.setVariable('C', const NumericValue(123.0));

      final result = variables.findVariable('C');
      expect(result.found, isTrue);
      expect(result.value, isA<NumericValue>());
      expect((result.value as NumericValue).value, equals(123.0));
    });

    test('should handle type mismatch errors', () {
      variables.setVariable('D', const NumericValue(1.0));

      expect(
        () => variables.setVariable('D', const StringValue('ERROR')),
        throwsA(isA<VariableException>())
      );
    });

    test('should clear all variables', () {
      variables.setVariable('A', const NumericValue(1.0));
      variables.setVariable('B\$', const StringValue('TEST'));

      variables.clearVariables();

      // After clearing, variables should be created as new
      final resultA = variables.findVariable('A');
      final resultB = variables.findVariable('B\$');

      expect(resultA.found, isFalse);
      expect(resultB.found, isFalse);
    });

    test('should handle multiple variables', () {
      variables.setVariable('A', const NumericValue(1.0));
      variables.setVariable('B', const NumericValue(2.0));
      variables.setVariable('C\$', const StringValue('TEST'));

      expect((variables.getVariable('A') as NumericValue).value, equals(1.0));
      expect((variables.getVariable('B') as NumericValue).value, equals(2.0));
      expect((variables.getVariable('C\$') as StringValue).value, equals('TEST'));
    });

    test('should handle invalid variable names', () {
      expect(
        () => variables.findVariable(''),
        throwsA(isA<VariableException>())
      );

      expect(
        () => variables.findVariable('ABC'),
        throwsA(isA<VariableException>())
      );
    });
  });

  group('VariableValue', () {
    test('NumericValue should have correct equality', () {
      const value1 = NumericValue(42.0);
      const value2 = NumericValue(42.0);
      const value3 = NumericValue(43.0);

      expect(value1, equals(value2));
      expect(value1, isNot(equals(value3)));
    });

    test('StringValue should have correct equality', () {
      const value1 = StringValue('HELLO');
      const value2 = StringValue('HELLO');
      const value3 = StringValue('WORLD');

      expect(value1, equals(value2));
      expect(value1, isNot(equals(value3)));
    });

    test('Different types should not be equal', () {
      const numericValue = NumericValue(42.0);
      const stringValue = StringValue('42');

      expect(numericValue, isNot(equals(stringValue)));
    });
  });
}
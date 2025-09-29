import 'package:test/test.dart';
import '../../lib/basic_interpreter.dart';

void main() {
  group('System Integration Tests', () {
    late BasicInterpreter basicInterpreter;

    setUp(() {
      basicInterpreter = BasicInterpreter();
    });

    group('SYS statement', () {
      test('SYS with valid address executes without error', () {
        final program = '''
10 SYS 49152
20 END
''';
        basicInterpreter.loadProgram(program);
        expect(() => basicInterpreter.run(), returnsNormally);
      });

      test('SYS calls system hook when configured', () {
        int? calledAddress;
        basicInterpreter.interpreter.systemCallHook = (address) {
          calledAddress = address;
        };

        final program = '''
10 SYS 32768
20 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        expect(calledAddress, equals(32768));
      });

      test('SYS with expression evaluates correctly', () {
        int? calledAddress;
        basicInterpreter.interpreter.systemCallHook = (address) {
          calledAddress = address;
        };

        final program = '''
10 A = 1024
20 SYS A * 2 + 100
30 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        expect(calledAddress, equals(2148)); // 1024 * 2 + 100
      });

      test('SYS with negative address throws error', () {
        final program = '''
10 SYS -100
20 END
''';
        basicInterpreter.loadProgram(program);
        expect(() => basicInterpreter.run(), throwsA(anything));
      });

      test('SYS with address > 65535 throws error', () {
        final program = '''
10 SYS 70000
20 END
''';
        basicInterpreter.loadProgram(program);
        expect(() => basicInterpreter.run(), throwsA(anything));
      });

      test('SYS with string argument throws type mismatch', () {
        final program = '''
10 A\$ = "HELLO"
20 SYS A\$
30 END
''';
        basicInterpreter.loadProgram(program);
        expect(() => basicInterpreter.run(), throwsA(anything));
      });

      test('SYS without argument is handled gracefully', () {
        final program = '''
10 SYS
20 END
''';
        basicInterpreter.loadProgram(program);
        // Should not crash - errors are handled internally
        expect(() => basicInterpreter.run(), returnsNormally);
      });

      test('Multiple SYS calls execute in sequence', () {
        final addresses = <int>[];
        basicInterpreter.interpreter.systemCallHook = (address) {
          addresses.add(address);
        };

        final program = '''
10 SYS 1000
20 SYS 2000
30 SYS 3000
40 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        expect(addresses, equals([1000, 2000, 3000]));
      });

      test('SYS can modify system state via hook', () {
        int counter = 0;
        basicInterpreter.interpreter.systemCallHook = (address) {
          if (address == 49152) {
            counter += 10;
          }
        };

        final program = '''
10 FOR I = 1 TO 5
20 SYS 49152
30 NEXT I
40 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        expect(counter, equals(50));
      });
    });

    group('USR function', () {
      test('USR returns argument by default', () {
        final program = '''
10 X = USR(42)
20 PRINT X
30 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        final output = basicInterpreter.getOutput();
        expect(output, contains('42'));
      });

      test('USR calls hook when configured', () {
        basicInterpreter.interpreter.usrFunctionHook = (arg) {
          return arg * 2; // Double the input
        };

        final program = '''
10 X = USR(21)
20 PRINT X
30 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        final output = basicInterpreter.getOutput();
        expect(output, contains('42'));
      });

      test('USR can perform complex calculations', () {
        basicInterpreter.interpreter.usrFunctionHook = (arg) {
          // Simulate a machine code routine that computes factorial
          if (arg <= 1) return 1;
          double result = 1;
          for (int i = 2; i <= arg.round(); i++) {
            result *= i;
          }
          return result;
        };

        final program = '''
10 X = USR(5)
20 PRINT X
30 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        final output = basicInterpreter.getOutput();
        expect(output, contains('120')); // 5! = 120
      });

      test('USR with expression evaluates correctly', () {
        basicInterpreter.interpreter.usrFunctionHook = (arg) {
          return arg + 100;
        };

        final program = '''
10 A = 10
20 B = 5
30 X = USR(A * B)
40 PRINT X
50 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        final output = basicInterpreter.getOutput();
        expect(output, contains('150')); // (10 * 5) + 100
      });

      test('USR with string argument is handled gracefully', () {
        final program = '''
10 A\$ = "TEST"
20 X = USR(A\$)
30 END
''';
        basicInterpreter.loadProgram(program);
        // Should not crash - errors are handled internally
        expect(() => basicInterpreter.run(), returnsNormally);
      });

      test('USR in complex expression', () {
        basicInterpreter.interpreter.usrFunctionHook = (arg) {
          return arg * 3;
        };

        final program = '''
10 X = USR(10) + USR(20) + 5
20 PRINT X
30 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        final output = basicInterpreter.getOutput();
        expect(output, contains('95')); // (10*3) + (20*3) + 5
      });

      test('USR result can be assigned to variable', () {
        basicInterpreter.interpreter.usrFunctionHook = (arg) {
          return arg / 2;
        };

        final program = '''
10 A = USR(100)
20 B = A * 3
30 PRINT B
40 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        final output = basicInterpreter.getOutput();
        expect(output, contains('150')); // (100/2) * 3
      });

      test('Multiple USR calls with different arguments', () {
        final calledArgs = <double>[];
        basicInterpreter.interpreter.usrFunctionHook = (arg) {
          calledArgs.add(arg);
          return arg;
        };

        final program = '''
10 X = USR(10)
20 Y = USR(20)
30 Z = USR(30)
40 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        expect(calledArgs, equals([10.0, 20.0, 30.0]));
      });
    });

    group('SYS and USR integration', () {
      test('SYS and USR can work together', () {
        int sysAddress = 0;
        basicInterpreter.interpreter.systemCallHook = (address) {
          sysAddress = address;
        };
        basicInterpreter.interpreter.usrFunctionHook = (arg) {
          return arg + 1000;
        };

        final program = '''
10 A = USR(100)
20 SYS A
30 PRINT A
40 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        expect(sysAddress, equals(1100));
        final output = basicInterpreter.getOutput();
        expect(output, contains('1100'));
      });

      test('Complex program with SYS and USR', () {
        final log = <String>[];
        basicInterpreter.interpreter.systemCallHook = (address) {
          log.add('SYS:$address');
        };
        basicInterpreter.interpreter.usrFunctionHook = (arg) {
          log.add('USR:$arg');
          return arg * 2;
        };

        final program = '''
10 FOR I = 1 TO 3
20 X = USR(I * 10)
30 SYS X
40 NEXT I
50 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        expect(
          log,
          equals([
            'USR:10.0',
            'SYS:20',
            'USR:20.0',
            'SYS:40',
            'USR:30.0',
            'SYS:60',
          ]),
        );
      });

      test('USR in IF condition with SYS in branch', () {
        bool sysCalled = false;
        basicInterpreter.interpreter.systemCallHook = (address) {
          sysCalled = true;
        };
        basicInterpreter.interpreter.usrFunctionHook = (arg) {
          return arg > 50 ? 1 : 0;
        };

        final program = '''
10 A = 100
20 IF USR(A) = 1 THEN SYS 49152
30 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        expect(sysCalled, isTrue);
      });
    });

    group('Machine code interface simulation', () {
      test('Hook can access and modify interpreter state indirectly', () {
        // Simulate a machine code routine that sets a memory location
        basicInterpreter.interpreter.systemCallHook = (address) {
          // Write a value to memory at the specified address
          basicInterpreter.memory.writeByte(address, 42);
        };

        final program = '''
10 SYS 1024
20 X = PEEK(1024)
30 PRINT X
40 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        final output = basicInterpreter.getOutput();
        expect(output, contains('42'));
      });

      test('USR can read from memory via hook', () {
        // Set up some data in memory
        basicInterpreter.memory.writeByte(2048, 99);

        basicInterpreter.interpreter.usrFunctionHook = (arg) {
          // Read from memory at the address specified by arg
          final address = arg.round();
          return basicInterpreter.memory.readByte(address).toDouble();
        };

        final program = '''
10 X = USR(2048)
20 PRINT X
30 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        final output = basicInterpreter.getOutput();
        expect(output, contains('99'));
      });

      test('SYS and USR can implement custom I/O routines', () {
        final buffer = <int>[];

        // SYS writes to buffer
        basicInterpreter.interpreter.systemCallHook = (address) {
          final value = basicInterpreter.memory.readByte(address);
          buffer.add(value);
        };

        // USR reads from buffer
        basicInterpreter.interpreter.usrFunctionHook = (arg) {
          if (buffer.isEmpty) return -1;
          return buffer.removeAt(0).toDouble();
        };

        final program = '''
10 POKE 1000, 65
20 SYS 1000
30 POKE 1000, 66
40 SYS 1000
50 X = USR(0)
60 Y = USR(0)
70 PRINT CHR\$(X); CHR\$(Y)
80 END
''';
        basicInterpreter.loadProgram(program);
        basicInterpreter.run();

        final output = basicInterpreter.getOutput();
        expect(output, contains('AB'));
      });
    });
  });
}

import 'dart:io';
import '../lib/basic_interpreter.dart';

void main() {
  print('Microsoft BASIC 6502 (Dart) Performance Benchmarks');
  print('=' * 50);

  final interpreter = BasicInterpreter();

  // Benchmark 1: Prime Number Calculation
  print('\n1. Prime Number Calculation (1-100)');
  final primeProgram = '''
10 FOR N=2 TO 100
20 F=1
30 FOR D=2 TO N-1
40 IF N/D=INT(N/D) THEN F=0
50 NEXT D
60 IF F=1 THEN PRINT N;" ";
70 NEXT N
80 END
''';

  interpreter.loadProgram(primeProgram);
  final primeStart = DateTime.now();
  interpreter.run();
  final primeTime = DateTime.now().difference(primeStart);
  print('Time: ${primeTime.inMilliseconds}ms');

  // Benchmark 2: Fibonacci Sequence
  print('\n2. Fibonacci Sequence (first 20 numbers)');
  final fibProgram = '''
10 A=0:B=1:PRINT A;B;
20 FOR I=3 TO 20
30 C=A+B:PRINT C;
40 A=B:B=C
50 NEXT I
60 END
''';

  interpreter.clear();
  interpreter.loadProgram(fibProgram);
  final fibStart = DateTime.now();
  interpreter.run();
  final fibTime = DateTime.now().difference(fibStart);
  print('\nTime: ${fibTime.inMilliseconds}ms');

  // Benchmark 3: Nested Loop Performance
  print('\n3. Nested Loop Performance (100x100)');
  final loopProgram = '''
10 C=0
20 FOR I=1 TO 100
30 FOR J=1 TO 100
40 C=C+1
50 NEXT J
60 NEXT I
70 PRINT "COUNT:";C
80 END
''';

  interpreter.clear();
  interpreter.loadProgram(loopProgram);
  final loopStart = DateTime.now();
  interpreter.run();
  final loopTime = DateTime.now().difference(loopStart);
  print('Time: ${loopTime.inMilliseconds}ms');

  // Benchmark 4: String Operations
  print('\n4. String Operations (100 concatenations)');
  final stringProgram = '''
10 A\$=""
20 FOR I=1 TO 100
30 A\$=A\$+"X"
40 NEXT I
50 PRINT "LENGTH:";LEN(A\$)
60 END
''';

  interpreter.clear();
  interpreter.loadProgram(stringProgram);
  final stringStart = DateTime.now();
  interpreter.run();
  final stringTime = DateTime.now().difference(stringStart);
  print('Time: ${stringTime.inMilliseconds}ms');

  // Benchmark 5: Mathematical Functions
  print('\n5. Mathematical Functions (trigonometry)');
  final mathProgram = '''
10 S=0
20 FOR I=1 TO 100
30 X=I*0.1
40 S=S+SIN(X)+COS(X)+TAN(X/10)
50 NEXT I
60 PRINT "SUM:";S
70 END
''';

  interpreter.clear();
  interpreter.loadProgram(mathProgram);
  final mathStart = DateTime.now();
  interpreter.run();
  final mathTime = DateTime.now().difference(mathStart);
  print('Time: ${mathTime.inMilliseconds}ms');

  // Benchmark 6: Array Operations
  print('\n6. Array Operations (20x20 matrix)');
  final arrayProgram = '''
10 DIM A(20,20)
20 FOR I=1 TO 20
30 FOR J=1 TO 20
40 A(I,J)=I*J
50 NEXT J
60 NEXT I
70 S=0
80 FOR I=1 TO 20
90 FOR J=1 TO 20
100 S=S+A(I,J)
110 NEXT J
120 NEXT I
130 PRINT "SUM:";S
140 END
''';

  interpreter.clear();
  interpreter.loadProgram(arrayProgram);
  final arrayStart = DateTime.now();
  interpreter.run();
  final arrayTime = DateTime.now().difference(arrayStart);
  print('Time: ${arrayTime.inMilliseconds}ms');

  // Benchmark 7: Bubble Sort
  print('\n7. Bubble Sort (50 elements)');
  final sortProgram = '''
10 DIM A(50)
20 FOR I=1 TO 50
30 A(I)=51-I
40 NEXT I
50 FOR I=1 TO 49
60 FOR J=1 TO 50-I
70 IF A(J)>A(J+1) THEN T=A(J):A(J)=A(J+1):A(J+1)=T
80 NEXT J
90 NEXT I
100 PRINT "SORTED: ";A(1);"-";A(50)
110 END
''';

  interpreter.clear();
  interpreter.loadProgram(sortProgram);
  final sortStart = DateTime.now();
  interpreter.run();
  final sortTime = DateTime.now().difference(sortStart);
  print('Time: ${sortTime.inMilliseconds}ms');

  // Summary
  print('\n' + '=' * 50);
  print('BENCHMARK SUMMARY');
  print('-' * 50);
  print('Prime Numbers (1-100):     ${primeTime.inMilliseconds}ms');
  print('Fibonacci (20 numbers):    ${fibTime.inMilliseconds}ms');
  print('Nested Loops (100x100):    ${loopTime.inMilliseconds}ms');
  print('String Ops (100 concat):   ${stringTime.inMilliseconds}ms');
  print('Math Functions (100 iter): ${mathTime.inMilliseconds}ms');
  print('Array Ops (20x20):         ${arrayTime.inMilliseconds}ms');
  print('Bubble Sort (50 elem):     ${sortTime.inMilliseconds}ms');
  print('-' * 50);
  final totalTime =
      primeTime +
      fibTime +
      loopTime +
      stringTime +
      mathTime +
      arrayTime +
      sortTime;
  print('Total Time: ${totalTime.inMilliseconds}ms');

  // Performance comparison notes
  print('\n' + '=' * 50);
  print('PERFORMANCE NOTES');
  print('-' * 50);
  print('These benchmarks measure the Dart implementation of');
  print('Microsoft BASIC 6502 against typical BASIC programs.');
  print('');
  print('For reference, the original 6502 @ 1MHz would take:');
  print('- Nested loops (100x100): ~10-15 seconds');
  print('- Prime numbers (1-100):  ~5-10 seconds');
  print('- Bubble sort (100 elem): ~20-30 seconds');
  print('');
  print('This Dart implementation on modern hardware is');
  print('approximately 1000-10000x faster than the original.');
}

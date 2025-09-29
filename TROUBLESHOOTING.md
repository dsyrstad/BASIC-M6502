# Troubleshooting Guide

## Overview

This guide helps you diagnose and fix common problems when using the Microsoft BASIC 6502 Dart implementation.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Runtime Errors](#runtime-errors)
3. [Program Compatibility](#program-compatibility)
4. [Performance Issues](#performance-issues)
5. [File I/O Problems](#file-io-problems)
6. [Common Programming Mistakes](#common-programming-mistakes)
7. [Debugging Techniques](#debugging-techniques)

## Installation Issues

### Problem: Dart SDK Not Found

**Symptom**:
```
bash: dart: command not found
```

**Solution**:
1. Install Dart SDK from https://dart.dev/get-dart
2. Verify installation: `dart --version`
3. Add Dart to your PATH

**macOS**:
```bash
export PATH="$PATH:/usr/local/opt/dart/libexec"
```

**Linux**:
```bash
export PATH="$PATH:/usr/lib/dart/bin"
```

**Windows**:
Add `C:\tools\dart-sdk\bin` to your PATH environment variable.

### Problem: Dependencies Not Resolving

**Symptom**:
```
Error: Cannot find package 'test'
```

**Solution**:
```bash
dart pub get
```

If that fails, try:
```bash
dart pub cache repair
dart pub get
```

### Problem: Permission Denied

**Symptom**:
```
Permission denied: bin/basic.dart
```

**Solution**:
```bash
chmod +x bin/basic.dart
```

## Runtime Errors

### SYNTAX ERROR

**Symptom**:
```
?SYNTAX ERROR IN LINE 10
```

**Common Causes**:

1. **Missing keyword**:
   ```basic
   10 X = 5    ' Missing LET (optional but helps clarity)
   ```
   Fix: Add `LET` or verify statement syntax
   ```basic
   10 LET X = 5
   ```

2. **Invalid line number**:
   ```basic
   10 GOTO 99999    ' Line doesn't exist
   ```
   Fix: Use `LIST` to verify line numbers exist

3. **Mismatched parentheses**:
   ```basic
   10 PRINT (2 + 3    ' Missing )
   ```
   Fix: Count your parentheses

4. **Invalid variable name**:
   ```basic
   10 LET 123A = 5    ' Can't start with digit
   ```
   Fix: Start variable names with a letter

**Debugging**:
```basic
' Enable line-by-line execution
10 PRINT "LINE 10": REM Debug marker
20 PRINT "LINE 20": REM Debug marker
```

### TYPE MISMATCH

**Symptom**:
```
?TYPE MISMATCH ERROR IN LINE 20
```

**Common Causes**:

1. **String/Number confusion**:
   ```basic
   10 A$ = "HELLO"
   20 PRINT A$ + 5    ' Can't add number to string
   ```
   Fix: Use correct type
   ```basic
   20 PRINT A$ + STR$(5)
   ```

2. **Wrong array type**:
   ```basic
   10 DIM A(10)       ' Numeric array
   20 A(5) = "TEXT"   ' Trying to store string
   ```
   Fix: Use string array
   ```basic
   10 DIM A$(10)
   ```

3. **Function argument type**:
   ```basic
   10 PRINT SIN("45")    ' SIN expects number
   ```
   Fix: Use numeric value
   ```basic
   10 PRINT SIN(45)
   ```

### DIVISION BY ZERO

**Symptom**:
```
?DIVISION BY ZERO ERROR IN LINE 30
```

**Common Causes**:

```basic
10 A = 0
20 B = 10
30 PRINT B / A    ' Division by zero
```

**Solution**: Check for zero before dividing
```basic
30 IF A <> 0 THEN PRINT B / A ELSE PRINT "UNDEFINED"
```

### OUT OF MEMORY

**Symptom**:
```
?OUT OF MEMORY ERROR
```

**Common Causes**:

1. **Too many variables**: Over 1000 variables
2. **Large arrays**: Arrays consuming too much space
3. **String accumulation**: Building large strings in loops

**Solutions**:

1. **Clear unused variables**:
   ```basic
   CLEAR    ' Reset all variables
   ```

2. **Dimension arrays appropriately**:
   ```basic
   ' Don't use:
   DIM A(10000)
   ' Use smaller arrays:
   DIM A(100)
   ```

3. **Avoid string accumulation**:
   ```basic
   ' Problematic:
   10 S$ = ""
   20 FOR I = 1 TO 1000
   30   S$ = S$ + "X"    ' Each concat allocates new string
   40 NEXT I

   ' Better:
   10 FOR I = 1 TO 1000
   20   PRINT "X";       ' Direct output
   30 NEXT I
   ```

### OUT OF STRING SPACE

**Symptom**:
```
?OUT OF STRING SPACE ERROR
```

**Cause**: Too many active string values

**Solutions**:

1. **Reuse string variables**:
   ```basic
   ' Problematic:
   10 FOR I = 1 TO 100
   20   A$ = "TEMP" + STR$(I)    ' Creates many temporaries
   30 NEXT I

   ' Better:
   10 A$ = "TEMP"
   20 FOR I = 1 TO 100
   30   PRINT A$; I
   40 NEXT I
   ```

2. **Minimize string operations in loops**:
   ```basic
   ' Avoid:
   10 FOR I = 1 TO 100
   20   S$ = LEFT$("HELLO", 2) + RIGHT$("WORLD", 3)
   30 NEXT I

   ' Better:
   10 S$ = LEFT$("HELLO", 2) + RIGHT$("WORLD", 3)
   20 FOR I = 1 TO 100
   30   PRINT S$
   40 NEXT I
   ```

### NEXT WITHOUT FOR

**Symptom**:
```
?NEXT WITHOUT FOR ERROR IN LINE 40
```

**Common Causes**:

1. **Missing FOR**:
   ```basic
   10 I = 1
   20 PRINT I
   30 I = I + 1
   40 NEXT I    ' No matching FOR
   ```
   Fix: Add FOR statement
   ```basic
   10 FOR I = 1 TO 10
   ```

2. **Wrong variable**:
   ```basic
   10 FOR I = 1 TO 10
   20   PRINT I
   30 NEXT J    ' Wrong variable
   ```
   Fix: Match variable names
   ```basic
   30 NEXT I
   ```

3. **Nested loop error**:
   ```basic
   10 FOR I = 1 TO 5
   20   FOR J = 1 TO 5
   30   NEXT I    ' Wrong order
   40 NEXT J
   ```
   Fix: Exit inner loops first
   ```basic
   30   NEXT J
   40 NEXT I
   ```

### RETURN WITHOUT GOSUB

**Symptom**:
```
?RETURN WITHOUT GOSUB ERROR
```

**Common Causes**:

1. **RETURN in main program**:
   ```basic
   10 PRINT "HELLO"
   20 RETURN    ' No GOSUB before this
   ```
   Fix: Only use RETURN after GOSUB

2. **Missing GOSUB**:
   ```basic
   10 GOTO 100
   20 END
   100 PRINT "SUBROUTINE"
   110 RETURN    ' Used GOTO instead of GOSUB
   ```
   Fix: Use GOSUB for subroutines
   ```basic
   10 GOSUB 100
   ```

### UNDEFINED LINE

**Symptom**:
```
?UNDEFINED LINE ERROR IN LINE 10
```

**Cause**: GOTO/GOSUB to non-existent line

**Solution**:
```basic
10 GOTO 500    ' Line 500 doesn't exist
```

Fix: Use `LIST` to check line numbers, then correct:
```basic
10 GOTO 50     ' Correct existing line number
```

### BAD SUBSCRIPT

**Symptom**:
```
?BAD SUBSCRIPT ERROR IN LINE 20
```

**Common Causes**:

1. **Array not dimensioned**:
   ```basic
   10 A(20) = 5    ' Array not DIMmed for size 20
   ```
   Fix: Dimension array first
   ```basic
   10 DIM A(20)
   20 A(20) = 5
   ```

2. **Index out of range**:
   ```basic
   10 DIM A(10)
   20 A(11) = 5    ' Index 11 > size 10
   ```
   Fix: Use valid indices (0-10 for DIM A(10))
   ```basic
   20 A(10) = 5
   ```

3. **Negative index**:
   ```basic
   10 DIM A(10)
   20 I = -1
   30 A(I) = 5    ' Negative index
   ```
   Fix: Check index bounds
   ```basic
   20 I = 0
   ```

### REDIMENSIONED ARRAY

**Symptom**:
```
?REDIMENSIONED ARRAY ERROR
```

**Cause**: Trying to DIM an array twice

```basic
10 DIM A(10)
20 DIM A(20)    ' Can't redimension
```

**Solution**: Use `CLEAR` to reset, or use different array name
```basic
10 DIM A(10)
15 CLEAR        ' Reset all variables
20 DIM A(20)    ' Now OK
```

## Program Compatibility

### Classic Program Won't Run

**Problem**: Old BASIC program doesn't work

**Diagnostic Steps**:

1. **Check for platform-specific commands**:
   ```basic
   10 POKE 53280, 0    ' Commodore-specific
   ```
   Solution: Remove or comment out

2. **Check for graphics commands**:
   ```basic
   10 HPLOT 100, 100    ' Apple II graphics
   ```
   Solution: Replace with text output

3. **Check for timing loops**:
   ```basic
   10 FOR T = 1 TO 1000: NEXT T    ' Delay
   ```
   Solution: Remove (not needed on modern hardware)

4. **List program to verify**:
   ```basic
   LIST    ' Shows program structure
   ```

### Program Runs Too Fast

**Problem**: Game or animation runs too quickly

**Cause**: Modern hardware is much faster than original 6502

**Solutions**:

1. **Add explicit pauses** (if implementing sleep):
   ```basic
   10 PRINT "HELLO"
   20 REM SLEEP 1000    ' Would need custom implementation
   30 PRINT "WORLD"
   ```

2. **Add user input delays**:
   ```basic
   10 PRINT "PRESS ANY KEY"
   20 GET A$: IF A$ = "" THEN 20
   ```

3. **Reduce iteration counts**:
   ```basic
   ' Original:
   10 FOR I = 1 TO 1000: NEXT I

   ' Modern:
   10 FOR I = 1 TO 10: NEXT I
   ```

### Random Numbers Don't Match

**Problem**: Program depends on specific random sequence

**Cause**: Different random number generator

**Solution**: Rewrite logic to not depend on specific sequence
```basic
' Instead of expecting specific values:
10 IF RND(1) = 0.123456 THEN ...

' Use ranges:
10 IF RND(1) < 0.5 THEN ...
```

## Performance Issues

### Program Runs Slowly

**Rare but possible causes**:

1. **Excessive string operations**:
   ```basic
   10 FOR I = 1 TO 10000
   20   S$ = S$ + "X"    ' Slow
   30 NEXT I
   ```
   Solution: Avoid string concatenation in tight loops

2. **Large arrays**:
   ```basic
   10 DIM A(10000, 10000)    ' Very large
   ```
   Solution: Use smaller arrays

3. **Deep recursion via GOSUB**:
   ```basic
   10 GOSUB 10    ' Infinite recursion
   ```
   Solution: Fix logic to prevent deep recursion

### High Memory Usage

**Check**:
```bash
dart run --observe bin/basic.dart
```

**Solutions**:
1. Clear unused variables with `CLEAR`
2. Use smaller arrays
3. Minimize string storage

## File I/O Problems

### Can't Load Program

**Symptom**:
```
?FILE NOT FOUND: PROGRAM.BAS
```

**Solutions**:

1. **Check filename**:
   ```basic
   LOAD "PROGRAM.BAS"    ' Correct
   LOAD "PROGRAM"        ' May not work (need extension)
   ```

2. **Check path**:
   ```basic
   ' Relative path:
   LOAD "examples/hello.bas"

   ' Absolute path:
   LOAD "/home/user/programs/hello.bas"
   ```

3. **Verify file exists**:
   ```bash
   ls -la examples/hello.bas
   ```

4. **Check permissions**:
   ```bash
   chmod 644 examples/hello.bas
   ```

### Can't Save Program

**Symptom**:
```
?WRITE ERROR
```

**Solutions**:

1. **Check directory permissions**:
   ```bash
   ls -ld .
   chmod 755 .
   ```

2. **Check disk space**:
   ```bash
   df -h .
   ```

3. **Use valid filename**:
   ```basic
   SAVE "PROGRAM.BAS"    ' OK
   SAVE "PRO/GRAM.BAS"   ' May fail (invalid chars)
   ```

## Common Programming Mistakes

### Infinite Loops

**Problem**:
```basic
10 GOTO 10    ' Infinite loop
```

**Solution**: Press Ctrl+C to break, then fix logic

**Prevention**:
```basic
10 FOR I = 1 TO 100    ' Use counted loops
20   ' ... code ...
30 NEXT I
```

### Variable Name Confusion

**Problem**: Only first 2 characters matter
```basic
10 APPLE = 5
20 APPLY = 10
30 PRINT APPLE    ' Prints 10, not 5!
```

**Solution**: Use distinct 2-character prefixes
```basic
10 AP = 5        ' APple
20 AY = 10       ' ApplY
30 PRINT AP      ' Prints 5
```

### Forgetting Variable Types

**Problem**:
```basic
10 N = "JOHN"       ' N is numeric, needs N$
20 PRINT N
```

**Solution**: Use `$` suffix for strings
```basic
10 N$ = "JOHN"
20 PRINT N$
```

### Array Bounds

**Problem**:
```basic
10 DIM A(10)
20 FOR I = 1 TO 10
30   A(I) = I
40 NEXT I
```

**Subtle issue**: Arrays are 0-based, so `A(10)` has indices 0-10 (11 elements)

**Clarification**:
```basic
10 DIM A(10)        ' Creates A(0) to A(10)
20 FOR I = 0 TO 10  ' Use all 11 elements
30   A(I) = I
40 NEXT I
```

## Debugging Techniques

### Add Debug PRINT Statements

```basic
10 PRINT "STARTING"
20 X = 10
30 PRINT "X ="; X: REM Debug
40 Y = X * 2
50 PRINT "Y ="; Y: REM Debug
60 PRINT Y
```

### Use STOP for Breakpoints

```basic
10 FOR I = 1 TO 100
20   IF I = 50 THEN STOP
30   PRINT I
40 NEXT I
```

When STOP is hit, check variables in immediate mode:
```basic
PRINT I
PRINT A
PRINT A$
```

Then continue with:
```basic
CONT    ' Note: CONT may not be implemented
```

Or fix and:
```basic
RUN
```

### List Specific Lines

```basic
LIST 100-200    ' Show lines 100 to 200
```

### Check Variable Values

In immediate mode:
```basic
PRINT A
PRINT B$
PRINT C(5)
```

### Simplify Problem

Create minimal test case:
```basic
' Original complex program has error
' Create simple version:
10 A = 1
20 B = 2
30 PRINT A + B
```

### Verify Tokens

If line looks correct but won't parse:
```basic
' Delete and retype the line
DELETE 100
100 PRINT "HELLO"
```

## Getting Help

### Check Documentation

1. [User Manual](USER_MANUAL.md) - Language reference
2. [API Documentation](API_DOCUMENTATION.md) - Developer API
3. [Dialect Differences](DIALECT_DIFFERENCES.md) - Compatibility info

### Run Examples

```bash
dart run bin/basic.dart examples/hello_world.bas
```

Study working examples in `examples/` directory.

### Report Bugs

If you've found a genuine bug:

1. Create minimal reproduction:
   ```basic
   10 PRINT "REPRODUCE BUG"
   20 ' ... minimal code ...
   ```

2. Report at: https://github.com/anthropics/claude-code/issues
   - Include program listing
   - Include error message
   - Include expected vs actual behavior
   - Include Dart version: `dart --version`

## Common Error Messages Quick Reference

| Error | Meaning | Common Fix |
|-------|---------|------------|
| SYNTAX ERROR | Invalid statement | Check spelling, parentheses |
| TYPE MISMATCH | Wrong variable type | Use `$` for strings |
| DIVISION BY ZERO | Divide by zero | Check denominator |
| OUT OF MEMORY | Too many variables | Use CLEAR |
| OUT OF STRING SPACE | Too many strings | Reduce string operations |
| NEXT WITHOUT FOR | Mismatched loop | Fix FOR/NEXT pairs |
| RETURN WITHOUT GOSUB | Invalid RETURN | Use RETURN only after GOSUB |
| UNDEFINED LINE | Line doesn't exist | Check line numbers with LIST |
| BAD SUBSCRIPT | Array index invalid | Check bounds, DIM array |
| REDIMENSIONED ARRAY | Array DIMmed twice | Use CLEAR or different name |
| OUT OF DATA | READ past end of DATA | Add more DATA or check logic |
| ILLEGAL FUNCTION CALL | Invalid function arg | Check function requirements |
| UNDEFINED FUNCTION | Function not DEFined | Add DEF FN statement |

## Performance Tips

1. **Minimize string operations in loops**
2. **Reuse variables** instead of creating new ones
3. **Use appropriate array sizes**
4. **Avoid deep GOSUB nesting**
5. **Clear unused variables** with CLEAR

## Best Practices

1. **Use meaningful variable names** (within 2-char limit)
2. **Comment your code** with REM
3. **Use indentation** for readability
4. **Test incrementally** (don't write whole program at once)
5. **Save frequently** with SAVE
6. **Use LIST** to review code
7. **Keep functions simple** (DEF FN)
8. **Handle errors** (check for zero, array bounds, etc.)

## Conclusion

Most problems are solved by:

1. **Reading error messages carefully**
2. **Using LIST to review code**
3. **Adding debug PRINT statements**
4. **Testing with simple cases**
5. **Checking documentation**

When in doubt, start with a minimal working program and add complexity gradually.
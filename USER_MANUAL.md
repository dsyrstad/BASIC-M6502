# Microsoft BASIC 6502 - User Manual

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Basic Concepts](#basic-concepts)
4. [Statement Reference](#statement-reference)
5. [Function Reference](#function-reference)
6. [Operator Reference](#operator-reference)
7. [Error Messages](#error-messages)
8. [Program Examples](#program-examples)

## Introduction

This is a Dart implementation of Microsoft BASIC Version 1.1 for the 6502 microprocessor, faithfully recreating the BASIC interpreter that powered early personal computers including the Apple II, Commodore PET, and Ohio Scientific machines.

### Features

- **Authentic Commodore BASIC compatibility** - Runs classic BASIC programs
- **Microsoft 5-byte floating-point format** - Full precision arithmetic
- **String handling** with automatic garbage collection
- **Array support** - Up to 255 dimensions
- **User-defined functions** via DEF FN
- **File I/O** - LOAD, SAVE, VERIFY programs
- **Interactive editing** - Add, modify, and delete program lines
- **40-column output** - Classic screen formatting

### System Requirements

- Dart SDK 3.0.0 or later

## Getting Started

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd BASIC-M6502

# Run the BASIC interpreter
dart run bin/basic.dart
```

### Running the Interpreter

The interpreter starts in immediate mode, displaying the `READY.` prompt:

```
READY.
_
```

You can enter BASIC statements directly for immediate execution, or enter numbered lines to build a program.

### Your First Program

```basic
10 PRINT "HELLO, WORLD!"
20 END
RUN
```

Output:
```
HELLO, WORLD!
```

### Loading Example Programs

```basic
LOAD "examples/hello_world.bas"
LIST
RUN
```

## Basic Concepts

### Line Numbers

Programs consist of numbered lines from 0 to 63999. Lines are stored in ascending order.

```basic
10 REM This is line 10
20 REM This is line 20
```

To insert a line between existing lines, use an intermediate number:
```basic
15 REM This line goes between 10 and 20
```

### Immediate Mode vs Program Mode

**Immediate Mode**: Commands without line numbers execute immediately.
```basic
PRINT 2 + 2
```

**Program Mode**: Commands with line numbers are stored in memory.
```basic
10 PRINT 2 + 2
```

### Variables

#### Simple Variables

Variable names consist of:
- One or two characters
- First character must be a letter (A-Z)
- Second character (optional) can be a letter or digit (0-9)
- Suffix `$` denotes string variables

Examples:
```basic
A = 10          ' Numeric variable A
B2 = 20         ' Numeric variable B2
A$ = "HELLO"    ' String variable A$
Z9$ = "WORLD"   ' String variable Z9$
```

**Note**: Only the first two characters are significant. `APPLE` and `APRICOT` both refer to variable `AP`.

#### Arrays

Arrays must be dimensioned before use (except for default 10-element arrays):

```basic
10 DIM A(100)           ' 1D array: 0 to 100 (101 elements)
20 DIM B(10,10)         ' 2D array: 0-10 x 0-10
30 DIM C$(50)           ' String array: 0 to 50
```

Array indices are 0-based by default.

### Data Types

#### Numbers

All numbers are stored in Microsoft 5-byte floating-point format:
- Range: ±2.93873588E-39 to ±1.70141183E+38
- Precision: ~9 decimal digits

Number formats:
```basic
42              ' Integer notation
3.14159         ' Decimal notation
-123.456        ' Negative number
1.5E+10         ' Scientific notation (1.5 × 10^10)
-2.5E-3         ' Negative exponent (-0.0025)
```

#### Strings

Strings can be up to 255 characters long:
```basic
A$ = "HELLO"
B$ = ""                 ' Empty string
C$ = "A STRING WITH SPACES AND 123 NUMBERS"
```

String concatenation:
```basic
A$ = "HELLO"
B$ = " WORLD"
C$ = A$ + B$           ' C$ = "HELLO WORLD"
```

### Operators

#### Arithmetic Operators
- `+` Addition
- `-` Subtraction
- `*` Multiplication
- `/` Division
- `^` Exponentiation

#### Relational Operators
- `=` Equal
- `<>` Not equal
- `<` Less than
- `>` Greater than
- `<=` Less than or equal
- `>=` Greater than or equal

#### Logical Operators
- `AND` Logical AND
- `OR` Logical OR
- `NOT` Logical NOT

### Expression Evaluation

Operators are evaluated in this order (highest to lowest precedence):
1. Parentheses `()`
2. Functions
3. Exponentiation `^`
4. Negation `-` (unary)
5. Multiplication `*`, Division `/`
6. Addition `+`, Subtraction `-`
7. Relational operators `=`, `<>`, `<`, `>`, `<=`, `>=`
8. `NOT`
9. `AND`
10. `OR`

## Statement Reference

### Program Control

#### RUN
Executes the program from the beginning (or specified line).

**Syntax**: `RUN [line_number]`

```basic
RUN             ' Start from first line
RUN 100         ' Start from line 100
```

#### END
Terminates program execution and returns to immediate mode.

**Syntax**: `END`

```basic
100 END
```

#### STOP
Halts program execution and displays the line number where stopped.

**Syntax**: `STOP`

```basic
50 STOP         ' Displays: BREAK IN LINE 50
```

#### NEW
Erases the current program from memory.

**Syntax**: `NEW`

```basic
NEW             ' Deletes all program lines
```

#### CLEAR
Clears all variables and resets memory.

**Syntax**: `CLEAR`

```basic
CLEAR           ' Reset all variables to 0 or ""
```

### Flow Control

#### GOTO
Transfers control to the specified line number.

**Syntax**: `GOTO line_number`

```basic
10 PRINT "START"
20 GOTO 40
30 PRINT "SKIPPED"
40 PRINT "END"
```

#### GOSUB / RETURN
Calls a subroutine at the specified line number. RETURN returns to the statement after the GOSUB.

**Syntax**:
```basic
GOSUB line_number
RETURN
```

```basic
10 GOSUB 100
20 PRINT "BACK FROM SUBROUTINE"
30 END
100 PRINT "IN SUBROUTINE"
110 RETURN
```

#### IF...THEN
Executes a statement if the condition is true.

**Syntax**: `IF condition THEN statement`

```basic
10 IF A > 10 THEN PRINT "A IS LARGE"
20 IF B = 0 THEN GOTO 100
30 IF X$ = "YES" THEN GOSUB 200
```

Multiple conditions:
```basic
10 IF A > 0 AND A < 100 THEN PRINT "IN RANGE"
```

#### ON...GOTO / ON...GOSUB
Branches to one of several line numbers based on the value of an expression.

**Syntax**:
```basic
ON expression GOTO line1, line2, line3, ...
ON expression GOSUB line1, line2, line3, ...
```

```basic
10 INPUT "CHOICE (1-3)"; C
20 ON C GOTO 100, 200, 300
30 PRINT "INVALID"
40 END
100 PRINT "OPTION 1": GOTO 40
200 PRINT "OPTION 2": GOTO 40
300 PRINT "OPTION 3": GOTO 40
```

#### FOR...NEXT
Executes a loop a specified number of times.

**Syntax**:
```basic
FOR variable = start TO end [STEP increment]
...statements...
NEXT [variable]
```

```basic
10 FOR I = 1 TO 10
20   PRINT I
30 NEXT I

' With STEP
40 FOR J = 10 TO 1 STEP -1
50   PRINT J
60 NEXT J
```

Nested loops:
```basic
10 FOR I = 1 TO 5
20   FOR J = 1 TO 5
30     PRINT I*J;
40   NEXT J
50   PRINT
60 NEXT I
```

### Input/Output

#### PRINT
Outputs data to the screen.

**Syntax**: `PRINT [expression_list]`

```basic
PRINT "HELLO"                  ' Prints HELLO
PRINT A                        ' Prints value of A
PRINT "A ="; A                 ' Prints A = followed by value
PRINT A, B, C                  ' Prints in columns
PRINT A; B; C                  ' Prints without spacing
PRINT                          ' Prints blank line
```

Special formatting:
- `;` - No space between items
- `,` - Tab to next column (every 10 characters)
- Trailing `;` or `,` - Suppresses newline

#### INPUT
Reads data from the keyboard.

**Syntax**: `INPUT [prompt;] variable_list`

```basic
10 INPUT A                     ' Displays ? prompt
20 INPUT "YOUR NAME"; N$       ' Custom prompt
30 INPUT "X, Y"; X, Y          ' Multiple values
```

Multiple values separated by commas:
```
? 10, 20, 30
```

#### GET
Reads a single character from the keyboard without waiting for Enter.

**Syntax**: `GET variable$`

```basic
10 GET A$
20 IF A$ = "" THEN 10          ' Wait for keypress
30 PRINT "YOU PRESSED "; A$
```

#### DATA, READ, RESTORE
Stores and reads constant data within the program.

**Syntax**:
```basic
DATA constant_list
READ variable_list
RESTORE [line_number]
```

```basic
10 FOR I = 1 TO 5
20   READ N
30   PRINT N
40 NEXT I
50 DATA 10, 20, 30, 40, 50

' Reusing data
100 RESTORE
110 READ A
```

### Variable and Array Operations

#### LET
Assigns a value to a variable (LET is optional).

**Syntax**: `[LET] variable = expression`

```basic
10 LET A = 10
20 B = 20                      ' LET is optional
30 C$ = "HELLO"
40 D = A + B
```

#### DIM
Dimensions an array.

**Syntax**: `DIM array(size1[, size2, ...])`

```basic
10 DIM A(100)                  ' 101 elements: A(0) to A(100)
20 DIM B(10, 10)               ' 11x11 2D array
30 DIM C$(50)                  ' String array
```

**Note**: Arrays can have up to 255 dimensions.

#### DEF FN
Defines a user function.

**Syntax**: `DEF FN name(parameter) = expression`

```basic
10 DEF FN SQ(X) = X * X
20 PRINT FN SQ(5)              ' Prints 25

30 DEF FN AV(A, B) = (A + B) / 2
40 PRINT FN AV(10, 20)         ' Prints 15
```

String functions:
```basic
10 DEF FN UP$(S$) = CHR$(ASC(S$) - 32)
```

### File Operations

#### LOAD
Loads a program from disk.

**Syntax**: `LOAD filename`

```basic
LOAD "MYPROG.BAS"
```

#### SAVE
Saves the current program to disk.

**Syntax**: `SAVE filename`

```basic
SAVE "MYPROG.BAS"
```

#### VERIFY
Verifies that a saved program matches the program in memory.

**Syntax**: `VERIFY filename`

```basic
VERIFY "MYPROG.BAS"
```

### Extended I/O

#### OPEN
Opens a file or device for I/O.

**Syntax**: `OPEN file_number, device_number [, secondary_address] [, filename]`

```basic
10 OPEN 1, 8, 2, "DATA.SEQ,S,W"  ' Open for writing
```

#### CLOSE
Closes an open file.

**Syntax**: `CLOSE file_number`

```basic
10 CLOSE 1
```

#### PRINT#
Outputs data to a file.

**Syntax**: `PRINT# file_number, expression_list`

```basic
10 PRINT# 1, "DATA LINE"
```

#### INPUT#
Reads data from a file.

**Syntax**: `INPUT# file_number, variable_list`

```basic
10 INPUT# 1, A$
```

#### CMD
Redirects PRINT output to a file.

**Syntax**: `CMD file_number`

```basic
10 CMD 1
20 PRINT "THIS GOES TO FILE"
30 CLOSE 1
```

### Program Editing

#### LIST
Displays the program (or a range of lines).

**Syntax**: `LIST [start_line[-end_line]]`

```basic
LIST                ' List entire program
LIST 100            ' List line 100
LIST 100-200        ' List lines 100 to 200
LIST -100           ' List lines up to 100
LIST 100-           ' List lines from 100 to end
```

### Memory Access

#### PEEK
Reads a byte from memory.

**Syntax**: `PEEK(address)`

```basic
10 A = PEEK(1024)
```

#### POKE
Writes a byte to memory.

**Syntax**: `POKE address, value`

```basic
10 POKE 1024, 65          ' Write 'A' to screen memory
```

### System Integration

#### SYS
Calls a machine language subroutine (simulated).

**Syntax**: `SYS address`

```basic
10 SYS 49152              ' Call ML routine at $C000
```

#### USR
Calls a user-defined machine language function.

**Syntax**: `USR(argument)`

```basic
10 X = USR(100)
```

### Comments

#### REM
Adds a comment (ignored during execution).

**Syntax**: `REM comment`

```basic
10 REM This is a comment
20 PRINT "HELLO"          REM Comments can follow statements
```

## Function Reference

### Mathematical Functions

#### ABS
Returns the absolute value.

**Syntax**: `ABS(expression)`

```basic
PRINT ABS(-5)             ' Prints 5
PRINT ABS(3.14)           ' Prints 3.14
```

#### INT
Returns the integer part (rounds down).

**Syntax**: `INT(expression)`

```basic
PRINT INT(3.7)            ' Prints 3
PRINT INT(-3.7)           ' Prints -4
```

#### SGN
Returns the sign of a number (-1, 0, or 1).

**Syntax**: `SGN(expression)`

```basic
PRINT SGN(-5)             ' Prints -1
PRINT SGN(0)              ' Prints 0
PRINT SGN(5)              ' Prints 1
```

#### SQR
Returns the square root.

**Syntax**: `SQR(expression)`

```basic
PRINT SQR(16)             ' Prints 4
PRINT SQR(2)              ' Prints 1.41421356
```

#### RND
Returns a random number between 0 and 1.

**Syntax**: `RND(argument)`

```basic
10 X = RND(1)             ' Random number 0 <= X < 1
20 N = INT(RND(1) * 6) + 1  ' Random 1-6 (dice roll)
```

Arguments:
- `RND(1)` or `RND(positive)` - Next random number
- `RND(0)` - Repeat last random number
- `RND(negative)` - Reseed with negative value

### Trigonometric Functions

All angles are in radians.

#### SIN
Returns the sine.

**Syntax**: `SIN(expression)`

```basic
PRINT SIN(0)              ' Prints 0
PRINT SIN(3.14159/2)      ' Prints 1 (90 degrees)
```

#### COS
Returns the cosine.

**Syntax**: `COS(expression)`

```basic
PRINT COS(0)              ' Prints 1
PRINT COS(3.14159)        ' Prints -1 (180 degrees)
```

#### TAN
Returns the tangent.

**Syntax**: `TAN(expression)`

```basic
PRINT TAN(0)              ' Prints 0
```

#### ATN
Returns the arctangent.

**Syntax**: `ATN(expression)`

```basic
PRINT ATN(1)              ' Prints 0.785398163 (45 degrees)
```

### Exponential and Logarithmic

#### EXP
Returns e raised to the power.

**Syntax**: `EXP(expression)`

```basic
PRINT EXP(1)              ' Prints 2.71828183 (e)
PRINT EXP(0)              ' Prints 1
```

#### LOG
Returns the natural logarithm.

**Syntax**: `LOG(expression)`

```basic
PRINT LOG(2.71828183)     ' Prints 1
PRINT LOG(10)             ' Prints 2.30258509
```

### String Functions

#### LEN
Returns the length of a string.

**Syntax**: `LEN(string_expression)`

```basic
PRINT LEN("HELLO")        ' Prints 5
PRINT LEN("")             ' Prints 0
```

#### LEFT$
Returns leftmost characters.

**Syntax**: `LEFT$(string_expression, count)`

```basic
PRINT LEFT$("HELLO", 3)   ' Prints HEL
```

#### RIGHT$
Returns rightmost characters.

**Syntax**: `RIGHT$(string_expression, count)`

```basic
PRINT RIGHT$("HELLO", 3)  ' Prints LLO
```

#### MID$
Returns substring.

**Syntax**: `MID$(string_expression, start[, length])`

```basic
PRINT MID$("HELLO", 2, 3) ' Prints ELL (starts at position 1)
PRINT MID$("HELLO", 3)    ' Prints LLO (from position 3 to end)
```

#### CHR$
Returns character with the given ASCII code.

**Syntax**: `CHR$(code)`

```basic
PRINT CHR$(65)            ' Prints A
PRINT CHR$(13)            ' Prints newline
```

#### ASC
Returns ASCII code of first character.

**Syntax**: `ASC(string_expression)`

```basic
PRINT ASC("A")            ' Prints 65
PRINT ASC("HELLO")        ' Prints 72 (H)
```

#### STR$
Converts number to string.

**Syntax**: `STR$(expression)`

```basic
A$ = STR$(123)            ' A$ = " 123" (note leading space for positive)
B$ = STR$(-456)           ' B$ = "-456"
```

#### VAL
Converts string to number.

**Syntax**: `VAL(string_expression)`

```basic
PRINT VAL("123")          ' Prints 123
PRINT VAL("3.14")         ' Prints 3.14
PRINT VAL("12ABC")        ' Prints 12 (stops at non-digit)
```

### Screen Functions

#### TAB
Moves cursor to column position.

**Syntax**: `TAB(column)`

```basic
10 PRINT TAB(10); "COLUMN 10"
20 PRINT TAB(20); "COLUMN 20"
```

#### SPC
Prints specified number of spaces.

**Syntax**: `SPC(count)`

```basic
10 PRINT "A"; SPC(5); "B"  ' Prints A     B
```

## Operator Reference

### Arithmetic Operators

| Operator | Description | Example | Result |
|----------|-------------|---------|--------|
| `+` | Addition | `5 + 3` | 8 |
| `-` | Subtraction | `5 - 3` | 2 |
| `*` | Multiplication | `5 * 3` | 15 |
| `/` | Division | `6 / 3` | 2 |
| `^` | Exponentiation | `2 ^ 3` | 8 |
| `-` (unary) | Negation | `-5` | -5 |

### Relational Operators

| Operator | Description | Example | Result |
|----------|-------------|---------|--------|
| `=` | Equal | `5 = 5` | -1 (true) |
| `<>` | Not equal | `5 <> 3` | -1 (true) |
| `<` | Less than | `3 < 5` | -1 (true) |
| `>` | Greater than | `5 > 3` | -1 (true) |
| `<=` | Less than or equal | `5 <= 5` | -1 (true) |
| `>=` | Greater than or equal | `5 >= 5` | -1 (true) |

**Note**: In BASIC, true is -1 and false is 0.

### Logical Operators

| Operator | Description | Example | Result |
|----------|-------------|---------|--------|
| `AND` | Logical AND | `-1 AND -1` | -1 (true) |
| `OR` | Logical OR | `0 OR -1` | -1 (true) |
| `NOT` | Logical NOT | `NOT 0` | -1 (true) |

**Note**: Logical operators work on integer representations.

### String Operator

| Operator | Description | Example | Result |
|----------|-------------|---------|--------|
| `+` | Concatenation | `"HI" + "!!"` | "HI!!" |

## Error Messages

### Error Codes

| Code | Message | Description |
|------|---------|-------------|
| NF | NEXT WITHOUT FOR | NEXT statement without matching FOR |
| SN | SYNTAX ERROR | Invalid statement syntax |
| RG | RETURN WITHOUT GOSUB | RETURN without matching GOSUB |
| OD | OUT OF DATA | READ statement with no DATA remaining |
| FC | ILLEGAL FUNCTION CALL | Invalid function argument |
| OV | OVERFLOW | Number too large |
| OM | OUT OF MEMORY | Insufficient memory |
| UL | UNDEFINED LINE | GOTO/GOSUB to non-existent line |
| BS | BAD SUBSCRIPT | Array index out of range |
| DD | REDIMENSIONED ARRAY | Array already dimensioned |
| /0 | DIVISION BY ZERO | Attempted division by zero |
| ID | ILLEGAL DIRECT | Statement not allowed in immediate mode |
| TM | TYPE MISMATCH | Wrong variable type (string vs numeric) |
| OS | OUT OF STRING SPACE | No room for string |
| LS | STRING TOO LONG | String exceeds 255 characters |
| ST | STRING FORMULA TOO COMPLEX | Expression too complex |
| CN | CONTINUE ERROR | Cannot continue after error |
| UF | UNDEFINED FUNCTION | Function not defined with DEF FN |

### Error Handling

When an error occurs:
1. Program execution stops
2. Error message is displayed
3. Immediate mode is entered
4. Variables retain their values (in program mode)

Example:
```
?OUT OF DATA ERROR IN LINE 50
```

## Program Examples

### Example 1: Temperature Converter

```basic
10 REM TEMPERATURE CONVERTER
20 PRINT "CELSIUS TO FAHRENHEIT"
30 PRINT
40 INPUT "CELSIUS"; C
50 F = C * 9 / 5 + 32
60 PRINT C; "C ="; F; "F"
70 END
```

### Example 2: Prime Number Checker

```basic
10 REM PRIME NUMBER CHECKER
20 INPUT "NUMBER"; N
30 IF N < 2 THEN PRINT "NOT PRIME": END
40 FOR I = 2 TO SQR(N)
50   IF N / I = INT(N / I) THEN PRINT "NOT PRIME": END
60 NEXT I
70 PRINT "PRIME"
```

### Example 3: Simple Menu System

```basic
10 REM MENU SYSTEM
20 PRINT "1. OPTION A"
30 PRINT "2. OPTION B"
40 PRINT "3. OPTION C"
50 PRINT "4. QUIT"
60 INPUT "CHOICE"; C
70 ON C GOSUB 100, 200, 300, 400
80 IF C <> 4 THEN 20
90 END
100 PRINT "OPTION A SELECTED": RETURN
200 PRINT "OPTION B SELECTED": RETURN
300 PRINT "OPTION C SELECTED": RETURN
400 PRINT "GOODBYE": RETURN
```

### Example 4: Array Statistics

```basic
10 REM ARRAY STATISTICS
20 DIM A(100)
30 INPUT "HOW MANY NUMBERS"; N
40 FOR I = 1 TO N
50   INPUT "NUMBER"; A(I)
60 NEXT I
70 REM CALCULATE AVERAGE
80 S = 0
90 FOR I = 1 TO N
100   S = S + A(I)
110 NEXT I
120 AV = S / N
130 PRINT "AVERAGE ="; AV
140 REM FIND MIN AND MAX
150 MIN = A(1): MAX = A(1)
160 FOR I = 2 TO N
170   IF A(I) < MIN THEN MIN = A(I)
180   IF A(I) > MAX THEN MAX = A(I)
190 NEXT I
200 PRINT "MIN ="; MIN
210 PRINT "MAX ="; MAX
```

### Example 5: Simple Text Adventure

```basic
10 REM SIMPLE ADVENTURE
20 R = 1
30 PRINT "YOU ARE IN A ";
40 ON R GOTO 100, 200, 300
100 PRINT "DARK FOREST"
110 PRINT "EXITS: NORTH, EAST"
120 INPUT "GO"; D$
130 IF D$ = "NORTH" THEN R = 2: GOTO 30
140 IF D$ = "EAST" THEN R = 3: GOTO 30
150 PRINT "CANNOT GO THAT WAY": GOTO 120
200 PRINT "CAVE"
210 PRINT "EXITS: SOUTH"
220 INPUT "GO"; D$
230 IF D$ = "SOUTH" THEN R = 1: GOTO 30
240 PRINT "CANNOT GO THAT WAY": GOTO 220
300 PRINT "MEADOW"
310 PRINT "EXITS: WEST"
320 INPUT "GO"; D$
330 IF D$ = "WEST" THEN R = 1: GOTO 30
340 PRINT "CANNOT GO THAT WAY": GOTO 320
```

### Example 6: Bubble Sort

```basic
10 REM BUBBLE SORT
20 DIM A(100)
30 INPUT "HOW MANY NUMBERS"; N
40 FOR I = 1 TO N
50   A(I) = INT(RND(1) * 100)
60   PRINT A(I);
70 NEXT I
80 PRINT: PRINT "SORTING..."
90 FOR I = 1 TO N - 1
100   FOR J = I + 1 TO N
110     IF A(I) > A(J) THEN T = A(I): A(I) = A(J): A(J) = T
120   NEXT J
130 NEXT I
140 PRINT "SORTED:"
150 FOR I = 1 TO N
160   PRINT A(I);
170 NEXT I
```

## Tips and Tricks

### Saving Memory

1. Use short variable names (1-2 characters)
2. Remove unnecessary spaces
3. Use multi-statement lines with `:`
4. Remove REM statements from final version

### Optimizing Performance

1. Use integer values when possible
2. Minimize string operations
3. Avoid nested loops when possible
4. Use DEF FN for repeated calculations

### Debugging Techniques

1. Use PRINT statements to trace execution
2. Use STOP to pause at specific points
3. Check variable values in immediate mode after STOP
4. LIST specific line ranges to review code

### Common Pitfalls

1. **Forgetting to DIM arrays** - Arrays over 10 elements must be dimensioned
2. **Wrong variable type** - Don't mix strings and numbers
3. **Infinite loops** - Always ensure loop conditions will terminate
4. **GOTO/GOSUB to wrong line** - Check line numbers carefully
5. **String space exhaustion** - Be careful with string concatenation in loops

## Keyboard Shortcuts

In the interactive editor:
- **Enter** - Execute immediate command or store program line
- **Ctrl+C** - Interrupt running program (return to READY prompt)
- **Ctrl+D** - Exit interpreter

## Appendix A: ASCII Codes

Common ASCII codes for use with CHR$ and ASC:

| Code | Character | Description |
|------|-----------|-------------|
| 7 | BEL | Bell/beep |
| 8 | BS | Backspace |
| 9 | TAB | Tab |
| 10 | LF | Line feed |
| 13 | CR | Carriage return |
| 32 | SP | Space |
| 48-57 | 0-9 | Digits |
| 65-90 | A-Z | Uppercase letters |
| 97-122 | a-z | Lowercase letters |

## Appendix B: Memory Map

Default memory configuration:

| Range | Usage |
|-------|-------|
| 0-255 | Zero page (system variables) |
| 256-511 | Stack |
| 512+ | Program storage |
| Top down | String space |

Use PEEK and POKE to access memory directly.

## Appendix C: Commodore PETSCII

This implementation supports PETSCII characters for Commodore compatibility. Special characters can be entered using CHR$ codes.

---

For additional help and examples, see the `examples/` directory and the project README.
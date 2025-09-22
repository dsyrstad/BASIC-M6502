# Plan to Convert Microsoft BASIC 6502 to Dart

## Project Overview
Convert the ~7000 line MACRO-10 assembly code (m6502.asm) implementing Microsoft BASIC 1.1 for 6502 (Commodore version) into a modern Dart console application that can run BASIC programs via stdin/stdout.

## Architecture Design

### 1. Core Interpreter Structure
- `lib/interpreter/interpreter.dart` - Main interpreter loop (NEWSTT)
- `lib/interpreter/tokenizer.dart` - Convert BASIC text to tokens (CRUNCH)
- `lib/interpreter/parser.dart` - Parse and execute statements
- `lib/interpreter/expression_evaluator.dart` - Formula evaluation (FRMEVL)

### 2. Memory Management
- `lib/memory/memory.dart` - Simulated 64KB memory space
- `lib/memory/variables.dart` - Variable storage (simple & arrays)
- `lib/memory/strings.dart` - String management with garbage collection
- `lib/memory/program_storage.dart` - Store tokenized BASIC program

### 3. Math Package
- `lib/math/floating_point.dart` - 5-byte Microsoft floating-point format
- `lib/math/operations.dart` - Basic arithmetic (FADD, FSUB, FMUL, FDIV)
- `lib/math/functions.dart` - Transcendental functions (SIN, COS, TAN, LOG, EXP, etc.)
- `lib/math/conversions.dart` - Number format conversions (FIN, FOUT, INT)

### 4. BASIC Statements
- `lib/statements/` - One file per statement type:
  - `control_flow.dart` - FOR/NEXT, GOTO, GOSUB/RETURN, IF/THEN, ON
  - `io.dart` - PRINT, INPUT, GET
  - `data.dart` - DATA, READ, RESTORE
  - `program.dart` - RUN, LIST, NEW, CLEAR
  - `memory_ops.dart` - POKE, PEEK, DIM
  - `file_ops.dart` - LOAD, SAVE, VERIFY

### 5. I/O System
- `lib/io/console.dart` - Terminal I/O via stdin/stdout
- `lib/io/screen.dart` - 40-column screen emulation
- `lib/io/commodore_chars.dart` - PETSCII character mapping

### 6. Runtime Support
- `lib/runtime/stack.dart` - Runtime stack for FOR/GOSUB
- `lib/runtime/errors.dart` - Error handling and messages
- `lib/runtime/line_editor.dart` - Interactive line input

## Implementation Phases

### Phase 1: Foundation (Week 1)
1. Set up Dart project structure
2. Implement memory simulation
3. Create tokenizer for BASIC keywords
4. Build basic interpreter loop
5. Implement simple statements (PRINT, REM, END)

### Phase 2: Variables & Expressions (Week 2)
1. Variable storage (2-char names, 6 bytes each)
2. Expression evaluator with precedence
3. LET statement and assignments
4. String variables and descriptors
5. Array support (DIM)

### Phase 3: Math Package (Week 3)
1. Microsoft 5-byte float format
2. Basic arithmetic operations
3. Mathematical functions
4. Number conversions (STR$, VAL)

### Phase 4: Control Flow (Week 4)
1. GOTO and line number handling
2. IF/THEN conditional execution
3. FOR/NEXT loops with stack management
4. GOSUB/RETURN subroutines
5. ON GOTO/GOSUB

### Phase 5: I/O & Data (Week 5)
1. INPUT statement with prompts
2. PRINT with formatting (TAB, SPC, semicolons, commas)
3. DATA/READ/RESTORE
4. GET for single character input
5. Screen positioning (40-column mode)

### Phase 6: Program Management (Week 6)
1. LIST command with line numbers
2. NEW/CLEAR commands
3. LOAD/SAVE for program storage
4. Interactive editor (line replacement)
5. RUN with line number support

### Phase 7: Advanced Features (Week 7)
1. String functions (LEFT$, RIGHT$, MID$, CHR$, ASC)
2. PEEK/POKE memory access
3. User-defined functions (DEF FN)
4. Error handling and messages
5. String garbage collection

### Phase 8: Polish & Testing (Week 8)
1. Commodore BASIC compatibility
2. Performance optimization
3. Comprehensive test suite
4. Example BASIC programs
5. Documentation

## Key Technical Challenges

1. **Floating-Point Format**: Implement Microsoft's 5-byte format with proper rounding
2. **String Management**: Garbage collection with temporary strings
3. **Line Editor**: Interactive editing with Commodore-style interface
4. **Token Compatibility**: Match original token values for program compatibility
5. **40-Column Display**: Emulate Commodore screen width and formatting

## File Structure
```
basic_m6502_dart/
├── bin/
│   └── basic.dart          # Main entry point
├── lib/
│   ├── interpreter/        # Core interpreter
│   ├── memory/             # Memory management
│   ├── math/               # Math package
│   ├── statements/         # BASIC statements
│   ├── io/                 # I/O subsystem
│   ├── runtime/            # Runtime support
│   └── basic_interpreter.dart  # Main API
├── test/                   # Unit tests
├── examples/               # Sample BASIC programs
└── pubspec.yaml           # Dependencies
```

## Testing Strategy
- Unit tests for each component
- Integration tests with classic BASIC programs
- Compatibility tests with Commodore BASIC samples
- Performance benchmarks against original

## Technical Implementation Details

### Memory Layout (Based on Original)
- **Page Zero (0-255)**: Critical variables and pointers
- **Page One (256-511)**: Stack
- **Program Storage**: Tokenized BASIC lines with links
- **Variable Storage**: Simple variables (6 bytes each)
- **Array Storage**: Multi-dimensional arrays
- **String Space**: Grows down from top of memory

### Data Structures

#### Program Line Format
- 2 bytes: Link to next line (0 = end)
- 2 bytes: Line number
- N bytes: Tokenized statement(s)
- 1 byte: Zero terminator

#### Variable Format
- 2 bytes: Variable name (2 ASCII chars)
- 4 bytes: Value (float or string descriptor)

#### String Descriptor
- 1 byte: Length
- 2 bytes: Pointer to string data

### Token Values (Must Match Original)
- Reserved words: 128-255
- Operators included in token range
- Special handling for multi-char operators

### Statement Execution Flow
1. NEWSTT fetches next statement
2. Checks for line terminator
3. Dispatches based on token value
4. Statement executes and returns to NEWSTT
5. Control flow statements modify execution pointer

### Expression Evaluation Algorithm
1. Push dummy precedence on stack
2. Read lexeme (constant, function, variable, or parenthesized expression)
3. Check for operator
4. Compare precedence with stack
5. Apply operators based on precedence
6. Continue until expression complete

### Error Handling
- 2-character error codes (matching original)
- Error messages for extended errors
- Stack reset on error
- Variables remain intact

This plan creates a faithful recreation of Microsoft BASIC while leveraging Dart's modern features for maintainability and performance.

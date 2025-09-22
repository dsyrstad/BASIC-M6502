# Microsoft BASIC 6502 Dart Implementation

A faithful Dart recreation of Microsoft BASIC Version 1.1 for the 6502 microprocessor, originally developed in 1976-1978. This interpreter powered early personal computers including the Commodore PET, Apple II, Ohio Scientific, and KIM-1.

## Project Goal

Convert the ~7000 line MACRO-10 assembly code (`m6502.asm`) into a modern, maintainable Dart console application while preserving the original behavior and quirks of the historical BASIC interpreter.

## Features

### Implemented
- [ ] Core interpreter loop
- [ ] Tokenizer and parser
- [ ] Memory management (64KB simulation)
- [ ] Variable storage (simple and arrays)
- [ ] Expression evaluation with operator precedence
- [ ] Microsoft 5-byte floating-point arithmetic
- [ ] String handling with garbage collection

### BASIC Statements (In Progress)
- [ ] Program control: RUN, LIST, NEW, CLEAR
- [ ] Flow control: GOTO, GOSUB/RETURN, IF/THEN, FOR/NEXT, ON
- [ ] I/O: PRINT, INPUT, GET, DATA/READ/RESTORE
- [ ] Math functions: SIN, COS, TAN, ATN, LOG, EXP, SQR, INT, ABS, SGN, RND
- [ ] String functions: LEFT$, RIGHT$, MID$, CHR$, ASC, LEN, STR$, VAL
- [ ] Memory: PEEK, POKE, DIM
- [ ] User functions: DEF FN
- [ ] File operations: LOAD, SAVE, VERIFY

## Architecture

The project maintains a structure similar to the original assembly code while leveraging Dart's modern features:

```
lib/
├── interpreter/     # Core interpreter and tokenizer
├── memory/         # 64KB memory simulation and variable storage
├── math/           # Microsoft floating-point implementation
├── statements/     # BASIC statement implementations
├── io/             # Console and screen emulation
└── runtime/        # Stack management and error handling
```

## Usage

```bash
# Run the BASIC interpreter
dart run

# Run a BASIC program from file
dart run < program.bas

# Interactive mode
dart run
> 10 PRINT "HELLO WORLD"
> 20 GOTO 10
> RUN
```

## Compatibility

This implementation aims for behavioral compatibility with the Commodore PET version of Microsoft BASIC 1.1, including:
- 40-column screen width
- 2-character variable names
- 5-byte floating-point format
- PETSCII character support
- Original error messages and codes

## Development Status

This is an active port of historical code. See `claude_tasks.md` for detailed implementation progress.

## Historical Context

This BASIC interpreter represents Microsoft's first major product and established patterns that influenced later Microsoft software. The original was written in MACRO-10 assembly for cross-compilation to 6502 machine code on a DEC PDP-10 mainframe.

## License

This implementation is based on the historical Microsoft BASIC 6502 source code. Please refer to the original licensing terms for the assembly code.
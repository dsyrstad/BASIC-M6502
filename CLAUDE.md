# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the historical source code for Microsoft BASIC Version 1.1 for the 6502 microprocessor (1976-1978). The single file `m6502.asm` contains the complete 8KB BASIC interpreter that powered early personal computers including the Apple II, Commodore PET, Ohio Scientific, and KIM-1.

## Assembly Language Format

The code is written in **MACRO-10 assembler syntax** for the DEC PDP-10 mainframe. This is NOT standard 6502 assembly - it's a cross-assembler that generates 6502 machine code.

Key syntax elements:
- **Directives**: `TITLE`, `SUBTTL`, `SEARCH`, `ORG`, `RADIX`, `SALL`, `DEFINE`, `IFE`/`IFN`, `IRPC`, `XWD`, `EXP`, `PRINTX`
- **Octal notation**: Uses `^O` prefix (e.g., `^O377` = 255 decimal)
- **Macros**: Extensive macro system simulates 6502 instructions (`LDAI`, `LDYI`, `LDWD`, `STWD`, etc.)
- **Labels**: End with `:` (single) or `::` (global)
- **Comments**: Start with `;`

## Build Configuration

There is no modern build system. The code requires conditional compilation flags:

**REALIO** - Target platform selector:
- `0` = PDP-10 simulator
- `1` = MOS Technology KIM-1
- `2` = Ohio Scientific (OSI)
- `3` = Commodore PET
- `4` = Apple II
- `5` = STM

**Feature flags**:
- `ROMSW` - ROM vs RAM configuration
- `INTPRC` - Integer array support
- `ADDPRC` - Additional floating-point precision
- `DISKO` - Disk I/O support (LOAD/SAVE commands)
- `EXTIO` - Extended I/O operations
- `TIME` - Clock/timer support

## Code Architecture

### Memory Layout
- **Page Zero** (0-255): Critical variables and pointers for 6502 efficiency
- **Stack** (256-511): Hardware stack and BASIC expression stack
- **ROM/RAM split**: Code at `ROMLOC` (typically 0x2000 or 0x4000), variables at `RAMLOC`

### Major Components (by SUBTTL sections)

1. **Initialization** (`INIT` at line 6703): System startup, memory configuration
2. **Statement Dispatcher** (`NEWSTT`): Main interpreter loop
3. **Expression Evaluator** (`FRMEVL`): Formula parsing and evaluation with operator precedence
4. **Variable Management** (`PTRGET`): Simple and array variable storage
5. **String Handling**: Garbage collection, descriptor management
6. **Math Package**: Floating-point arithmetic, transcendental functions
7. **I/O Routines**: Platform-specific character I/O abstraction

### Key Entry Points
- `START` (line 732): Program entry, jumps to `INIT`
- `INIT` (line 6703): System initialization
- `READY`: Interactive prompt handler
- `NEWSTT`: Statement fetch and execute loop

### Data Structures
- **Variables**: 6 bytes each (2 name, 4 value)
- **Strings**: 3-byte descriptors (length + pointer)
- **Line format**: Link pointer (2), line number (2), tokens, null terminator

## Historical Context

This code represents Microsoft's first major product and established patterns still visible in later Microsoft software. The multi-platform conditional compilation approach was innovative for 1976-1978. Understanding this code requires knowledge of both 6502 architecture and PDP-10 MACRO-10 assembler conventions.

## Working with This Code

This is historical/archival code - not intended for modern compilation or execution. Analysis should focus on:
- Understanding early software engineering practices
- Studying the BASIC interpreter implementation
- Historical research on personal computing origins
- Educational purposes regarding language interpreter design

The code cannot be assembled without a PDP-10 MACRO-10 assembler or compatible cross-assembler tools from the 1970s era.
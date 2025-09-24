# Microsoft BASIC 6502 to Dart Conversion - Task List

## Project Setup
- [x] Create new Dart project structure
- [x] Set up pubspec.yaml with dependencies
- [x] Create directory structure as per plan
- [x] Set up Git repository and initial commit
- [x] Create README.md with project overview

## Phase 1: Foundation

### Memory System
- [x] Create `lib/memory/memory.dart` with 64KB array
- [x] Implement memory read/write operations
- [x] Define memory regions (zero page, stack, program, variables)
- [x] Create memory dump/debug utilities
- [x] Write unit tests for memory operations

### Tokenizer
- [x] Create `lib/interpreter/tokenizer.dart`
- [x] Define token constants (128-255 for reserved words)
- [x] Implement keyword recognition from RESLST
- [x] Handle multi-character operators
- [x] Support "GO TO" special case handling
- [x] Implement line tokenization (CRUNCH equivalent)
- [x] Write unit tests for tokenizer

### Basic Interpreter Loop
- [x] Create `lib/interpreter/interpreter.dart`
- [x] Implement NEWSTT main loop equivalent
- [x] Handle direct mode vs program mode
- [x] Implement CHRGET/CHRGOT character fetch
- [x] Create text pointer management
- [x] Write unit tests for interpreter loop

### Simple Statements
- [x] Implement REM statement (no-op)
- [x] Implement END statement
- [x] Implement PRINT with expression evaluation
- [x] Create statement dispatcher
- [x] Write integration tests for simple programs

## Phase 2: Variables & Expressions

### Variable Storage
- [x] Create `lib/memory/variables.dart`
- [x] Implement 2-character variable names
- [x] Create 6-byte variable storage format
- [x] Implement variable lookup (PTRGET equivalent)
- [x] Handle variable creation
- [x] Write unit tests for variable operations

### Expression Evaluator
- [x] Create `lib/interpreter/expression_evaluator.dart`
- [x] Implement FRMEVL algorithm with stack
- [x] Handle operator precedence
- [x] Support parentheses
- [x] Implement numeric constants
- [x] Support variable references
- [x] Write unit tests for expressions

### LET Statement
- [x] Implement LET statement
- [x] Support implicit LET (assignment without LET)
- [x] Handle string assignments
- [x] Handle numeric assignments
- [x] Write tests for various assignments

### String System
- [x] Create `lib/memory/strings.dart`
- [x] Implement 3-byte string descriptors
- [x] Create string space management
- [x] Implement temporary string handling
- [x] Add string comparison operations
- [x] Write unit tests for strings

### Array Support
- [x] Implement DIM statement
- [x] Create array storage format
- [x] Support multi-dimensional arrays
- [x] Implement array access in expressions
- [x] Handle array bounds checking
- [x] Write unit tests for arrays

## Phase 3: Math Package

### Floating-Point Format
- [x] Create `lib/math/floating_point.dart`
- [x] Implement Microsoft 5-byte float format
- [x] Create pack/unpack operations
- [x] Implement normalization
- [x] Handle special cases (zero, overflow)
- [x] Write unit tests for float format

### Basic Arithmetic
- [x] Create `lib/math/operations.dart`
- [x] Implement FADD (addition)
- [x] Implement FSUB (subtraction)
- [x] Implement FMUL (multiplication)
- [x] Implement FDIV (division)
- [x] Implement negation
- [x] Handle overflow/underflow
- [x] Write unit tests for arithmetic

### Math Functions
- [x] Create `lib/math/functions.dart`
- [x] Implement SIN function
- [x] Implement COS function
- [x] Implement TAN function
- [x] Implement ATN function
- [x] Implement LOG function
- [x] Implement EXP function
- [x] Implement SQR function
- [x] Implement RND function
- [x] Implement INT function
- [x] Implement ABS function
- [x] Implement SGN function
- [x] Write unit tests for each function

### Number Conversions
- [x] Create `lib/math/conversions.dart`
- [x] Implement FIN (string to float)
- [x] Implement FOUT (float to string)
- [x] Implement STR$ function
- [x] Implement VAL function
- [x] Handle different number formats
- [x] Write unit tests for conversions

## Phase 4: Control Flow

### Line Number Management
- [x] Create line number table
- [x] Implement line lookup
- [x] Support line insertion/deletion
- [ ] Handle line renumbering (if needed)
- [x] Write unit tests for line management

### GOTO Statement
- [x] Implement GOTO statement
- [x] Create line search algorithm
- [x] Handle undefined line errors
- [ ] Support computed GOTO
- [x] Write tests for GOTO

### IF/THEN Statement
- [x] Implement IF statement
- [x] Support relational operators (<, >, =, <=, >=, <>)
- [x] Implement THEN clause
- [x] Support IF without THEN (implicit)
- [ ] Handle nested IF statements
- [x] Write tests for conditionals

### FOR/NEXT Loops
- [x] Create `lib/runtime/stack.dart` for loop stack
- [x] Implement FOR statement
- [x] Create 16-byte FOR stack entry
- [x] Implement NEXT statement
- [x] Handle STEP clause
- [x] Support nested loops
- [x] Implement loop variable lookup (FNDFOR)
- [x] Write tests for loops

### GOSUB/RETURN
- [x] Implement GOSUB statement
- [x] Create 5-byte GOSUB stack entry
- [x] Implement RETURN statement
- [x] Handle stack unwinding
- [x] Support nested subroutines
- [x] Write tests for subroutines

### ON Statement
- [x] Implement ON GOTO
- [x] Implement ON GOSUB
- [x] Handle expression evaluation
- [x] Support multiple targets
- [x] Write tests for ON statements

## Phase 5: I/O & Data

### INPUT Statement
- [x] Implement INPUT statement
- [x] Support prompts (? and custom)
- [x] Handle multiple variables
- [x] Support string and numeric input
- [x] Implement input validation
- [x] Handle redo from start
- [x] Write tests for INPUT

### PRINT Formatting
- [x] Enhance PRINT statement
- [x] Implement semicolon separator (no spacing)
- [x] Implement comma separator (tab zones)
- [x] Implement TAB() function
- [x] Implement SPC() function
- [ ] Support PRINT USING (if applicable)
- [x] Handle 40-column formatting
- [x] Write tests for PRINT formatting

### DATA/READ/RESTORE
- [x] Implement DATA statement
- [x] Create data pointer management
- [x] Implement READ statement
- [x] Implement RESTORE statement
- [x] Handle OUT OF DATA error
- [x] Support mixed data types
- [x] Write tests for DATA operations

### GET Statement
- [x] Implement GET statement
- [x] Create single-character input
- [x] Handle keyboard buffer
- [x] Support non-blocking input
- [x] Write tests for GET

### Screen Emulation
- [x] Create `lib/io/screen.dart`
- [x] Implement 40-column mode
- [x] Handle cursor positioning
- [x] Support screen scrolling
- [x] Implement clear screen
- [x] Write tests for screen operations

## Phase 6: Program Management

### LIST Command
- [x] Implement LIST statement
- [x] Handle token detokenization
- [x] Format output properly
- [x] Support line range specification
- [ ] Support LIST to device (if needed)
- [ ] Write tests for LIST

### NEW/CLEAR Commands
- [x] Implement NEW command
- [x] Implement CLEAR command
- [x] Handle memory initialization
- [x] Reset variables and pointers
- [x] Clear stack properly
- [x] Write tests for NEW/CLEAR

### LOAD/SAVE Commands
- [x] Implement SAVE command
- [x] Create program file format
- [x] Implement LOAD command
- [ ] Handle file I/O errors
- [ ] Support VERIFY command
- [ ] Write tests for file operations

### Line Editor
- [x] Create `lib/runtime/line_editor.dart` (integrated in interpreter)
- [x] Implement line insertion
- [x] Implement line deletion
- [x] Implement line replacement
- [ ] Handle immediate mode
- [ ] Support line editing shortcuts
- [ ] Write tests for editor

### RUN Command
- [x] Implement RUN statement
- [x] Support RUN with line number
- [x] Handle variable clearing
- [x] Reset stack and pointers
- [x] Initialize runtime state
- [ ] Write tests for RUN

## Phase 7: Advanced Features

### String Functions
- [x] Implement LEFT$ function
- [x] Implement RIGHT$ function
- [x] Implement MID$ function
- [x] Implement CHR$ function
- [x] Implement ASC function
- [x] Implement LEN function
- [x] Support string concatenation
- [x] Write tests for string functions

### Memory Access
- [ ] Implement PEEK function
- [ ] Implement POKE statement
- [ ] Handle memory boundaries
- [ ] Support PEEK/POKE of system areas
- [ ] Write tests for memory access

### User-Defined Functions
- [ ] Implement DEF FN statement
- [ ] Create function storage
- [ ] Implement FN calls
- [ ] Support parameter passing
- [ ] Handle function scope
- [ ] Write tests for user functions

### Error Handling
- [ ] Create `lib/runtime/errors.dart`
- [ ] Implement all error codes from ERRTAB
- [ ] Create error messages (2-char and long)
- [ ] Implement error recovery
- [ ] Support ON ERROR (if applicable)
- [ ] Write tests for error handling

### Garbage Collection
- [ ] Implement string garbage collection
- [ ] Handle temporary strings
- [ ] Implement GARBAG algorithm
- [ ] Support forced collection
- [ ] Optimize collection performance
- [ ] Write tests for garbage collection

## Phase 8: Polish & Testing

### Commodore Compatibility
- [ ] Create `lib/io/commodore_chars.dart`
- [ ] Implement PETSCII character set
- [ ] Support special Commodore characters
- [ ] Handle screen codes vs ASCII
- [ ] Implement Commodore-specific features
- [ ] Write compatibility tests

### Performance Optimization
- [ ] Profile interpreter performance
- [ ] Optimize hot paths
- [ ] Improve memory access patterns
- [ ] Cache frequently used values
- [ ] Optimize expression evaluation
- [ ] Benchmark against targets

### Test Suite
- [ ] Create comprehensive unit tests
- [ ] Write integration tests
- [ ] Port classic BASIC programs for testing
- [ ] Create regression test suite
- [ ] Implement performance benchmarks
- [ ] Set up CI/CD pipeline

### Example Programs
- [ ] Create `examples/` directory
- [ ] Port classic BASIC games
- [ ] Create tutorial programs
- [ ] Add benchmark programs
- [ ] Include Commodore BASIC samples
- [ ] Write program documentation

### Documentation
- [ ] Write user manual
- [ ] Create API documentation
- [ ] Document BASIC dialect differences
- [ ] Create migration guide from 6502
- [ ] Write developer documentation
- [ ] Create troubleshooting guide

## Additional Features

### Extended I/O (if time permits)
- [ ] Implement OPEN statement
- [ ] Implement CLOSE statement
- [ ] Implement PRINT# statement
- [ ] Implement INPUT# statement
- [ ] Implement CMD statement
- [ ] Support device numbers

### System Integration
- [ ] Implement SYS statement (simulated)
- [ ] Implement USR function
- [ ] Support machine code interface
- [ ] Handle system calls
- [ ] Write tests for system integration

### Debugging Features
- [ ] Add TRON/TROFF statements
- [ ] Implement breakpoints
- [ ] Create variable watch
- [ ] Add step-through debugging
- [ ] Implement memory viewer
- [ ] Create performance profiler

## Testing Milestones

### Milestone 1: Basic Programs Run
- [ ] "HELLO WORLD" program works
- [ ] Simple calculations work
- [ ] Variable assignment works
- [ ] Basic PRINT formatting works

### Milestone 2: Control Flow Works
- [ ] Loops execute correctly
- [ ] Conditionals branch properly
- [ ] Subroutines work
- [ ] Line numbers resolve

### Milestone 3: Full Compatibility
- [ ] All statements implemented
- [ ] All functions work
- [ ] Error handling complete
- [ ] I/O fully functional

### Milestone 4: Production Ready
- [ ] Performance acceptable
- [ ] Memory management stable
- [ ] Documentation complete
- [ ] Test coverage > 90%

## Notes
- Each checkbox represents a discrete task that can be completed independently
- Tasks are ordered by dependency where possible
- Some tasks may be worked on in parallel
- Additional subtasks may be discovered during implementation
- Regular testing should accompany each implementation task

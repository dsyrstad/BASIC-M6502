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
- [x] Implement basic PRINT (text only)
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
- [ ] Implement LET statement
- [ ] Support implicit LET (assignment without LET)
- [ ] Handle string assignments
- [ ] Handle numeric assignments
- [ ] Write tests for various assignments

### String System
- [ ] Create `lib/memory/strings.dart`
- [ ] Implement 3-byte string descriptors
- [ ] Create string space management
- [ ] Implement temporary string handling
- [ ] Add string comparison operations
- [ ] Write unit tests for strings

### Array Support
- [ ] Implement DIM statement
- [ ] Create array storage format
- [ ] Support multi-dimensional arrays
- [ ] Implement array access in expressions
- [ ] Handle array bounds checking
- [ ] Write unit tests for arrays

## Phase 3: Math Package

### Floating-Point Format
- [ ] Create `lib/math/floating_point.dart`
- [ ] Implement Microsoft 5-byte float format
- [ ] Create pack/unpack operations
- [ ] Implement normalization
- [ ] Handle special cases (zero, overflow)
- [ ] Write unit tests for float format

### Basic Arithmetic
- [ ] Create `lib/math/operations.dart`
- [ ] Implement FADD (addition)
- [ ] Implement FSUB (subtraction)
- [ ] Implement FMUL (multiplication)
- [ ] Implement FDIV (division)
- [ ] Implement negation
- [ ] Handle overflow/underflow
- [ ] Write unit tests for arithmetic

### Math Functions
- [ ] Create `lib/math/functions.dart`
- [ ] Implement SIN function
- [ ] Implement COS function
- [ ] Implement TAN function
- [ ] Implement ATN function
- [ ] Implement LOG function
- [ ] Implement EXP function
- [ ] Implement SQR function
- [ ] Implement RND function
- [ ] Implement INT function
- [ ] Implement ABS function
- [ ] Implement SGN function
- [ ] Write unit tests for each function

### Number Conversions
- [ ] Create `lib/math/conversions.dart`
- [ ] Implement FIN (string to float)
- [ ] Implement FOUT (float to string)
- [ ] Implement STR$ function
- [ ] Implement VAL function
- [ ] Handle different number formats
- [ ] Write unit tests for conversions

## Phase 4: Control Flow

### Line Number Management
- [ ] Create line number table
- [ ] Implement line lookup
- [ ] Support line insertion/deletion
- [ ] Handle line renumbering (if needed)
- [ ] Write unit tests for line management

### GOTO Statement
- [ ] Implement GOTO statement
- [ ] Create line search algorithm
- [ ] Handle undefined line errors
- [ ] Support computed GOTO
- [ ] Write tests for GOTO

### IF/THEN Statement
- [ ] Implement IF statement
- [ ] Support relational operators (<, >, =, <=, >=, <>)
- [ ] Implement THEN clause
- [ ] Support IF without THEN (implicit)
- [ ] Handle nested IF statements
- [ ] Write tests for conditionals

### FOR/NEXT Loops
- [ ] Create `lib/runtime/stack.dart` for loop stack
- [ ] Implement FOR statement
- [ ] Create 16-byte FOR stack entry
- [ ] Implement NEXT statement
- [ ] Handle STEP clause
- [ ] Support nested loops
- [ ] Implement loop variable lookup (FNDFOR)
- [ ] Write tests for loops

### GOSUB/RETURN
- [ ] Implement GOSUB statement
- [ ] Create 5-byte GOSUB stack entry
- [ ] Implement RETURN statement
- [ ] Handle stack unwinding
- [ ] Support nested subroutines
- [ ] Write tests for subroutines

### ON Statement
- [ ] Implement ON GOTO
- [ ] Implement ON GOSUB
- [ ] Handle expression evaluation
- [ ] Support multiple targets
- [ ] Write tests for ON statements

## Phase 5: I/O & Data

### INPUT Statement
- [ ] Implement INPUT statement
- [ ] Support prompts (? and custom)
- [ ] Handle multiple variables
- [ ] Support string and numeric input
- [ ] Implement input validation
- [ ] Handle redo from start
- [ ] Write tests for INPUT

### PRINT Formatting
- [ ] Enhance PRINT statement
- [ ] Implement semicolon separator (no spacing)
- [ ] Implement comma separator (tab zones)
- [ ] Implement TAB() function
- [ ] Implement SPC() function
- [ ] Support PRINT USING (if applicable)
- [ ] Handle 40-column formatting
- [ ] Write tests for PRINT formatting

### DATA/READ/RESTORE
- [ ] Implement DATA statement
- [ ] Create data pointer management
- [ ] Implement READ statement
- [ ] Implement RESTORE statement
- [ ] Handle OUT OF DATA error
- [ ] Support mixed data types
- [ ] Write tests for DATA operations

### GET Statement
- [ ] Implement GET statement
- [ ] Create single-character input
- [ ] Handle keyboard buffer
- [ ] Support non-blocking input
- [ ] Write tests for GET

### Screen Emulation
- [ ] Create `lib/io/screen.dart`
- [ ] Implement 40-column mode
- [ ] Handle cursor positioning
- [ ] Support screen scrolling
- [ ] Implement clear screen
- [ ] Write tests for screen operations

## Phase 6: Program Management

### LIST Command
- [ ] Implement LIST statement
- [ ] Support line range specification
- [ ] Handle token detokenization
- [ ] Format output properly
- [ ] Support LIST to device (if needed)
- [ ] Write tests for LIST

### NEW/CLEAR Commands
- [ ] Implement NEW command
- [ ] Implement CLEAR command
- [ ] Handle memory initialization
- [ ] Reset variables and pointers
- [ ] Clear stack properly
- [ ] Write tests for NEW/CLEAR

### LOAD/SAVE Commands
- [ ] Implement SAVE command
- [ ] Create program file format
- [ ] Implement LOAD command
- [ ] Handle file I/O errors
- [ ] Support VERIFY command
- [ ] Write tests for file operations

### Line Editor
- [ ] Create `lib/runtime/line_editor.dart`
- [ ] Implement line insertion
- [ ] Implement line deletion
- [ ] Implement line replacement
- [ ] Handle immediate mode
- [ ] Support line editing shortcuts
- [ ] Write tests for editor

### RUN Command
- [ ] Implement RUN statement
- [ ] Support RUN with line number
- [ ] Handle variable clearing
- [ ] Reset stack and pointers
- [ ] Initialize runtime state
- [ ] Write tests for RUN

## Phase 7: Advanced Features

### String Functions
- [ ] Implement LEFT$ function
- [ ] Implement RIGHT$ function
- [ ] Implement MID$ function
- [ ] Implement CHR$ function
- [ ] Implement ASC function
- [ ] Implement LEN function
- [ ] Support string concatenation
- [ ] Write tests for string functions

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

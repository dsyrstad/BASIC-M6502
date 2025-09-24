/// Runtime stack management for FOR/NEXT loops and GOSUB/RETURN.
///
/// Manages the runtime stack equivalent to the original 6502 implementation.
/// FOR loops use 16-byte stack entries, GOSUB uses 5-byte entries.
library;

import '../memory/memory.dart';
import '../memory/variables.dart';

/// Stack entry types
enum StackEntryType {
  forLoop(0x81), // FOR loop entry type (matches original)
  gosub(0x8D); // GOSUB entry type (matches original)

  const StackEntryType(this.typeMarker);
  final int typeMarker;
}

/// FOR loop stack entry (16 bytes total)
class ForLoopEntry {
  final String variableName; // Loop variable name (2 chars)
  final double stepValue; // STEP value (5 bytes float)
  final double limitValue; // TO limit value (5 bytes float)
  final int lineNumber; // Line number of FOR statement
  final int textPointer; // Position after FOR statement

  ForLoopEntry({
    required this.variableName,
    required this.stepValue,
    required this.limitValue,
    required this.lineNumber,
    required this.textPointer,
  });

  @override
  String toString() {
    return 'FOR $variableName TO $limitValue STEP $stepValue (line $lineNumber)';
  }
}

/// GOSUB stack entry (5 bytes total)
class GosubEntry {
  final int lineNumber; // Return line number
  final int textPointer; // Return text pointer

  GosubEntry({required this.lineNumber, required this.textPointer});

  @override
  String toString() {
    return 'GOSUB return to line $lineNumber';
  }
}

/// Runtime stack manager
///
/// Implements the stack management for FOR/NEXT loops and GOSUB/RETURN
/// statements, matching the behavior of the original 6502 implementation.
class RuntimeStack {
  final Memory _memory;
  final VariableStorage _variables;

  /// Stack entries (grows downward like original)
  final List<dynamic> _stack = [];

  /// Maximum stack depth to prevent infinite recursion
  static const int maxStackDepth = 256;

  RuntimeStack(this._memory, this._variables);

  /// Push a FOR loop entry onto the stack
  void pushForLoop(
    String variableName,
    double stepValue,
    double limitValue,
    int lineNumber,
    int textPointer,
  ) {
    if (_stack.length >= maxStackDepth) {
      throw StackException('OUT OF MEMORY - Stack overflow');
    }

    final entry = ForLoopEntry(
      variableName: variableName,
      stepValue: stepValue,
      limitValue: limitValue,
      lineNumber: lineNumber,
      textPointer: textPointer,
    );

    _stack.add(entry);
  }

  /// Push a GOSUB entry onto the stack
  void pushGosub(int lineNumber, int textPointer) {
    if (_stack.length >= maxStackDepth) {
      throw StackException('OUT OF MEMORY - Stack overflow');
    }

    final entry = GosubEntry(lineNumber: lineNumber, textPointer: textPointer);

    _stack.add(entry);
  }

  /// Find FOR loop entry for a variable (FNDFOR equivalent)
  ///
  /// Searches the stack for a FOR loop with the given variable name.
  /// Returns the entry if found, null otherwise.
  ForLoopEntry? findForLoop(String variableName) {
    // Search from top of stack downward
    for (int i = _stack.length - 1; i >= 0; i--) {
      final entry = _stack[i];
      if (entry is ForLoopEntry && entry.variableName == variableName) {
        return entry;
      }
    }
    return null;
  }

  /// Pop FOR loop entry for a variable
  ///
  /// Removes all stack entries down to and including the FOR loop
  /// for the specified variable. This matches the original behavior
  /// where NEXT pops everything above the matching FOR.
  ForLoopEntry? popForLoop(String variableName) {
    // Find the FOR loop entry
    int foundIndex = -1;
    for (int i = _stack.length - 1; i >= 0; i--) {
      final entry = _stack[i];
      if (entry is ForLoopEntry && entry.variableName == variableName) {
        foundIndex = i;
        break;
      }
    }

    if (foundIndex == -1) {
      return null; // FOR loop not found
    }

    // Get the entry before removing it
    final forEntry = _stack[foundIndex] as ForLoopEntry;

    // Remove all entries from foundIndex to end (inclusive)
    _stack.removeRange(foundIndex, _stack.length);

    return forEntry;
  }

  /// Pop the most recent GOSUB entry
  GosubEntry? popGosub() {
    // Search from top for most recent GOSUB entry
    for (int i = _stack.length - 1; i >= 0; i--) {
      final entry = _stack[i];
      if (entry is GosubEntry) {
        final gosubEntry = entry;
        // Remove this entry and everything above it
        _stack.removeRange(i, _stack.length);
        return gosubEntry;
      }
    }
    return null; // No GOSUB found
  }

  /// Check if there are any active FOR loops
  bool hasActiveForLoops() {
    return _stack.any((entry) => entry is ForLoopEntry);
  }

  /// Check if there are any active GOSUB calls
  bool hasActiveGosubs() {
    return _stack.any((entry) => entry is GosubEntry);
  }

  /// Get current stack depth
  int get depth => _stack.length;

  /// Clear the entire stack
  void clear() {
    _stack.clear();
  }

  /// Get a description of the current stack (for debugging)
  String getStackDescription() {
    if (_stack.isEmpty) {
      return 'Stack: empty';
    }

    final buffer = StringBuffer('Stack (${_stack.length} entries):\n');
    for (int i = _stack.length - 1; i >= 0; i--) {
      buffer.writeln('  [$i] ${_stack[i]}');
    }
    return buffer.toString();
  }

  /// Check for nested FOR loops with the same variable
  ///
  /// This helps detect and handle nested loops with the same
  /// variable name, which should reuse the same variable.
  bool hasNestedForLoop(String variableName) {
    int count = 0;
    for (final entry in _stack) {
      if (entry is ForLoopEntry && entry.variableName == variableName) {
        count++;
        if (count > 1) {
          return true;
        }
      }
    }
    return false;
  }

  /// Get all active FOR loop variables
  List<String> getActiveForVariables() {
    final variables = <String>[];
    for (final entry in _stack) {
      if (entry is ForLoopEntry) {
        variables.add(entry.variableName);
      }
    }
    return variables;
  }

  /// Validate stack integrity
  ///
  /// Checks that the stack is in a valid state.
  /// Used for debugging and error detection.
  bool validateStack() {
    // All entries should be valid types
    for (final entry in _stack) {
      if (entry is! ForLoopEntry && entry is! GosubEntry) {
        return false;
      }
    }
    return true;
  }
}

/// Exception thrown by stack operations
class StackException implements Exception {
  final String message;

  StackException(this.message);

  @override
  String toString() => 'StackException: $message';
}

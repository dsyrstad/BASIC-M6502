import '../memory/memory.dart';

/// String management system for Microsoft BASIC 6502.
///
/// Implements the original string handling with:
/// - 3-byte string descriptors (length + 2-byte pointer)
/// - String space that grows down from top of memory
/// - Temporary string management
/// - String garbage collection (GARBAG)
/// - String comparison operations
class StringManager {
  final Memory memory;

  /// Maximum string length (255 characters)
  static const int maxStringLength = 255;

  /// String descriptor size (3 bytes: length + pointer)
  static const int descriptorSize = 3;

  /// Temporary string stack size
  static const int tempStringStackSize = 3;

  /// Temporary string descriptors stack
  final List<StringDescriptor> _tempStringStack = [];

  StringManager(this.memory);

  /// Get the current string space top
  int get _stringSpaceTop {
    return memory.readWord(Memory.fretop);
  }

  /// Set the string space top
  set _stringSpaceTop(int address) {
    memory.writeWord(Memory.fretop, address);
  }

  /// Get the current string end (bottom of used string space)
  int get _stringEnd {
    return memory.readWord(Memory.strend);
  }

  /// Set the string end
  set _stringEnd(int address) {
    memory.writeWord(Memory.strend, address);
  }

  /// Get the current temporary string pointer
  int get _tempStringPointer {
    return memory.readWord(Memory.frespc);
  }

  /// Set the temporary string pointer
  set _tempStringPointer(int address) {
    memory.writeWord(Memory.frespc, address);
  }

  /// Initialize string management system
  void initialize(int topOfMemory) {
    _stringSpaceTop = topOfMemory;
    // Only set _stringEnd if it's not already set (i.e., if it's 0)
    if (memory.readWord(Memory.strend) == 0) {
      _stringEnd = memory.readWord(Memory.arytab); // String space starts after arrays
    }
    _tempStringPointer = 0;
    _tempStringStack.clear();
  }

  /// Create a string descriptor from a Dart string
  StringDescriptor createString(String value) {
    if (value.length > maxStringLength) {
      throw StringException('String too long: ${value.length} > $maxStringLength');
    }

    if (value.isEmpty) {
      return StringDescriptor(length: 0, pointer: 0);
    }

    // Allocate space for the string
    final stringAddress = _allocateStringSpace(value.length);

    // Write string data to memory
    for (int i = 0; i < value.length; i++) {
      memory.writeByte(stringAddress + i, value.codeUnitAt(i));
    }

    return StringDescriptor(length: value.length, pointer: stringAddress);
  }

  /// Create a temporary string that will be automatically managed
  StringDescriptor createTemporaryString(String value) {
    final descriptor = createString(value);

    // Add to temporary string stack
    if (_tempStringStack.length >= tempStringStackSize) {
      // Remove oldest temporary string
      _tempStringStack.removeAt(0);
    }

    _tempStringStack.add(descriptor);
    _tempStringPointer = descriptor.pointer;

    return descriptor;
  }

  /// Read a string from memory using a descriptor
  String readString(StringDescriptor descriptor) {
    if (descriptor.length == 0 || descriptor.pointer == 0) {
      return '';
    }

    final buffer = StringBuffer();
    for (int i = 0; i < descriptor.length; i++) {
      final byte = memory.readByte(descriptor.pointer + i);
      buffer.writeCharCode(byte);
    }

    return buffer.toString();
  }

  /// Read a string descriptor from memory at the given address
  StringDescriptor readDescriptor(int address) {
    final length = memory.readByte(address);
    final pointer = memory.readWord(address + 1);
    return StringDescriptor(length: length, pointer: pointer);
  }

  /// Write a string descriptor to memory at the given address
  void writeDescriptor(int address, StringDescriptor descriptor) {
    memory.writeByte(address, descriptor.length);
    memory.writeWord(address + 1, descriptor.pointer);
  }

  /// Allocate space for a string in string space
  int _allocateStringSpace(int length) {
    if (length == 0) return 0;

    // Check if we have enough space
    final currentTop = _stringSpaceTop;
    final currentEnd = _stringEnd;
    final newTop = currentTop - length;

    if (newTop < currentEnd) {
      // Not enough space - trigger garbage collection
      garbageCollect();

      // Check again after garbage collection
      final newCurrentTop = _stringSpaceTop;
      final newCurrentEnd = _stringEnd;
      final newNewTop = newCurrentTop - length;

      if (newNewTop < newCurrentEnd) {
        throw StringException('Out of string space');
      }

      _stringSpaceTop = newNewTop;
      return newNewTop;
    }

    _stringSpaceTop = newTop;
    return newTop;
  }

  /// Garbage collection for string space (GARBAG equivalent)
  void garbageCollect() {
    // Create a list of all string descriptors that are still in use
    final activeStrings = <StringDescriptor>[];

    // Scan variable table for string variables
    final vartabStart = memory.readWord(Memory.vartab);
    final arytabStart = memory.readWord(Memory.arytab);

    for (int addr = vartabStart; addr < arytabStart; addr += 6) {
      // Check if this is a string variable (high bit set in first character)
      final firstChar = memory.readByte(addr);
      if ((firstChar & 0x80) != 0) {
        // This is a string variable - read its descriptor
        final descriptor = readDescriptor(addr + 2);
        if (descriptor.length > 0 && descriptor.pointer > 0) {
          activeStrings.add(descriptor);
        }
      }
    }

    // TODO: Scan array table for string arrays
    // TODO: Scan FOR/GOSUB stack for string temporaries

    // Add temporary strings to active list
    activeStrings.addAll(_tempStringStack);

    // Sort active strings by pointer address (high to low)
    activeStrings.sort((a, b) => b.pointer.compareTo(a.pointer));

    // Compact string space
    final topOfMemory = memory.readWord(Memory.memsiz);
    int newTop = topOfMemory;

    for (final descriptor in activeStrings) {
      if (descriptor.length > 0 && descriptor.pointer > 0) {
        final newAddress = newTop - descriptor.length;

        // Move string data if necessary
        if (newAddress != descriptor.pointer) {
          memory.copyBlock(descriptor.pointer, newAddress, descriptor.length);

          // Update all references to this string
          _updateStringReferences(descriptor.pointer, newAddress);
        }

        newTop = newAddress;
      }
    }

    _stringSpaceTop = newTop;
  }

  /// Update all references to a string after garbage collection
  void _updateStringReferences(int oldAddress, int newAddress) {
    // Update variable table
    final vartabStart = memory.readWord(Memory.vartab);
    final arytabStart = memory.readWord(Memory.arytab);

    for (int addr = vartabStart; addr < arytabStart; addr += 6) {
      final firstChar = memory.readByte(addr);
      if ((firstChar & 0x80) != 0) {
        final descriptor = readDescriptor(addr + 2);
        if (descriptor.pointer == oldAddress) {
          writeDescriptor(addr + 2, StringDescriptor(
            length: descriptor.length,
            pointer: newAddress
          ));
        }
      }
    }

    // Update temporary string stack
    for (int i = 0; i < _tempStringStack.length; i++) {
      if (_tempStringStack[i].pointer == oldAddress) {
        _tempStringStack[i] = StringDescriptor(
          length: _tempStringStack[i].length,
          pointer: newAddress
        );
      }
    }

    // Update temporary string pointer if it matches
    if (_tempStringPointer == oldAddress) {
      _tempStringPointer = newAddress;
    }
  }

  /// String concatenation (equivalent to string + operator)
  StringDescriptor concatenateStrings(StringDescriptor left, StringDescriptor right) {
    final leftStr = readString(left);
    final rightStr = readString(right);
    final result = leftStr + rightStr;

    return createTemporaryString(result);
  }

  /// String comparison operations
  int compareStrings(StringDescriptor left, StringDescriptor right) {
    final leftStr = readString(left);
    final rightStr = readString(right);

    return leftStr.compareTo(rightStr);
  }

  /// Check if two strings are equal
  bool areStringsEqual(StringDescriptor left, StringDescriptor right) {
    return compareStrings(left, right) == 0;
  }

  /// Extract substring (LEFT$, RIGHT$, MID$ functions)
  StringDescriptor substring(StringDescriptor source, int start, [int? length]) {
    final sourceStr = readString(source);

    if (start < 0 || start >= sourceStr.length) {
      return createTemporaryString('');
    }

    String result;
    if (length != null) {
      final end = (start + length).clamp(0, sourceStr.length);
      result = sourceStr.substring(start, end);
    } else {
      result = sourceStr.substring(start);
    }

    return createTemporaryString(result);
  }

  /// Get string length (LEN function)
  int getStringLength(StringDescriptor descriptor) {
    return descriptor.length;
  }

  /// Convert ASCII value to character (CHR$ function)
  StringDescriptor charFromAscii(int asciiValue) {
    if (asciiValue < 0 || asciiValue > 255) {
      throw StringException('Invalid ASCII value: $asciiValue');
    }

    final char = String.fromCharCode(asciiValue);
    return createTemporaryString(char);
  }

  /// Get ASCII value of first character (ASC function)
  int asciiFromChar(StringDescriptor descriptor) {
    final str = readString(descriptor);
    if (str.isEmpty) {
      throw StringException('ASC of empty string');
    }

    return str.codeUnitAt(0);
  }

  /// Clear all temporary strings
  void clearTemporaryStrings() {
    _tempStringStack.clear();
    _tempStringPointer = 0;
  }

  /// Get available string space
  int getAvailableStringSpace() {
    return _stringSpaceTop - _stringEnd;
  }

  /// Check if string space is getting low
  bool isStringSpaceLow({double threshold = 0.1}) {
    final totalSpace = memory.readWord(Memory.memsiz) - _stringEnd;
    final usedSpace = memory.readWord(Memory.memsiz) - _stringSpaceTop;
    final freeSpace = totalSpace - usedSpace;

    return freeSpace < (totalSpace * threshold);
  }

  /// Force garbage collection if string space is low
  void checkAndGarbageCollect() {
    if (isStringSpaceLow()) {
      garbageCollect();
    }
  }

  /// Reset string management to initial state
  void reset() {
    _tempStringStack.clear();
    _tempStringPointer = 0;

    // Reset string space to top of memory
    final topOfMemory = memory.readWord(Memory.memsiz);
    if (topOfMemory > 0) {
      _stringSpaceTop = topOfMemory;
    }
  }
}

/// String descriptor matching Microsoft BASIC format
class StringDescriptor {
  final int length;    // String length (0-255)
  final int pointer;   // Pointer to string data in memory

  const StringDescriptor({
    required this.length,
    required this.pointer,
  });

  /// Check if this represents an empty string
  bool get isEmpty => length == 0 || pointer == 0;

  /// Check if this represents a non-empty string
  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      other is StringDescriptor &&
      other.length == length &&
      other.pointer == pointer;

  @override
  int get hashCode => Object.hash(length, pointer);

  @override
  String toString() => 'StringDescriptor(length: $length, pointer: 0x${pointer.toRadixString(16)})';
}

/// Exception thrown by string operations
class StringException implements Exception {
  final String message;

  StringException(this.message);

  @override
  String toString() => 'StringException: $message';
}
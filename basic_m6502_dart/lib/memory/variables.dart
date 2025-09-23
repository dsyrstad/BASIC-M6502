import '../memory/memory.dart';

/// Variable storage system matching Microsoft BASIC 6502 format.
///
/// Variables are stored as 6-byte entries:
/// - 2 bytes: Variable name (2 ASCII characters)
/// - 4 bytes: Value (floating-point number or string descriptor)
///
/// String variables end with '$' and have a different value format.
/// Array variables end with '(' and point to array storage.
class VariableStorage {
  final Memory memory;

  /// Size of each variable entry in bytes
  static const int variableSize = 6;

  /// Variable name length (2 characters)
  static const int nameSize = 2;

  /// Value size (4 bytes for float or string descriptor)
  static const int valueSize = 4;

  /// String variable marker character
  static const int stringMarker = 36; // '$'

  /// Array variable marker character
  static const int arrayMarker = 40; // '('

  VariableStorage(this.memory);

  /// Get the start of variable table from memory
  int get _variableTableStart {
    return memory.readWord(Memory.vartab);
  }

  /// Set the start of variable table in memory
  set _variableTableStart(int address) {
    memory.writeWord(Memory.vartab, address);
  }

  /// Get the start of array table from memory
  int get _arrayTableStart {
    return memory.readWord(Memory.arytab);
  }

  /// Set the start of array table in memory
  set _arrayTableStart(int address) {
    memory.writeWord(Memory.arytab, address);
  }

  /// Find a variable by name (PTRGET equivalent)
  VariableResult findVariable(String name) {
    // Allow string variables with $ suffix (e.g., A$, S1$)
    final maxLength = name.endsWith('\$') ? 3 : 2;
    if (name.isEmpty || name.length > maxLength) {
      throw VariableException('Invalid variable name: $name');
    }

    // Normalize variable name to 2 characters
    final normalizedName = _normalizeVariableName(name);
    final nameBytes = _encodeVariableName(normalizedName);

    // Check if it's a string variable
    final isString = name.endsWith('\$');

    // Check if it's an array variable
    final isArray = name.endsWith('(');

    // Search through variable table
    int tableStart = _variableTableStart;
    int tableEnd = isArray ? _arrayTableStart : memory.readWord(Memory.arytab);

    for (int addr = tableStart; addr < tableEnd; addr += variableSize) {
      final varNameBytes = [
        memory.readByte(addr),
        memory.readByte(addr + 1)
      ];

      if (varNameBytes[0] == nameBytes[0] && varNameBytes[1] == nameBytes[1]) {
        // Found variable
        final value = _readVariableValue(addr + nameSize, isString);
        return VariableResult(
          found: true,
          address: addr,
          name: normalizedName,
          value: value,
          isString: isString,
          isArray: isArray
        );
      }
    }

    // Variable not found - need to create it
    final newAddr = _createVariable(normalizedName, nameBytes, isString, isArray);
    final defaultValue = isString ? StringValue('') : NumericValue(0.0);

    return VariableResult(
      found: false,
      address: newAddr,
      name: normalizedName,
      value: defaultValue,
      isString: isString,
      isArray: isArray
    );
  }

  /// Create a new variable entry
  int _createVariable(String name, List<int> nameBytes, bool isString, bool isArray) {
    int insertPoint;

    if (isArray) {
      // Arrays go after simple variables
      insertPoint = _arrayTableStart;
      // TODO: Implement array storage expansion
    } else {
      // Simple variables go before arrays
      insertPoint = memory.readWord(Memory.arytab);

      // Move array table forward to make room
      _expandVariableTable(variableSize);
    }

    // Write variable name
    memory.writeByte(insertPoint, nameBytes[0]);
    memory.writeByte(insertPoint + 1, nameBytes[1]);

    // Initialize value to zero/empty
    for (int i = 0; i < valueSize; i++) {
      memory.writeByte(insertPoint + nameSize + i, 0);
    }

    return insertPoint;
  }

  /// Expand variable table by moving array table forward
  void _expandVariableTable(int bytes) {
    final oldArrayStart = memory.readWord(Memory.arytab);
    final stringEnd = memory.readWord(Memory.strend);
    final newArrayStart = oldArrayStart + bytes;

    // Move existing array data
    if (stringEnd > oldArrayStart) {
      final arraySize = stringEnd - oldArrayStart;
      memory.copyBlock(oldArrayStart, newArrayStart, arraySize);
    }

    // Update pointers
    memory.writeWord(Memory.arytab, newArrayStart);
    memory.writeWord(Memory.strend, memory.readWord(Memory.strend) + bytes);
  }

  /// Normalize variable name to 2 characters
  String _normalizeVariableName(String name) {
    String normalized = name.toUpperCase();

    // Remove special suffixes for processing
    if (normalized.endsWith('\$') || normalized.endsWith('(')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    // Truncate to 2 characters if needed
    if (normalized.length > 2) {
      normalized = normalized.substring(0, 2);
    }

    // Pad to 2 characters with spaces if needed
    while (normalized.length < 2) {
      normalized += ' ';
    }

    // Add back suffix if it was a string or array
    if (name.endsWith('\$')) {
      normalized = normalized + '\$';
    } else if (name.endsWith('(')) {
      normalized = normalized + '(';
    }

    return normalized;
  }

  /// Encode variable name to byte array
  List<int> _encodeVariableName(String name) {
    final bytes = <int>[0, 0];

    for (int i = 0; i < 2 && i < name.length; i++) {
      int ch = name.codeUnitAt(i);

      // Handle special characters
      if (ch == stringMarker || ch == arrayMarker) {
        ch |= 0x80; // Set high bit for special markers
      }

      bytes[i] = ch;
    }

    return bytes;
  }

  /// Read variable value from memory
  VariableValue _readVariableValue(int address, bool isString) {
    if (isString) {
      // String variable - read 3-byte string descriptor
      final length = memory.readByte(address);
      final pointer = memory.readWord(address + 1);

      if (length == 0 || pointer == 0) {
        return StringValue('');
      }

      // Read string data
      final stringData = StringBuffer();
      for (int i = 0; i < length; i++) {
        stringData.writeCharCode(memory.readByte(pointer + i));
      }

      return StringValue(stringData.toString());
    } else {
      // Numeric variable - read 4-byte float (simplified for now)
      final bytes = <int>[];
      for (int i = 0; i < 4; i++) {
        bytes.add(memory.readByte(address + i));
      }

      // TODO: Implement proper Microsoft float format conversion
      // For now, just use a simple encoding
      final value = _bytesToDouble(bytes);
      return NumericValue(value);
    }
  }

  /// Write variable value to memory
  void _writeVariableValue(int address, VariableValue value, bool isString) {
    if (isString && value is StringValue) {
      // Simple string storage - for now store string inline after variable table
      final stringData = value.value;
      if (stringData.isEmpty) {
        memory.writeByte(address, 0); // Length
        memory.writeWord(address + 1, 0); // Pointer
        memory.writeByte(address + 3, 0); // Unused
      } else {
        // Find a place to store the string (simplified)
        final stringAddr = _allocateStringSpace(stringData.length);

        // Write string data
        for (int i = 0; i < stringData.length; i++) {
          memory.writeByte(stringAddr + i, stringData.codeUnitAt(i));
        }

        // Write string descriptor
        memory.writeByte(address, stringData.length); // Length
        memory.writeWord(address + 1, stringAddr); // Pointer
        memory.writeByte(address + 3, 0); // Unused
      }
    } else if (!isString && value is NumericValue) {
      // Numeric variable - write 4-byte float
      final bytes = _doubleToBytes(value.value);
      for (int i = 0; i < 4; i++) {
        memory.writeByte(address + i, bytes[i]);
      }
    } else {
      throw VariableException('Type mismatch in variable assignment');
    }
  }

  /// Allocate space for string storage (simplified)
  int _allocateStringSpace(int length) {
    // For now, just allocate at end of string space
    // This is a simplified version - real BASIC has garbage collection
    final currentStringEnd = memory.readWord(Memory.strend);
    final stringTop = memory.readWord(Memory.fretop);

    if (stringTop == 0) {
      // Initialize string space at top of memory
      const topOfMemory = 0x8000; // Simplified
      memory.writeWord(Memory.fretop, topOfMemory);
      memory.writeWord(Memory.strend, currentStringEnd);
    }

    final newStringTop = memory.readWord(Memory.fretop) - length;
    memory.writeWord(Memory.fretop, newStringTop);

    return newStringTop;
  }

  /// Set variable value
  void setVariable(String name, VariableValue value) {
    final result = findVariable(name);
    final isString = value is StringValue;

    if (result.isString != isString) {
      throw VariableException('Type mismatch: variable $name');
    }

    _writeVariableValue(result.address + nameSize, value, isString);
  }

  /// Get variable value
  VariableValue getVariable(String name) {
    final result = findVariable(name);
    return result.value;
  }

  /// Clear all variables
  void clearVariables() {
    final vartabStart = memory.readWord(Memory.vartab);
    final arytabStart = memory.readWord(Memory.arytab);

    // Clear variable table
    memory.fillBlock(vartabStart, arytabStart - vartabStart, 0);

    // Reset array table to start right after variable table
    memory.writeWord(Memory.arytab, vartabStart);
    memory.writeWord(Memory.strend, vartabStart);
  }

  /// Simple double to bytes conversion (placeholder)
  List<int> _doubleToBytes(double value) {
    // TODO: Implement proper Microsoft 5-byte float format
    // For now, use a simplified 4-byte representation
    final intValue = (value * 1000).round(); // Store as fixed point
    return [
      intValue & 0xFF,
      (intValue >> 8) & 0xFF,
      (intValue >> 16) & 0xFF,
      (intValue >> 24) & 0xFF,
    ];
  }

  /// Simple bytes to double conversion (placeholder)
  double _bytesToDouble(List<int> bytes) {
    // TODO: Implement proper Microsoft 5-byte float format
    // For now, use a simplified 4-byte representation
    final intValue = bytes[0] |
                    (bytes[1] << 8) |
                    (bytes[2] << 16) |
                    (bytes[3] << 24);
    return intValue / 1000.0;
  }

  /// Initialize variable storage system
  void initialize(int startAddress) {
    _variableTableStart = startAddress;
    _arrayTableStart = startAddress;
    memory.writeWord(Memory.strend, startAddress);
  }
}

/// Result of variable lookup
class VariableResult {
  final bool found;
  final int address;
  final String name;
  final VariableValue value;
  final bool isString;
  final bool isArray;

  VariableResult({
    required this.found,
    required this.address,
    required this.name,
    required this.value,
    required this.isString,
    required this.isArray,
  });
}

/// Base class for variable values
abstract class VariableValue {
  const VariableValue();
}

/// Numeric variable value
class NumericValue extends VariableValue {
  final double value;

  const NumericValue(this.value);

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other) =>
      other is NumericValue && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// String variable value
class StringValue extends VariableValue {
  final String value;

  const StringValue(this.value);

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is StringValue && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Tab function value for PRINT statement
class TabValue extends VariableValue {
  final int column;

  const TabValue(this.column);

  @override
  String toString() => 'TAB($column)';

  @override
  bool operator ==(Object other) =>
      other is TabValue && other.column == column;

  @override
  int get hashCode => column.hashCode;
}

/// Space function value for PRINT statement
class SpcValue extends VariableValue {
  final int spaces;

  const SpcValue(this.spaces);

  @override
  String toString() => 'SPC($spaces)';

  @override
  bool operator ==(Object other) =>
      other is SpcValue && other.spaces == spaces;

  @override
  int get hashCode => spaces.hashCode;
}

/// Exception thrown by variable operations
class VariableException implements Exception {
  final String message;

  VariableException(this.message);

  @override
  String toString() => 'VariableException: $message';
}
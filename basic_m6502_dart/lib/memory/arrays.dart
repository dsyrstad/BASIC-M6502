import '../memory/memory.dart';
import '../memory/variables.dart';

/// Array management system for Microsoft BASIC 6502.
///
/// Implements the original array handling with:
/// - Array descriptors with variable name, size, dimensions, and extents
/// - Multi-dimensional array support
/// - Array bounds checking
/// - DIM statement support for array allocation
/// - Array variable lookup and indexing
class ArrayManager {
  final Memory memory;

  /// Maximum number of dimensions supported
  static const int maxDimensions = 10;

  /// Size of array descriptor header (name + length + dimension count)
  static const int descriptorHeaderSize = 5;

  /// Size of each dimension extent (2 bytes)
  static const int dimensionExtentSize = 2;

  ArrayManager(this.memory);

  /// Get the current array table start
  int get _arrayTableStart {
    return memory.readWord(Memory.arytab);
  }

  /// Set the array table start
  set _arrayTableStart(int address) {
    memory.writeWord(Memory.arytab, address);
  }

  /// Get the current string end (end of array space)
  int get _stringEnd {
    return memory.readWord(Memory.strend);
  }

  /// Set the string end
  set _stringEnd(int address) {
    memory.writeWord(Memory.strend, address);
  }

  /// Find an array by name
  ArrayResult findArray(String name) {
    if (name.isEmpty) {
      throw ArrayException('Invalid array name: $name');
    }

    // For search purposes, accept longer names but use first 2 chars
    String searchName = name.length > 2 ? name.substring(0, 2) : name;

    // Normalize array name
    String normalizedName = searchName.toUpperCase();
    if (normalizedName.endsWith('(')) {
      normalizedName = normalizedName.substring(0, normalizedName.length - 1);
    }

    // Pad to 2 characters
    while (normalizedName.length < 2) {
      normalizedName += ' ';
    }

    final nameBytes = _encodeArrayName(
      normalizedName,
    ); // Use normalized name for encoding

    // Check if it's a string array
    final isString = name.contains('\$');

    // Search through array table
    int currentAddr = _arrayTableStart;
    final endAddr = _stringEnd;

    while (currentAddr < endAddr) {
      // Read array descriptor
      final descriptor = _readArrayDescriptor(currentAddr);

      if (descriptor.nameBytes[0] == nameBytes[0] &&
          descriptor.nameBytes[1] == nameBytes[1]) {
        // Found the array
        return ArrayResult(
          found: true,
          address: currentAddr,
          name: descriptor.name, // Use descriptor's trimmed name
          descriptor: descriptor,
          isString: isString,
        );
      }

      // Move to next array
      currentAddr += descriptor.totalSize;
    }

    // Array not found
    return ArrayResult(
      found: false,
      address: 0,
      name: normalizedName.trim(), // Trim spaces from normalized name
      descriptor: null,
      isString: isString,
    );
  }

  /// Create a new array (DIM statement)
  ArrayDescriptor createArray(
    String name,
    List<int> dimensions, {
    bool isString = false,
  }) {
    if (name.isEmpty) {
      throw ArrayException('Invalid array name: $name');
    }

    if (dimensions.isEmpty || dimensions.length > maxDimensions) {
      throw ArrayException(
        'Invalid number of dimensions: ${dimensions.length}',
      );
    }

    // For creation, use first 2 characters of name and normalize to uppercase
    String arrayName = name.length > 2 ? name.substring(0, 2) : name;
    arrayName = arrayName.toUpperCase();

    // Check if array already exists
    final existing = findArray(arrayName);
    if (existing.found) {
      throw ArrayException('Array already dimensioned: $arrayName');
    }

    // Validate dimensions
    for (int i = 0; i < dimensions.length; i++) {
      if (dimensions[i] < 0 || dimensions[i] > 32767) {
        throw ArrayException('Invalid dimension size: ${dimensions[i]}');
      }
    }

    // Calculate total number of elements
    int totalElements = 1;
    for (final dim in dimensions) {
      totalElements *= (dim + 1); // BASIC uses 0-based indexing, so add 1
      if (totalElements > 65535) {
        throw ArrayException('Array too large');
      }
    }

    // Calculate storage requirements
    final elementSize = isString
        ? 3
        : 4; // String descriptors vs numeric values
    final dataSize = totalElements * elementSize;
    final extentsSize = dimensions.length * dimensionExtentSize;
    final totalSize = descriptorHeaderSize + extentsSize + dataSize;

    // Check if we have enough space
    final currentEnd = _stringEnd;
    final newEnd = currentEnd + totalSize;
    final stringTop = memory.readWord(Memory.fretop);

    if (newEnd >= stringTop) {
      throw ArrayException('Out of memory for array');
    }

    // Create array descriptor
    final nameBytes = _encodeArrayName(arrayName);
    final descriptor = ArrayDescriptor(
      address: currentEnd,
      nameBytes: nameBytes,
      totalSize: totalSize,
      dimensionCount: dimensions.length,
      dimensions: List.from(dimensions),
      isString: isString,
      elementSize: elementSize,
      dataOffset: descriptorHeaderSize + extentsSize,
    );

    // Write array descriptor to memory
    _writeArrayDescriptor(currentEnd, descriptor);

    // Initialize array data to zero
    memory.fillBlock(currentEnd + descriptor.dataOffset, dataSize, 0);

    // Update string end pointer
    _stringEnd = newEnd;

    return descriptor;
  }

  /// Get array element address
  int getElementAddress(ArrayDescriptor descriptor, List<int> indices) {
    if (indices.length != descriptor.dimensionCount) {
      throw ArrayException(
        'Wrong number of indices: got ${indices.length}, expected ${descriptor.dimensionCount}',
      );
    }

    // Check bounds
    for (int i = 0; i < indices.length; i++) {
      if (indices[i] < 0 || indices[i] > descriptor.dimensions[i]) {
        throw ArrayException(
          'Index out of bounds: ${indices[i]} not in range 0..${descriptor.dimensions[i]}',
        );
      }
    }

    // Calculate linear index using row-major order
    int linearIndex = 0;
    int multiplier = 1;

    for (int i = indices.length - 1; i >= 0; i--) {
      linearIndex += indices[i] * multiplier;
      multiplier *= (descriptor.dimensions[i] + 1);
    }

    return descriptor.address +
        descriptor.dataOffset +
        (linearIndex * descriptor.elementSize);
  }

  /// Read array element value
  VariableValue getArrayElement(ArrayDescriptor descriptor, List<int> indices) {
    final elementAddr = getElementAddress(descriptor, indices);

    if (descriptor.isString) {
      // Read string descriptor
      final length = memory.readByte(elementAddr);
      final pointer = memory.readWord(elementAddr + 1);

      if (length == 0 || pointer == 0) {
        return const StringValue('');
      }

      // Read string data
      final buffer = StringBuffer();
      for (int i = 0; i < length; i++) {
        buffer.writeCharCode(memory.readByte(pointer + i));
      }

      return StringValue(buffer.toString());
    } else {
      // Read numeric value (4-byte format)
      final bytes = <int>[];
      for (int i = 0; i < 4; i++) {
        bytes.add(memory.readByte(elementAddr + i));
      }

      // TODO: Implement proper Microsoft float format conversion
      final value = _bytesToDouble(bytes);
      return NumericValue(value);
    }
  }

  /// Set array element value
  void setArrayElement(
    ArrayDescriptor descriptor,
    List<int> indices,
    VariableValue value,
  ) {
    final elementAddr = getElementAddress(descriptor, indices);

    if (descriptor.isString && value is StringValue) {
      // For now, store string inline (simplified - real BASIC uses string space)
      final stringData = value.value;
      if (stringData.length > 255) {
        throw ArrayException('String too long for array element');
      }

      if (stringData.isEmpty) {
        memory.writeByte(elementAddr, 0); // Length
        memory.writeWord(elementAddr + 1, 0); // Pointer
      } else {
        // This is a simplified implementation - real BASIC would allocate in string space
        throw ArrayException('String array assignment not fully implemented');
      }
    } else if (!descriptor.isString && value is NumericValue) {
      // Write numeric value
      final bytes = _doubleToBytes(value.value);
      for (int i = 0; i < 4; i++) {
        memory.writeByte(elementAddr + i, bytes[i]);
      }
    } else {
      throw ArrayException('Type mismatch in array assignment');
    }
  }

  /// Clear all arrays
  void clearArrays() {
    final vartabStart = memory.readWord(Memory.vartab);
    _arrayTableStart = vartabStart;
    _stringEnd = vartabStart;
  }

  /// Read array descriptor from memory
  ArrayDescriptor _readArrayDescriptor(int address) {
    // Read name (2 bytes)
    final nameBytes = [memory.readByte(address), memory.readByte(address + 1)];

    // Read total size (2 bytes)
    final totalSize = memory.readWord(address + 2);

    // Read dimension count (1 byte)
    final dimensionCount = memory.readByte(address + 4);

    // Read dimension extents
    final dimensions = <int>[];
    for (int i = 0; i < dimensionCount; i++) {
      final extent = memory.readWord(address + 5 + (i * 2));
      dimensions.add(extent - 1); // Convert from extent to max index
    }

    // Determine if it's a string array
    final isString = (nameBytes[1] & 0x80) != 0;

    final elementSize = isString ? 3 : 4;
    final dataOffset =
        descriptorHeaderSize + (dimensionCount * dimensionExtentSize);

    return ArrayDescriptor(
      address: address,
      nameBytes: nameBytes,
      totalSize: totalSize,
      dimensionCount: dimensionCount,
      dimensions: dimensions,
      isString: isString,
      elementSize: elementSize,
      dataOffset: dataOffset,
    );
  }

  /// Write array descriptor to memory
  void _writeArrayDescriptor(int address, ArrayDescriptor descriptor) {
    // Write name (2 bytes)
    memory.writeByte(address, descriptor.nameBytes[0]);
    memory.writeByte(address + 1, descriptor.nameBytes[1]);

    // Write total size (2 bytes)
    memory.writeWord(address + 2, descriptor.totalSize);

    // Write dimension count (1 byte)
    memory.writeByte(address + 4, descriptor.dimensionCount);

    // Write dimension extents
    for (int i = 0; i < descriptor.dimensionCount; i++) {
      final extent =
          descriptor.dimensions[i] + 1; // Convert from max index to extent
      memory.writeWord(address + 5 + (i * 2), extent);
    }
  }

  /// Encode array name to bytes
  List<int> _encodeArrayName(String name) {
    final bytes = <int>[0, 0];

    // Clean name - remove $ suffix for string arrays
    String cleanName = name;
    final isStringArray = name.contains('\$');
    if (isStringArray) {
      cleanName = cleanName.replaceAll('\$', '');
    }

    // Pad to 2 characters with spaces
    while (cleanName.length < 2) {
      cleanName += ' ';
    }

    for (int i = 0; i < 2 && i < cleanName.length; i++) {
      int ch = cleanName.codeUnitAt(i);

      // Set high bit for string arrays on second character
      if (i == 1 && isStringArray) {
        ch |= 0x80;
      }

      bytes[i] = ch;
    }

    return bytes;
  }

  /// Convert bytes to double (simplified)
  double _bytesToDouble(List<int> bytes) {
    // TODO: Implement proper Microsoft 5-byte float format
    final intValue =
        bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
    return intValue / 1000.0;
  }

  /// Convert double to bytes (simplified)
  List<int> _doubleToBytes(double value) {
    // TODO: Implement proper Microsoft 5-byte float format
    final intValue = (value * 1000).round();
    return [
      intValue & 0xFF,
      (intValue >> 8) & 0xFF,
      (intValue >> 16) & 0xFF,
      (intValue >> 24) & 0xFF,
    ];
  }

  /// Get total number of elements in array
  int getArrayElementCount(ArrayDescriptor descriptor) {
    int count = 1;
    for (final dim in descriptor.dimensions) {
      count *= (dim + 1);
    }
    return count;
  }

  /// Get memory usage information
  ArrayMemoryInfo getMemoryInfo() {
    int totalArrays = 0;
    int totalElements = 0;
    int totalMemoryUsed = 0;

    int currentAddr = _arrayTableStart;
    final endAddr = _stringEnd;

    while (currentAddr < endAddr) {
      final descriptor = _readArrayDescriptor(currentAddr);
      totalArrays++;
      totalElements += getArrayElementCount(descriptor);
      totalMemoryUsed += descriptor.totalSize;
      currentAddr += descriptor.totalSize;
    }

    final availableSpace = memory.readWord(Memory.fretop) - _stringEnd;

    return ArrayMemoryInfo(
      totalArrays: totalArrays,
      totalElements: totalElements,
      memoryUsed: totalMemoryUsed,
      availableSpace: availableSpace,
    );
  }
}

/// Array descriptor matching Microsoft BASIC format
class ArrayDescriptor {
  final int address; // Address in memory
  final List<int> nameBytes; // Variable name as bytes
  final int totalSize; // Total size in memory
  final int dimensionCount; // Number of dimensions
  final List<int> dimensions; // Size of each dimension (max indices)
  final bool isString; // True if string array
  final int elementSize; // Size of each element in bytes
  final int dataOffset; // Offset to array data

  const ArrayDescriptor({
    required this.address,
    required this.nameBytes,
    required this.totalSize,
    required this.dimensionCount,
    required this.dimensions,
    required this.isString,
    required this.elementSize,
    required this.dataOffset,
  });

  /// Get array name as string
  String get name {
    final buffer = StringBuffer();
    for (int i = 0; i < 2; i++) {
      final byte = nameBytes[i] & 0x7F; // Clear high bit
      if (byte != 0 && byte != 32) {
        // Skip null and space
        buffer.writeCharCode(byte);
      } else {
        break; // Stop at first space or null
      }
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return 'ArrayDescriptor(name: $name, dimensions: $dimensions, '
        'isString: $isString, size: $totalSize)';
  }
}

/// Result of array lookup
class ArrayResult {
  final bool found;
  final int address;
  final String name;
  final ArrayDescriptor? descriptor;
  final bool isString;

  const ArrayResult({
    required this.found,
    required this.address,
    required this.name,
    required this.descriptor,
    required this.isString,
  });
}

/// Array memory usage information
class ArrayMemoryInfo {
  final int totalArrays;
  final int totalElements;
  final int memoryUsed;
  final int availableSpace;

  const ArrayMemoryInfo({
    required this.totalArrays,
    required this.totalElements,
    required this.memoryUsed,
    required this.availableSpace,
  });

  @override
  String toString() {
    return 'ArrayMemoryInfo(arrays: $totalArrays, elements: $totalElements, '
        'used: $memoryUsed bytes, available: $availableSpace bytes)';
  }
}

/// Exception thrown by array operations
class ArrayException implements Exception {
  final String message;

  ArrayException(this.message);

  @override
  String toString() => 'ArrayException: $message';
}

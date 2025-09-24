import 'dart:typed_data';

/// Simulates 64KB of 6502 memory space.
///
/// Memory layout follows original Microsoft BASIC:
/// - 0x0000-0x00FF: Zero page (fast access variables)
/// - 0x0100-0x01FF: Stack
/// - 0x0200-0x1FFF: Free RAM for BASIC programs and variables
/// - 0x2000-0x3FFF: BASIC interpreter ROM (varies by platform)
/// - 0x4000-0xFFFF: Additional RAM/ROM (platform dependent)
class Memory {
  static const int memorySize = 65536; // 64KB

  // Memory region boundaries
  static const int zeroPageStart = 0x0000;
  static const int zeroPageEnd = 0x00FF;
  static const int stackStart = 0x0100;
  static const int stackEnd = 0x01FF;
  static const int ramStart = 0x0200;
  static const int defaultRomStart = 0x2000; // Commodore PET location

  // Zero page locations from original BASIC
  static const int chrget = 0x70; // Character get routine
  static const int txtptr = 0x7A; // Text pointer (2 bytes)
  static const int vartab = 0x2D; // Start of variable table (2 bytes)
  static const int arytab = 0x2F; // Start of array table (2 bytes)
  static const int strend = 0x31; // End of string storage (2 bytes)
  static const int fretop = 0x33; // Start of string space (2 bytes)
  static const int frespc = 0x35; // Temporary string pointer (2 bytes)
  static const int memsiz = 0x37; // Top of memory (2 bytes)
  static const int curlin = 0x39; // Current line number (2 bytes)
  static const int oldlin = 0x3B; // Old line number (2 bytes)
  static const int oldtxt = 0x3D; // Old text pointer (2 bytes)
  static const int datlin = 0x3F; // DATA line number (2 bytes)
  static const int datptr = 0x41; // DATA statement pointer (2 bytes)
  static const int inpptr = 0x43; // INPUT pointer (2 bytes)
  static const int varnam = 0x45; // Variable name (2 bytes)
  static const int varpnt = 0x47; // Variable pointer (2 bytes)
  static const int forpnt = 0x49; // FOR loop pointer (2 bytes)
  static const int facexp = 0x61; // Floating accumulator exponent
  static const int facho = 0x62; // Floating accumulator high order
  static const int facmoh = 0x63; // Floating accumulator middle order high
  static const int facmo = 0x64; // Floating accumulator middle order
  static const int faclo = 0x65; // Floating accumulator low order
  static const int facsgn = 0x66; // Floating accumulator sign
  static const int argexp = 0x69; // Argument exponent
  static const int argho = 0x6A; // Argument high order
  static const int argmoh = 0x6B; // Argument middle order high
  static const int argmo = 0x6C; // Argument middle order
  static const int arglo = 0x6D; // Argument low order
  static const int argsgn = 0x6E; // Argument sign

  final Uint8List _memory;

  Memory() : _memory = Uint8List(memorySize) {
    _initialize();
  }

  /// Initialize memory with default values
  void _initialize() {
    // Clear all memory
    _memory.fillRange(0, memorySize, 0);

    // Set up default zero page values
    // These will be properly initialized during interpreter startup
  }

  /// Read a single byte from memory
  int readByte(int address) {
    if (address < 0 || address >= memorySize) {
      throw MemoryException(
        'Invalid memory address: \$${address.toRadixString(16)}',
      );
    }
    return _memory[address];
  }

  /// Write a single byte to memory
  void writeByte(int address, int value) {
    if (address < 0 || address >= memorySize) {
      throw MemoryException(
        'Invalid memory address: \$${address.toRadixString(16)}',
      );
    }
    if (value < 0 || value > 255) {
      throw MemoryException('Invalid byte value: $value');
    }
    _memory[address] = value;
  }

  /// Read a 16-bit word from memory (little-endian)
  int readWord(int address) {
    if (address < 0 || address >= memorySize - 1) {
      throw MemoryException(
        'Invalid word address: \$${address.toRadixString(16)}',
      );
    }
    return _memory[address] | (_memory[address + 1] << 8);
  }

  /// Write a 16-bit word to memory (little-endian)
  void writeWord(int address, int value) {
    if (address < 0 || address >= memorySize - 1) {
      throw MemoryException(
        'Invalid word address: \$${address.toRadixString(16)}',
      );
    }
    if (value < 0 || value > 0xFFFF) {
      throw MemoryException('Invalid word value: $value');
    }
    _memory[address] = value & 0xFF;
    _memory[address + 1] = (value >> 8) & 0xFF;
  }

  /// Read a string from memory (null-terminated)
  String readString(int address) {
    final buffer = StringBuffer();
    int addr = address;

    while (addr < memorySize) {
      final byte = _memory[addr];
      if (byte == 0) break;
      buffer.writeCharCode(byte);
      addr++;
    }

    return buffer.toString();
  }

  /// Write a string to memory (null-terminated)
  void writeString(int address, String value) {
    int addr = address;

    for (int i = 0; i < value.length && addr < memorySize; i++) {
      _memory[addr++] = value.codeUnitAt(i);
    }

    if (addr < memorySize) {
      _memory[addr] = 0; // Null terminator
    }
  }

  /// Copy a block of memory
  void copyBlock(int source, int destination, int length) {
    if (source < 0 ||
        source + length > memorySize ||
        destination < 0 ||
        destination + length > memorySize) {
      throw MemoryException('Invalid memory block copy parameters');
    }

    // Handle overlapping copies correctly
    if (source < destination && source + length > destination) {
      // Copy backwards
      for (int i = length - 1; i >= 0; i--) {
        _memory[destination + i] = _memory[source + i];
      }
    } else {
      // Copy forwards
      for (int i = 0; i < length; i++) {
        _memory[destination + i] = _memory[source + i];
      }
    }
  }

  /// Fill a block of memory with a value
  void fillBlock(int address, int length, int value) {
    if (address < 0 || address + length > memorySize) {
      throw MemoryException('Invalid memory fill parameters');
    }
    if (value < 0 || value > 255) {
      throw MemoryException('Invalid fill value: $value');
    }

    _memory.fillRange(address, address + length, value);
  }

  /// Get a view of memory for debugging
  Uint8List getMemoryView(int address, int length) {
    if (address < 0 || address + length > memorySize) {
      throw MemoryException('Invalid memory view parameters');
    }

    return Uint8List.view(_memory.buffer, address, length);
  }

  /// Create a hex dump of memory for debugging
  String hexDump(int address, int length, {int bytesPerLine = 16}) {
    if (address < 0 || address + length > memorySize) {
      throw MemoryException('Invalid hex dump parameters');
    }

    final buffer = StringBuffer();

    for (int i = 0; i < length; i += bytesPerLine) {
      // Address
      buffer.write('${(address + i).toRadixString(16).padLeft(4, '0')}: ');

      // Hex bytes
      for (int j = 0; j < bytesPerLine; j++) {
        if (i + j < length) {
          buffer.write(
            '${_memory[address + i + j].toRadixString(16).padLeft(2, '0')} ',
          );
        } else {
          buffer.write('   ');
        }
      }

      buffer.write(' ');

      // ASCII representation
      for (int j = 0; j < bytesPerLine && i + j < length; j++) {
        final byte = _memory[address + i + j];
        if (byte >= 32 && byte < 127) {
          buffer.writeCharCode(byte);
        } else {
          buffer.write('.');
        }
      }

      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Reset memory to initial state
  void reset() {
    _initialize();
  }

  /// Check if address is in zero page
  bool isZeroPage(int address) {
    return address >= zeroPageStart && address <= zeroPageEnd;
  }

  /// Check if address is in stack area
  bool isStack(int address) {
    return address >= stackStart && address <= stackEnd;
  }
}

/// Exception thrown for memory access errors
class MemoryException implements Exception {
  final String message;

  MemoryException(this.message);

  @override
  String toString() => 'MemoryException: $message';
}

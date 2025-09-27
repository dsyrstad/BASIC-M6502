import 'dart:typed_data';
import 'memory.dart';

/// Manages storage and retrieval of BASIC program lines.
///
/// Program lines are stored in memory following the Microsoft BASIC format:
/// - 2 bytes: Link pointer to next line (0x0000 = end of program)
/// - 2 bytes: Line number (binary, little-endian)
/// - N bytes: Tokenized statement(s)
/// - 1 byte: Zero terminator
///
/// Lines are stored in sorted order by line number for efficient lookup.
class ProgramStorage {
  final Memory memory;

  /// Pointer to start of program in memory
  int _programStart = 0x0801; // Commodore BASIC start address

  /// Pointer to end of program in memory
  int _programEnd = 0x0801;

  /// Cache of line number to memory address mappings for fast lookup
  final Map<int, int> _lineAddressCache = <int, int>{};

  /// Flag to indicate if cache needs rebuilding
  bool _cacheValid = false;

  ProgramStorage(this.memory) {
    _initializeProgram();
  }

  /// Initialize empty program storage
  void _initializeProgram() {
    // Write end-of-program marker at start
    memory.writeWord(_programStart, 0x0000);
    _programEnd = _programStart + 2;
    _lineAddressCache.clear();
    _cacheValid = true;
  }

  /// Store a program line, replacing any existing line with same number
  void storeLine(int lineNumber, List<int> tokenizedContent) {
    if (lineNumber < 0 || lineNumber > 65535) {
      throw ProgramStorageException('Invalid line number: $lineNumber');
    }

    if (tokenizedContent.isEmpty) {
      // Empty content means delete the line
      deleteLine(lineNumber);
      return;
    }

    // Find insertion point
    final insertInfo = _findLineInsertionPoint(lineNumber);

    if (insertInfo.existingLineAddress != -1) {
      // Replace existing line
      _replaceLine(
        insertInfo.existingLineAddress,
        lineNumber,
        tokenizedContent,
      );
    } else {
      // Insert new line
      _insertLine(insertInfo.insertAddress, lineNumber, tokenizedContent);
    }

    _invalidateCache();
  }

  /// Delete a program line
  void deleteLine(int lineNumber) {
    final lineAddress = findLineAddress(lineNumber);
    if (lineAddress == -1) {
      return; // Line doesn't exist
    }

    _removeLine(lineAddress);
    _invalidateCache();
  }

  /// Find the memory address of a line number, returns -1 if not found
  int findLineAddress(int lineNumber) {
    if (!_cacheValid) {
      _rebuildCache();
    }

    return _lineAddressCache[lineNumber] ?? -1;
  }

  /// Get the next line number after the given line number
  /// Returns -1 if no next line exists
  int getNextLineNumber(int currentLineNumber) {
    if (!_cacheValid) {
      _rebuildCache();
    }

    int? nextLineNumber;
    for (final lineNum in _lineAddressCache.keys) {
      if (lineNum > currentLineNumber) {
        if (nextLineNumber == null || lineNum < nextLineNumber) {
          nextLineNumber = lineNum;
        }
      }
    }

    return nextLineNumber ?? -1;
  }

  /// Get all line numbers in ascending order
  List<int> getAllLineNumbers() {
    // Direct scan instead of using cache to avoid circular reference issues
    final lineNumbers = <int>[];
    int currentAddress = _programStart;
    final visitedAddresses = <int>{};
    int iterations = 0;
    const maxIterations = 1000;

    while (iterations++ < maxIterations) {
      if (visitedAddresses.contains(currentAddress)) {
        // Circular reference detected - stop here
        break;
      }
      visitedAddresses.add(currentAddress);

      final linkPointer = memory.readWord(currentAddress);

      if (linkPointer == 0) {
        // End of program
        break;
      }

      final lineNumber = memory.readWord(currentAddress + 2);
      lineNumbers.add(lineNumber);

      currentAddress = linkPointer;
    }

    lineNumbers.sort();
    return lineNumbers;
  }

  /// Get all lines as a map of line number to tokenized content
  Map<int, List<int>> getAllLines() {
    // Use getAllLineNumbers which works correctly, then get content for each
    final result = <int, List<int>>{};
    final lineNumbers = getAllLineNumbers();

    for (final lineNumber in lineNumbers) {
      try {
        result[lineNumber] = getLineContent(lineNumber);
      } catch (e) {
        // Skip lines that can't be read (shouldn't happen but safety first)
        continue;
      }
    }
    return result;
  }

  /// Check if a line exists
  bool hasLine(int lineNumber) {
    return findLineAddress(lineNumber) != -1;
  }

  /// Add a line from a tokenized line (for testing)
  void addLine(dynamic line) {
    if (line is String) {
      // Parse line number and tokenize the content
      final trimmed = line.trim();
      final spaceIndex = trimmed.indexOf(' ');
      if (spaceIndex == -1) {
        throw ProgramStorageException('Invalid line format: missing content');
      }

      final lineNumberStr = trimmed.substring(0, spaceIndex);
      final content = trimmed.substring(spaceIndex + 1);

      final lineNumber = int.tryParse(lineNumberStr);
      if (lineNumber == null) {
        throw ProgramStorageException('Invalid line number: $lineNumberStr');
      }

      // For testing, we'll create a simple tokenized version
      // In reality, this would use the tokenizer
      final tokenizedContent =
          content.codeUnits + [0]; // Simple ASCII + null terminator

      storeLine(lineNumber, tokenizedContent);
    } else if (line is List<int>) {
      // Handle pre-tokenized line format
      if (line.length < 4) {
        throw ProgramStorageException('Invalid tokenized line format');
      }

      // Extract line number from tokenized line (bytes 2-3, little-endian)
      final lineNumber = line[2] | (line[3] << 8);

      // Extract content (skip link pointer and line number)
      final content = line.sublist(4);

      storeLine(lineNumber, content);
    } else {
      throw ProgramStorageException(
        'Invalid line type: expected String or List<int>',
      );
    }
  }

  /// Get tokenized content of a line
  List<int> getLineContent(int lineNumber) {
    final lineAddress = findLineAddress(lineNumber);
    if (lineAddress == -1) {
      throw ProgramStorageException('Line $lineNumber not found');
    }

    return _readLineContent(lineAddress);
  }

  /// Get formatted line for display (line number + detokenized content)
  String getLineForDisplay(
    int lineNumber,
    String Function(List<int>) detokenizer,
  ) {
    final content = getLineContent(lineNumber);
    final detokenizedContent = detokenizer(content);
    return '$lineNumber $detokenizedContent';
  }

  /// Clear all program lines
  void clearProgram() {
    _initializeProgram();
  }

  /// Get the first line number in the program
  /// Returns -1 if program is empty
  int getFirstLineNumber() {
    if (!_cacheValid) {
      _rebuildCache();
    }

    if (_lineAddressCache.isEmpty) {
      return -1;
    }

    final lineNumbers = _lineAddressCache.keys.toList();
    lineNumbers.sort();
    return lineNumbers.first;
  }

  /// Check if program is empty
  bool get isEmpty {
    if (!_cacheValid) {
      _rebuildCache();
    }
    return _lineAddressCache.isEmpty;
  }

  /// Get program size in bytes
  int get programSize => _programEnd - _programStart;

  /// Set program start address (for different platforms)
  void setProgramStart(int address) {
    if (address < 0 || address > 0xFFFF) {
      throw ProgramStorageException('Invalid program start address: $address');
    }

    _programStart = address;
    _initializeProgram();
  }

  /// Find where to insert a line, returns info about insertion point
  _LineInsertionInfo _findLineInsertionPoint(int lineNumber) {
    int currentAddress = _programStart;
    int previousAddress = -1;

    while (true) {
      final linkPointer = memory.readWord(currentAddress);

      if (linkPointer == 0) {
        // End of program
        return _LineInsertionInfo(currentAddress, -1);
      }

      final currentLineNumber = memory.readWord(currentAddress + 2);

      if (currentLineNumber == lineNumber) {
        // Found existing line
        return _LineInsertionInfo(currentAddress, currentAddress);
      }

      if (currentLineNumber > lineNumber) {
        // Insert before this line
        return _LineInsertionInfo(currentAddress, -1);
      }

      previousAddress = currentAddress;
      currentAddress = linkPointer;
    }
  }

  /// Replace an existing line with new content
  void _replaceLine(int lineAddress, int lineNumber, List<int> content) {
    final oldLineSize = _getLineSize(lineAddress);
    final newLineSize = _calculateLineSize(content);
    final nextAddress = memory.readWord(lineAddress);

    if (newLineSize == oldLineSize) {
      // Same size, just replace content in place
      _writeLineContent(lineAddress, lineNumber, content, nextAddress);
    } else {
      // Different size, remove old line and insert new one
      _removeLine(lineAddress);

      // Find new insertion point (might have changed)
      final insertInfo = _findLineInsertionPoint(lineNumber);
      _insertLine(insertInfo.insertAddress, lineNumber, content);
    }
  }

  /// Insert a new line at the specified address
  void _insertLine(int insertAddress, int lineNumber, List<int> content) {
    final lineSize = _calculateLineSize(content);

    // Check if we're inserting at the end of the program
    final isAtEnd = memory.readWord(insertAddress) == 0;

    if (isAtEnd) {
      // Inserting at the end - simple case
      // Write the new line
      _writeLineContent(
        insertAddress,
        lineNumber,
        content,
        insertAddress + lineSize,
      );

      // Write end-of-program marker after the new line
      memory.writeWord(insertAddress + lineSize, 0);

      // Update program end pointer
      _programEnd = insertAddress + lineSize + 2; // +2 for end marker
    } else {
      // Inserting before existing lines
      // Save what comes after the insertion point
      final nextLineAddress = memory.readWord(insertAddress);

      // Make space for the new line
      _makeSpace(insertAddress, lineSize);

      // The lines that were at insertAddress are now at insertAddress + lineSize
      final newNextAddress = insertAddress + lineSize;

      // Write the new line with link to the moved lines
      _writeLineContent(insertAddress, lineNumber, content, newNextAddress);

      // Update program end pointer
      _programEnd += lineSize;
    }
  }

  /// Remove a line from memory
  void _removeLine(int lineAddress) {
    final lineSize = _getLineSize(lineAddress);
    final nextAddress = memory.readWord(lineAddress);

    // Move everything after this line down
    if (nextAddress != 0) {
      final moveSize = _programEnd - nextAddress;
      memory.copyBlock(nextAddress, lineAddress, moveSize);

      // Update link pointers in the moved block to reflect new addresses
      _updateLinksAfterMove(lineAddress, moveSize, -lineSize);
    }

    // Update program end pointer
    _programEnd -= lineSize;

    // Write new end-of-program marker
    memory.writeWord(_programEnd, 0x0000);
  }

  /// Make space in memory for a new line
  void _makeSpace(int address, int size) {
    final moveSize = _programEnd - address;
    if (moveSize > 0) {
      memory.copyBlock(address, address + size, moveSize);

      // Update link pointers in the moved block to point to new addresses
      _updateLinksAfterMove(address + size, moveSize, size);
    }
  }

  /// Update link pointers after moving a block of memory
  void _updateLinksAfterMove(int blockStart, int blockSize, int offset) {
    int currentAddress = blockStart;
    final blockEnd = blockStart + blockSize;

    while (currentAddress < blockEnd) {
      final linkPointer = memory.readWord(currentAddress);

      if (linkPointer == 0) {
        // End of program marker, we're done
        break;
      }

      // The link pointer currently points to the old address of the next line
      // We need to calculate the line size using the original relationship
      // Original address of current line = currentAddress - offset
      final originalAddress = currentAddress - offset;
      final lineSize = linkPointer - originalAddress;

      // Update the link pointer to point to the new location
      final newLinkPointer = linkPointer + offset;
      memory.writeWord(currentAddress, newLinkPointer);

      // Move to the next line in the moved block
      currentAddress += lineSize;
    }
  }

  /// Calculate the size of a line in memory
  int _calculateLineSize(List<int> content) {
    return 4 + content.length + 1; // link(2) + linenum(2) + content + null
  }

  /// Get the size of an existing line in memory
  int _getLineSize(int lineAddress) {
    final linkPointer = memory.readWord(lineAddress);
    if (linkPointer == 0) {
      // This is the end marker
      return 2;
    }
    return linkPointer - lineAddress;
  }

  /// Write line content to memory
  void _writeLineContent(
    int address,
    int lineNumber,
    List<int> content,
    int nextLineAddress,
  ) {
    // Write link pointer to next line
    memory.writeWord(address, nextLineAddress);

    // Write line number
    memory.writeWord(address + 2, lineNumber);

    // Write tokenized content
    for (int i = 0; i < content.length; i++) {
      memory.writeByte(address + 4 + i, content[i]);
    }

    // Write null terminator
    memory.writeByte(address + 4 + content.length, 0);
  }

  /// Read the content of a line (without line number and structure)
  List<int> _readLineContent(int lineAddress) {
    final linkPointer = memory.readWord(lineAddress);
    if (linkPointer == 0) {
      throw ProgramStorageException('Invalid line address');
    }

    final contentStart = lineAddress + 4;
    final contentEnd = linkPointer - 1; // Exclude null terminator
    final content = <int>[];

    for (int addr = contentStart; addr < contentEnd; addr++) {
      content.add(memory.readByte(addr));
    }

    return content;
  }

  /// Rebuild the line number to address cache
  void _rebuildCache() {
    _lineAddressCache.clear();
    int currentAddress = _programStart;
    int maxIterations = 1000; // Prevent infinite loops
    int iterations = 0;
    final visitedAddresses = <int>{};

    while (true) {
      // Safety checks to prevent infinite loops
      if (iterations++ > maxIterations) {
        throw ProgramStorageException(
          'Infinite loop detected in program storage - too many lines',
        );
      }

      if (visitedAddresses.contains(currentAddress)) {
        throw ProgramStorageException(
          'Circular reference detected in program storage at address ${currentAddress.toRadixString(16)}',
        );
      }
      visitedAddresses.add(currentAddress);

      final linkPointer = memory.readWord(currentAddress);

      if (linkPointer == 0) {
        // End of program
        break;
      }

      final lineNumber = memory.readWord(currentAddress + 2);
      _lineAddressCache[lineNumber] = currentAddress;

      currentAddress = linkPointer;
    }

    _cacheValid = true;
  }

  /// Mark cache as invalid
  void _invalidateCache() {
    _cacheValid = false;
  }

  /// Export the entire program as bytes for saving to disk
  List<int> exportProgram() {
    final programData = <int>[];
    int currentAddress = _programStart;

    while (true) {
      final linkPointer = memory.readWord(currentAddress);

      if (linkPointer == 0) {
        // End of program - write terminator
        programData.add(0);
        programData.add(0);
        break;
      }

      // Get line data
      final lineNumber = memory.readWord(currentAddress + 2);

      // Calculate line length
      int lineEnd = currentAddress + 4;
      while (memory.readByte(lineEnd) != 0) {
        lineEnd++;
      }
      final lineLength =
          lineEnd - currentAddress + 1; // Include null terminator

      // Write line length (2 bytes)
      programData.add(lineLength & 0xFF);
      programData.add((lineLength >> 8) & 0xFF);

      // Write line number (2 bytes)
      programData.add(lineNumber & 0xFF);
      programData.add((lineNumber >> 8) & 0xFF);

      // Write line content (tokens until null)
      for (int addr = currentAddress + 4; addr <= lineEnd; addr++) {
        programData.add(memory.readByte(addr));
      }

      currentAddress = linkPointer;
    }

    return programData;
  }

  /// Import a program from bytes loaded from disk
  void importProgram(List<int> programData) {
    // Validate program data
    if (programData.isEmpty) {
      throw ProgramStorageException('Empty program data');
    }

    if (programData.length < 2) {
      throw ProgramStorageException('Invalid program format - too short');
    }

    // Clear current program first
    clearProgram();

    int index = 0;
    int lineCount = 0;

    while (index < programData.length - 1) {
      // Check for buffer overflow
      if (index + 1 >= programData.length) {
        throw ProgramStorageException(
          'Invalid program format - unexpected end of data',
        );
      }

      // Read line length
      final lineLength = programData[index] | (programData[index + 1] << 8);
      index += 2;

      if (lineLength == 0) {
        // End of program
        break;
      }

      // Validate line length
      if (lineLength < 4) {
        throw ProgramStorageException(
          'Invalid program format - line too short',
        );
      }

      if (lineLength > 255) {
        throw ProgramStorageException('Invalid program format - line too long');
      }

      // Check if we have enough data for this line
      if (index + lineLength - 2 > programData.length) {
        throw ProgramStorageException(
          'Invalid program format - line data exceeds file size',
        );
      }

      // Read line number
      final lineNumber = programData[index] | (programData[index + 1] << 8);
      index += 2;

      // Validate line number
      if (lineNumber < 0 || lineNumber > 65535) {
        throw ProgramStorageException('Invalid line number: $lineNumber');
      }

      // Read line content
      final content = <int>[];
      for (int i = 0; i < lineLength - 4; i++) {
        if (index >= programData.length) {
          throw ProgramStorageException(
            'Invalid program format - line content truncated',
          );
        }
        final byte = programData[index++];
        if (byte != 0) {
          // Skip null terminator
          content.add(byte);
        }
      }

      // Skip null terminator if present
      if (index < programData.length && programData[index] == 0) {
        index++;
      }

      // Store the line
      try {
        storeLine(lineNumber, content);
        lineCount++;

        // Prevent programs with too many lines
        if (lineCount > 1000) {
          throw ProgramStorageException('Program too large - too many lines');
        }
      } catch (e) {
        if (e is ProgramStorageException) {
          throw e;
        }
        throw ProgramStorageException('Failed to store line $lineNumber: $e');
      }
    }

    _invalidateCache();
  }
}

/// Information about where to insert a line
class _LineInsertionInfo {
  final int insertAddress; // Where to insert/replace
  final int existingLineAddress; // -1 if new line, address if replacing

  _LineInsertionInfo(this.insertAddress, this.existingLineAddress);
}

/// Exception thrown for program storage errors
class ProgramStorageException implements Exception {
  final String message;

  ProgramStorageException(this.message);

  @override
  String toString() => 'ProgramStorageException: $message';
}

import 'dart:io';
import 'dart:typed_data';

/// Exception for file I/O errors
class FileIOException implements Exception {
  final String message;
  const FileIOException(this.message);
  @override
  String toString() => message;
}

/// Manages file and device I/O operations for BASIC.
///
/// This implementation supports the Commodore BASIC I/O model with
/// logical file numbers, device numbers, and secondary addresses.
class FileIOManager {
  /// Maximum number of open files
  static const int maxOpenFiles = 10;

  /// Device numbers
  static const int deviceKeyboard = 0;
  static const int deviceTape = 1;
  static const int deviceScreen = 3;
  static const int devicePrinter = 4;
  static const int deviceDisk = 8;

  /// Open file entries
  final Map<int, OpenFile> _openFiles = {};

  /// Current output device for CMD
  int _currentOutputDevice = deviceScreen;

  /// Open a file or device
  ///
  /// Parameters:
  /// - logicalFile: Logical file number (1-255)
  /// - deviceNumber: Device number (0=keyboard, 1=tape, 3=screen, 4=printer, 8-11=disk)
  /// - secondaryAddress: Secondary address (0-15, optional)
  /// - filename: Filename for disk operations (optional)
  void open(
    int logicalFile,
    int deviceNumber, {
    int secondaryAddress = 0,
    String? filename,
  }) {
    // Validate logical file number
    if (logicalFile < 1 || logicalFile > 255) {
      throw FileIOException(
        'ILLEGAL QUANTITY ERROR - Invalid logical file number',
      );
    }

    // Check if file is already open
    if (_openFiles.containsKey(logicalFile)) {
      throw FileIOException('FILE ALREADY OPEN');
    }

    // Check maximum open files
    if (_openFiles.length >= maxOpenFiles) {
      throw FileIOException('TOO MANY FILES');
    }

    // Validate device number
    if (deviceNumber < 0 || deviceNumber > 31) {
      throw FileIOException('DEVICE NOT PRESENT');
    }

    // Create appropriate file handler based on device
    OpenFile? openFile;

    switch (deviceNumber) {
      case deviceKeyboard:
        openFile = KeyboardFile(logicalFile, secondaryAddress);
        break;
      case deviceScreen:
        openFile = ScreenFile(logicalFile, secondaryAddress);
        break;
      case devicePrinter:
        openFile = PrinterFile(logicalFile, secondaryAddress);
        break;
      case deviceDisk:
        if (filename == null || filename.isEmpty) {
          throw FileIOException('MISSING FILE NAME');
        }
        openFile = DiskFile(logicalFile, secondaryAddress, filename);
        break;
      default:
        // For tape and other devices, create a stub
        openFile = StubFile(logicalFile, deviceNumber, secondaryAddress);
    }

    // Open the file
    openFile.open();
    _openFiles[logicalFile] = openFile;
  }

  /// Close a file
  void close(int logicalFile) {
    final file = _openFiles[logicalFile];
    if (file == null) {
      throw FileIOException('FILE NOT OPEN');
    }

    file.close();
    _openFiles.remove(logicalFile);

    // If this was the CMD output, reset to screen
    if (_currentOutputDevice == logicalFile) {
      _currentOutputDevice = deviceScreen;
    }
  }

  /// Close all open files
  void closeAll() {
    for (final file in _openFiles.values) {
      file.close();
    }
    _openFiles.clear();
    _currentOutputDevice = deviceScreen;
  }

  /// Write to a file
  void write(int logicalFile, String data) {
    if (logicalFile == 0) {
      // Writing to file 0 means screen
      stdout.write(data);
      return;
    }

    final file = _openFiles[logicalFile];
    if (file == null) {
      throw FileIOException('FILE NOT OPEN');
    }

    file.write(data);
  }

  /// Read from a file
  String read(int logicalFile) {
    if (logicalFile == 0) {
      // Reading from file 0 means keyboard
      return stdin.readLineSync() ?? '';
    }

    final file = _openFiles[logicalFile];
    if (file == null) {
      throw FileIOException('FILE NOT OPEN');
    }

    return file.read();
  }

  /// Read a single character from a file
  int? readChar(int logicalFile) {
    if (logicalFile == 0) {
      // Reading from file 0 means keyboard
      // This would require raw mode input
      return null;
    }

    final file = _openFiles[logicalFile];
    if (file == null) {
      throw FileIOException('FILE NOT OPEN');
    }

    return file.readChar();
  }

  /// Redirect output to a file (CMD)
  void redirectOutput(int logicalFile) {
    if (logicalFile == 0 || logicalFile == deviceScreen) {
      // Redirect to screen - always allowed
      _currentOutputDevice = deviceScreen;
    } else if (!_openFiles.containsKey(logicalFile)) {
      throw FileIOException('FILE NOT OPEN');
    } else {
      _currentOutputDevice = logicalFile;
    }
  }

  /// Get current output device
  int get currentOutputDevice => _currentOutputDevice;

  /// Check if a file is open
  bool isOpen(int logicalFile) => _openFiles.containsKey(logicalFile);

  /// Get file status
  String getStatus(int logicalFile) {
    final file = _openFiles[logicalFile];
    if (file == null) {
      return 'FILE NOT OPEN';
    }
    return file.status;
  }
}

/// Base class for open files
abstract class OpenFile {
  final int logicalFile;
  final int deviceNumber;
  final int secondaryAddress;

  OpenFile(this.logicalFile, this.deviceNumber, this.secondaryAddress);

  /// Open the file
  void open();

  /// Close the file
  void close();

  /// Write data to the file
  void write(String data);

  /// Read data from the file
  String read();

  /// Read a single character
  int? readChar();

  /// Get file status
  String get status => 'OK';
}

/// Keyboard input file
class KeyboardFile extends OpenFile {
  KeyboardFile(int logicalFile, int secondaryAddress)
    : super(logicalFile, FileIOManager.deviceKeyboard, secondaryAddress);

  @override
  void open() {
    // No special initialization needed for keyboard
  }

  @override
  void close() {
    // No cleanup needed for keyboard
  }

  @override
  void write(String data) {
    throw FileIOException('FILE TYPE MISMATCH - Cannot write to keyboard');
  }

  @override
  String read() {
    return stdin.readLineSync() ?? '';
  }

  @override
  int? readChar() {
    // Would require raw mode input
    return null;
  }
}

/// Screen output file
class ScreenFile extends OpenFile {
  ScreenFile(int logicalFile, int secondaryAddress)
    : super(logicalFile, FileIOManager.deviceScreen, secondaryAddress);

  @override
  void open() {
    // No special initialization needed for screen
  }

  @override
  void close() {
    // No cleanup needed for screen
  }

  @override
  void write(String data) {
    stdout.write(data);
  }

  @override
  String read() {
    throw FileIOException('FILE TYPE MISMATCH - Cannot read from screen');
  }

  @override
  int? readChar() {
    throw FileIOException('FILE TYPE MISMATCH - Cannot read from screen');
  }
}

/// Printer output file
class PrinterFile extends OpenFile {
  final List<String> _buffer = [];

  PrinterFile(int logicalFile, int secondaryAddress)
    : super(logicalFile, FileIOManager.devicePrinter, secondaryAddress);

  @override
  void open() {
    // Initialize printer buffer
    _buffer.clear();
  }

  @override
  void close() {
    // Flush printer buffer
    if (_buffer.isNotEmpty) {
      // In a real implementation, this would send to printer
      print('=== PRINTER OUTPUT ===');
      for (final line in _buffer) {
        print(line);
      }
      print('=== END PRINTER OUTPUT ===');
    }
  }

  @override
  void write(String data) {
    // Buffer printer output
    _buffer.add(data);
  }

  @override
  String read() {
    throw FileIOException('FILE TYPE MISMATCH - Cannot read from printer');
  }

  @override
  int? readChar() {
    throw FileIOException('FILE TYPE MISMATCH - Cannot read from printer');
  }
}

/// Disk file
class DiskFile extends OpenFile {
  final String filename;
  RandomAccessFile? _file;
  bool _isOutput = false;

  DiskFile(int logicalFile, int secondaryAddress, this.filename)
    : super(logicalFile, FileIOManager.deviceDisk, secondaryAddress);

  @override
  void open() {
    try {
      // Secondary address determines mode:
      // 0 = read (PRG file)
      // 1 = write (PRG file)
      // 2-14 = data channels
      // 15 = command channel

      if (secondaryAddress == 15) {
        // Command channel - not implemented
        return;
      }

      _isOutput = secondaryAddress == 1 || secondaryAddress >= 2;

      if (_isOutput) {
        // Open for writing
        final file = File(filename);
        _file = file.openSync(mode: FileMode.write);
      } else {
        // Open for reading
        final file = File(filename);
        if (!file.existsSync()) {
          throw FileIOException('FILE NOT FOUND');
        }
        _file = file.openSync(mode: FileMode.read);
      }
    } catch (e) {
      if (e is FileIOException) rethrow;
      throw FileIOException('DISK ERROR - ${e.toString()}');
    }
  }

  @override
  void close() {
    _file?.closeSync();
    _file = null;
  }

  @override
  void write(String data) {
    if (!_isOutput) {
      throw FileIOException('FILE TYPE MISMATCH - File not open for writing');
    }
    if (_file == null) {
      throw FileIOException('FILE NOT OPEN');
    }

    try {
      _file!.writeStringSync(data);
    } catch (e) {
      throw FileIOException('DISK ERROR - ${e.toString()}');
    }
  }

  @override
  String read() {
    if (_isOutput) {
      throw FileIOException('FILE TYPE MISMATCH - File not open for reading');
    }
    if (_file == null) {
      throw FileIOException('FILE NOT OPEN');
    }

    try {
      // Read until newline or EOF
      final buffer = StringBuffer();
      int byte;
      while ((byte = _file!.readByteSync()) != -1) {
        if (byte == 10 || byte == 13) {
          // Skip CR/LF
          if (byte == 13) {
            // Check for CRLF
            final pos = _file!.positionSync();
            if (_file!.readByteSync() != 10) {
              _file!.setPositionSync(pos);
            }
          }
          break;
        }
        buffer.writeCharCode(byte);
      }
      return buffer.toString();
    } catch (e) {
      throw FileIOException('DISK ERROR - ${e.toString()}');
    }
  }

  @override
  int? readChar() {
    if (_isOutput) {
      throw FileIOException('FILE TYPE MISMATCH - File not open for reading');
    }
    if (_file == null) {
      throw FileIOException('FILE NOT OPEN');
    }

    try {
      final byte = _file!.readByteSync();
      return byte == -1 ? null : byte;
    } catch (e) {
      throw FileIOException('DISK ERROR - ${e.toString()}');
    }
  }
}

/// Stub file for unsupported devices
class StubFile extends OpenFile {
  StubFile(int logicalFile, int deviceNumber, int secondaryAddress)
    : super(logicalFile, deviceNumber, secondaryAddress);

  @override
  void open() {
    // Stub - device not implemented
  }

  @override
  void close() {
    // Stub - device not implemented
  }

  @override
  void write(String data) {
    throw FileIOException('DEVICE NOT PRESENT');
  }

  @override
  String read() {
    throw FileIOException('DEVICE NOT PRESENT');
  }

  @override
  int? readChar() {
    throw FileIOException('DEVICE NOT PRESENT');
  }
}

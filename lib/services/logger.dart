import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';

/// Custom printer that puts time inline with the log message
class InlineTimePrinter extends LogPrinter {
  final bool colors;
  final bool printEmojis;

  InlineTimePrinter({this.colors = true, this.printEmojis = true});

  @override
  List<String> log(LogEvent event) {
    final time = DateTime.now();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';

    final emoji = _getEmoji(event.level);
    final levelColor = _getLevelColor(event.level);

    String message = '$timeStr $emoji ${event.message}';

    if (colors) {
      message = '$levelColor$message\x1B[0m';
    }

    final output = <String>[message];

    // Add error information if present
    if (event.error != null) {
      final errorColor = colors ? levelColor : '';
      final resetColor = colors ? '\x1B[0m' : '';
      output.add('$errorColor  Error: ${event.error}$resetColor');
    }

    // Add stack trace if present
    if (event.stackTrace != null) {
      final traceColor = colors ? '\x1B[38;5;244m' : ''; // Gray
      final resetColor = colors ? '\x1B[0m' : '';
      final stackLines = event.stackTrace.toString().split('\n');
      for (final line in stackLines) {
        if (line.isNotEmpty) {
          output.add('$traceColor  $line$resetColor');
        }
      }
    }

    return output;
  }

  String _getEmoji(Level level) {
    if (!printEmojis) return '';

    switch (level) {
      case Level.trace:
        return '';
      case Level.debug:
        return '🐛';
      case Level.info:
        return '💡';
      case Level.warning:
        return '⚠️';
      case Level.error:
        return '⛔';
      case Level.fatal:
        return '👾';
      case Level.all:
        return '📋';
      default:
        return '';
    }
  }

  String _getLevelColor(Level level) {
    switch (level) {
      case Level.trace:
        return '\x1B[38;5;244m'; // Gray
      case Level.debug:
        return '\x1B[38;5;12m'; // Blue
      case Level.info:
        return '\x1B[38;5;12m'; // Blue
      case Level.warning:
        return '\x1B[38;5;208m'; // Orange
      case Level.error:
        return '\x1B[38;5;196m'; // Red
      case Level.fatal:
        return '\x1B[38;5;199m'; // Magenta
      case Level.all:
        return '\x1B[38;5;15m'; // White
      default:
        return '\x1B[38;5;15m'; // White
    }
  }
}

/// File output printer that writes logs to a file without ANSI color codes
class FileOutputPrinter extends LogPrinter {
  final IOSink? _fileSink;
  final bool printEmojis;

  FileOutputPrinter(this._fileSink, {this.printEmojis = true});

  @override
  List<String> log(LogEvent event) {
    if (_fileSink == null) return [];

    final time = DateTime.now();
    final dateStr = '${time.year}-${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')}';
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';

    final emoji = _getEmoji(event.level);
    final levelStr = _getLevelString(event.level);

    final output = <String>[];
    output.add('[$dateStr $timeStr] [$levelStr] $emoji ${event.message}');

    // Add error information if present
    if (event.error != null) {
      output.add('  Error: ${event.error}');
    }

    // Add stack trace if present
    if (event.stackTrace != null) {
      final stackLines = event.stackTrace.toString().split('\n');
      for (final line in stackLines) {
        if (line.isNotEmpty) {
          output.add('  $line');
        }
      }
    }

    // Write to file
    for (final line in output) {
      _fileSink!.writeln(line);
    }
    _fileSink!.flush();

    return output;
  }

  String _getEmoji(Level level) {
    if (!printEmojis) return '';

    switch (level) {
      case Level.trace:
        return '';
      case Level.debug:
        return '🐛';
      case Level.info:
        return '💡';
      case Level.warning:
        return '⚠️';
      case Level.error:
        return '⛔';
      case Level.fatal:
        return '👾';
      case Level.all:
        return '📋';
      default:
        return '';
    }
  }

  String _getLevelString(Level level) {
    switch (level) {
      case Level.trace:
        return 'TRACE';
      case Level.debug:
        return 'DEBUG';
      case Level.info:
        return 'INFO';
      case Level.warning:
        return 'WARN';
      case Level.error:
        return 'ERROR';
      case Level.fatal:
        return 'FATAL';
      default:
        return 'LOG';
    }
  }
}

/// Custom log output that writes to a file
class FileLogOutput extends LogOutput {
  final IOSink _fileSink;
  final LogPrinter _printer;

  FileLogOutput(this._fileSink, this._printer);

  @override
  void output(OutputEvent event) {
    final lines = _printer.log(event);
    for (final line in lines) {
      _fileSink.writeln(line);
    }
    _fileSink.flush();
  }
}

/// Centralized logging service for the Horcrux application.
///
/// This service provides a consistent logging interface throughout the app
/// with configurable log levels and formatting.
/// Logs are written to both console and a file.
class Log {
  static final Logger _logger = Logger(
    printer: InlineTimePrinter(
      colors: true,
      printEmojis: true,
    ),
  );

  /// Log trace messages (most detailed level)
  static void trace(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) _initialize();
    _loggerInstance.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log debug messages
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) _initialize();
    _loggerInstance.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log informational messages
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) _initialize();
    _loggerInstance.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) _initialize();
    _loggerInstance.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) _initialize();
    _loggerInstance.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal failure messages
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) _initialize();
    _loggerInstance.f(message, error: error, stackTrace: stackTrace);
  }

  /// Export all log files as a zip archive
  /// Returns the path to the created zip file, or null if export fails
  static Future<String?> exportLogsAsZip() async {
    try {
      final logFiles = await getAllLogFiles();
      if (logFiles.isEmpty) {
        return null;
      }

      // Create zip archive
      final archive = Archive();

      // Add all log files to the archive
      for (final logFile in logFiles) {
        final fileData = await logFile.readAsBytes();
        final fileName = path.basename(logFile.path);
        archive.addFile(ArchiveFile(fileName, fileData.length, fileData));
      }

      // Create zip file
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      if (zipData == null) {
        return null;
      }

      // Save zip file
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final zipFileName = 'keydex_logs_${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.zip';
      final zipFile = File(path.join(directory.path, zipFileName));
      await zipFile.writeAsBytes(zipData);

      return zipFile.path;
    } catch (e) {
      error('Failed to export logs as zip', e);
      return null;
    }
  }

  /// Close the file sink (call this when app is closing)
  static Future<void> dispose() async {
    await _fileSink?.flush();
    await _fileSink?.close();
    _fileSink = null;
  }
}

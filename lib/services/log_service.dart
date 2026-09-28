import 'package:logger/logger.dart';

/// Severity level of a log entry.
enum LogLevel { info, warning, error }

/// A single in-memory log entry shown in the Admin Logs screen.
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  /// Human-readable level label.
  String get levelLabel {
    switch (level) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}

/// Centralised logging service.
///
/// Usage:
///   LogService.info('AuthService', 'User signed in: uid=abc123');
///   LogService.warning('CartProvider', 'Cart loaded from fallback cache');
///   LogService.error('FirestoreService', 'Failed to save order', error: e);
class LogService {
  LogService._();

  // ── Pretty console logger (shows colors in terminal) ──────────────────────
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  // ── In-memory log buffer (visible in Admin Logs screen) ───────────────────
  static final List<LogEntry> _entries = [];

  /// All captured log entries, newest first.
  static List<LogEntry> get entries => List.unmodifiable(_entries.reversed.toList());

  /// Optional listeners that get notified when a new entry is added.
  static final List<void Function()> _listeners = [];

  static void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  static void _notify() {
    for (final l in _listeners) {
      l();
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Logs a general informational message.
  static void info(String tag, String message) {
    _logger.i('[$tag] $message');
    _store(LogLevel.info, tag, message);
  }

  /// Logs a non-critical warning.
  static void warning(String tag, String message, {Object? error}) {
    _logger.w('[$tag] $message${error != null ? ' | $error' : ''}');
    _store(LogLevel.warning, tag, message);
  }

  /// Logs an error, optionally with the exception and stack trace.
  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      '[$tag] $message',
      error: error,
      stackTrace: stackTrace,
    );
    _store(LogLevel.error, tag, '$message${error != null ? ' — $error' : ''}');
  }

  /// Clears all stored log entries (admin action).
  static void clearLogs() {
    _entries.clear();
    _notify();
    info('LogService', 'Log history cleared by admin');
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static void _store(LogLevel level, String tag, String message) {
    _entries.add(LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    ));
    // Keep the buffer bounded so memory does not grow unbounded.
    if (_entries.length > 500) {
      _entries.removeAt(0);
    }
    _notify();
  }
}

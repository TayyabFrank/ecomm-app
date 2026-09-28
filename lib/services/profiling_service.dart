import 'dart:async';
import 'dart:io' show ProcessInfo;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'log_service.dart';

/// A single performance metric snapshot.
class PerfSnapshot {
  final DateTime timestamp;
  final double memoryMB;
  final double avgFrameTimeMs;
  final int droppedFrames;
  final int totalFrames;
  final Duration uptime;

  const PerfSnapshot({
    required this.timestamp,
    required this.memoryMB,
    required this.avgFrameTimeMs,
    required this.droppedFrames,
    required this.totalFrames,
    required this.uptime,
  });

  double get fps =>
      avgFrameTimeMs > 0 ? (1000.0 / avgFrameTimeMs).clamp(0, 120) : 0;

  String get fpsLabel => fps.toStringAsFixed(1);

  String get memoryLabel => '${memoryMB.toStringAsFixed(1)} MB';

  String get uptimeLabel {
    final h = uptime.inHours;
    final m = uptime.inMinutes % 60;
    final s = uptime.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

/// Centralized profiling service that tracks app performance metrics.
///
/// Collects:
/// - Estimated memory usage (from Dart VM)
/// - Frame rendering timing (via [SchedulerBinding])
/// - Dropped frame count
/// - App uptime
///
/// Stores a rolling history of snapshots for display in the admin dashboard.
class ProfilingService {
  ProfilingService._();

  static const String _tag = 'ProfilingService';
  static const int _maxHistory = 60; // ~60 seconds of data at 1s intervals

  static final List<PerfSnapshot> _history = [];
  static Timer? _samplingTimer;
  static DateTime? _appStartTime;
  static bool _isRunning = false;

  // Frame timing tracking
  static final List<double> _recentFrameTimes = [];
  static int _droppedFrameCount = 0;
  static int _totalFrameCount = 0;

  /// All recorded snapshots, newest first.
  static List<PerfSnapshot> get history =>
      List.unmodifiable(_history.reversed.toList());

  /// Latest snapshot, if available.
  static PerfSnapshot? get latest => _history.isNotEmpty ? _history.last : null;

  static bool get isRunning => _isRunning;

  /// Optional listeners for UI updates.
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

  /// Starts the profiling engine. Call once during app initialization.
  static void start() {
    if (_isRunning) return;
    _isRunning = true;
    _appStartTime ??= DateTime.now();

    // Listen to frame timings
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);

    // Sample metrics every second
    _samplingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _captureSnapshot();
    });

    LogService.info(_tag, 'Profiling engine started');
  }

  /// Stops the profiling engine.
  static void stop() {
    _samplingTimer?.cancel();
    _samplingTimer = null;
    _isRunning = false;

    // Note: we cannot remove timings callback easily, but we stop sampling.
    LogService.info(_tag, 'Profiling engine stopped');
  }

  /// Callback for frame timing data from the Flutter engine.
  static void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final totalDuration = timing.totalSpan;
      final ms = totalDuration.inMicroseconds / 1000.0;
      _recentFrameTimes.add(ms);
      _totalFrameCount++;

      // A frame taking > 16.67ms means it missed the 60fps target.
      if (ms > 16.67) {
        _droppedFrameCount++;
      }
    }

    // Keep only the last 120 frame times for averaging
    if (_recentFrameTimes.length > 120) {
      _recentFrameTimes.removeRange(0, _recentFrameTimes.length - 120);
    }
  }

  /// Captures a snapshot of current performance metrics.
  static void _captureSnapshot() {
    // Memory estimation
    double memoryMB = 0;
    try {
      if (!kIsWeb) {
        // ProcessInfo is available in Dart VM (not on web)
        final info = ProcessInfo.currentRss;
        memoryMB = info / (1024 * 1024);
      }
    } catch (_) {
      // Fallback: no memory info available (e.g., on web)
      memoryMB = 0;
    }

    // Average frame time
    double avgFrameTime = 0;
    if (_recentFrameTimes.isNotEmpty) {
      avgFrameTime =
          _recentFrameTimes.reduce((a, b) => a + b) / _recentFrameTimes.length;
    }

    final snapshot = PerfSnapshot(
      timestamp: DateTime.now(),
      memoryMB: memoryMB,
      avgFrameTimeMs: avgFrameTime,
      droppedFrames: _droppedFrameCount,
      totalFrames: _totalFrameCount,
      uptime: DateTime.now().difference(_appStartTime!),
    );

    _history.add(snapshot);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }

    _notify();
  }

  /// Clears all recorded history.
  static void clearHistory() {
    _history.clear();
    _droppedFrameCount = 0;
    _totalFrameCount = 0;
    _recentFrameTimes.clear();
    _notify();
    LogService.info(_tag, 'Performance history cleared');
  }
}

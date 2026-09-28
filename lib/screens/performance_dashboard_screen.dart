import 'package:flutter/material.dart';

import '../services/profiling_service.dart';

class PerformanceDashboardScreen extends StatefulWidget {
  static const routeName = '/admin-performance';

  const PerformanceDashboardScreen({super.key});

  @override
  State<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends State<PerformanceDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Start profiling if not already running
    if (!ProfilingService.isRunning) {
      ProfilingService.start();
    }
    ProfilingService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    ProfilingService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final latest = ProfilingService.latest;
    final history = ProfilingService.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Monitor'),
        actions: [
          IconButton(
            icon: Icon(
              ProfilingService.isRunning ? Icons.pause : Icons.play_arrow,
            ),
            tooltip:
                ProfilingService.isRunning ? 'Pause Profiling' : 'Resume Profiling',
            onPressed: () {
              setState(() {
                if (ProfilingService.isRunning) {
                  ProfilingService.stop();
                } else {
                  ProfilingService.start();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear History',
            onPressed: () {
              ProfilingService.clearHistory();
            },
          ),
        ],
      ),
      body: latest == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.speed_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Waiting for profiling data...',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Metrics update every second',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              children: [
                // ── Live Status Badge ──
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ProfilingService.isRunning
                            ? Colors.green
                            : Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: (ProfilingService.isRunning
                                    ? Colors.green
                                    : Colors.red)
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ProfilingService.isRunning
                          ? 'LIVE MONITORING'
                          : 'PAUSED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ProfilingService.isRunning
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Uptime: ${latest.uptimeLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Primary Metric Cards ──
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'FPS',
                        value: latest.fpsLabel,
                        subtitle: 'frames/sec',
                        icon: Icons.speed,
                        color: _fpsColor(latest.fps),
                        progress: (latest.fps / 60.0).clamp(0, 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Memory',
                        value: latest.memoryLabel,
                        subtitle: 'RSS usage',
                        icon: Icons.memory,
                        color: _memoryColor(latest.memoryMB),
                        progress: (latest.memoryMB / 512.0).clamp(0, 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Frame Time',
                        value:
                            '${latest.avgFrameTimeMs.toStringAsFixed(1)}ms',
                        subtitle: 'avg render time',
                        icon: Icons.timer_outlined,
                        color: latest.avgFrameTimeMs < 16.67
                            ? Colors.green
                            : Colors.orange,
                        progress:
                            (latest.avgFrameTimeMs / 33.0).clamp(0, 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Dropped',
                        value: '${latest.droppedFrames}',
                        subtitle:
                            'of ${latest.totalFrames} total frames',
                        icon: Icons.warning_amber_rounded,
                        color: latest.droppedFrames > 10
                            ? Colors.red
                            : Colors.green,
                        progress: latest.totalFrames > 0
                            ? (latest.droppedFrames / latest.totalFrames)
                                .clamp(0, 1)
                            : 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── FPS Timeline Chart ──
                const Text(
                  'FPS Timeline',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last ${history.length} seconds',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: CustomPaint(
                    size: const Size(double.infinity, 96),
                    painter: _FpsChartPainter(
                      data: history.reversed
                          .take(60)
                          .toList()
                          .reversed
                          .map((s) => s.fps)
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Memory Timeline Chart ──
                const Text(
                  'Memory Timeline',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'RSS in MB',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: CustomPaint(
                    size: const Size(double.infinity, 96),
                    painter: _MemoryChartPainter(
                      data: history.reversed
                          .take(60)
                          .toList()
                          .reversed
                          .map((s) => s.memoryMB)
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Detailed Metrics Table ──
                const Text(
                  'Detailed Metrics',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Current FPS',
                        value: latest.fpsLabel,
                        icon: Icons.speed,
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'Avg Frame Time',
                        value:
                            '${latest.avgFrameTimeMs.toStringAsFixed(2)} ms',
                        icon: Icons.timer,
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'Memory (RSS)',
                        value: latest.memoryLabel,
                        icon: Icons.memory,
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'Total Frames',
                        value: '${latest.totalFrames}',
                        icon: Icons.panorama_fish_eye,
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'Dropped Frames',
                        value: '${latest.droppedFrames}',
                        icon: Icons.warning_amber,
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'Drop Rate',
                        value: latest.totalFrames > 0
                            ? '${(latest.droppedFrames / latest.totalFrames * 100).toStringAsFixed(2)}%'
                            : '0%',
                        icon: Icons.trending_down,
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'App Uptime',
                        value: latest.uptimeLabel,
                        icon: Icons.access_time,
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        label: 'Snapshot History',
                        value: '${history.length} samples',
                        icon: Icons.history,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Color _fpsColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 30) return Colors.orange;
    return Colors.red;
  }

  Color _memoryColor(double mb) {
    if (mb < 150) return Colors.green;
    if (mb < 300) return Colors.orange;
    return Colors.red;
  }
}

// ── Metric Card Widget ──────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double progress;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              backgroundColor: Colors.grey.shade200,
              color: color,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail Row Widget ───────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2E32),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FPS Chart Painter ───────────────────────────────────────────────────────

class _FpsChartPainter extends CustomPainter {
  final List<double> data;

  _FpsChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Draw 60fps target line
    final targetY = size.height - (60 / 70 * size.height);
    final targetPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, targetY),
      Offset(size.width, targetY),
      targetPaint,
    );

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '60fps',
        style: TextStyle(
            color: Colors.green.withValues(alpha: 0.5), fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(2, targetY - 12));

    // Draw the FPS line
    final linePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.cyanAccent.withValues(alpha: 0.3),
          Colors.cyanAccent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final stepX = data.length > 1 ? size.width / (data.length - 1) : 0.0;

    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i].clamp(0, 70) / 70 * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((data.length - 1) * stepX, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _FpsChartPainter oldDelegate) =>
      data != oldDelegate.data;
}

// ── Memory Chart Painter ────────────────────────────────────────────────────

class _MemoryChartPainter extends CustomPainter {
  final List<double> data;

  _MemoryChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxMem = data.reduce((a, b) => a > b ? a : b).clamp(50, 1024);

    final linePaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.amber.withValues(alpha: 0.3),
          Colors.amber.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final stepX = data.length > 1 ? size.width / (data.length - 1) : 0.0;

    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxMem * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((data.length - 1) * stepX, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Max label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${maxMem.toStringAsFixed(0)} MB',
        style: TextStyle(
            color: Colors.amber.withValues(alpha: 0.5), fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(2, 2));
  }

  @override
  bool shouldRepaint(covariant _MemoryChartPainter oldDelegate) =>
      data != oldDelegate.data;
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/log_service.dart';

class AdminLogsScreen extends StatefulWidget {
  static const routeName = '/admin-logs';

  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  @override
  void initState() {
    super.initState();
    LogService.addListener(_onLogUpdated);
  }

  @override
  void dispose() {
    LogService.removeListener(_onLogUpdated);
    super.dispose();
  }

  void _onLogUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Color _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.blue.shade700;
      case LogLevel.warning:
        return Colors.orange.shade700;
      case LogLevel.error:
        return Colors.red.shade700;
    }
  }

  IconData _getIconForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber_rounded;
      case LogLevel.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = LogService.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Logs',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Logs'),
                  content: const Text('Are you sure you want to clear all system logs?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        LogService.clearLogs();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text(
                'No logs available.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final color = _getColorForLevel(entry.level);
                final timeFormatted = DateFormat('MM/dd HH:mm:ss').format(entry.timestamp);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(_getIconForLevel(entry.level), color: color, size: 28),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.levelLabel,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '[${entry.tag}]',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Text(
                          timeFormatted,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SelectableText(
                        entry.message,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

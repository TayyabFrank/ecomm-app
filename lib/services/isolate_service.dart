import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'log_service.dart';
import 'event_bus.dart';


/// Service that offloads heavy computations to background isolates
/// to keep the main UI thread responsive.
class IsolateService {
  IsolateService._();

  static const String _tag = 'IsolateService';

  /// Generates a CSV sales report from a list of serialized order maps.
  /// Runs in a background isolate via [compute] to prevent UI jank.
  ///
  /// Returns the full CSV string.
  static Future<String> generateSalesReport(
      List<Map<String, dynamic>> orderMaps) async {
    LogService.info(_tag,
        'Spawning background isolate to generate report for ${orderMaps.length} orders');

    final stopwatch = Stopwatch()..start();

    final csv = await compute(_buildCsvReport, orderMaps);

    stopwatch.stop();
    LogService.info(_tag,
        'Report generated in ${stopwatch.elapsedMilliseconds}ms (${csv.length} chars)');

    EventBus.instance.fire(ReportReadyEvent('sales_report_${DateTime.now().millisecondsSinceEpoch}.csv'));

    return csv;
  }

  /// Top-level function executed inside the background isolate.
  /// Must be a top-level or static function (isolate requirement).
  static String _buildCsvReport(List<Map<String, dynamic>> orderMaps) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // ── CSV Header ──
    buffer.writeln(
        'Order ID,Customer,Email,Date,Status,Items,Subtotal,Shipping Address,Payment Method');

    // ── Stats accumulators ──
    double totalRevenue = 0;
    int totalItemsSold = 0;
    int pendingCount = 0;
    int shippedCount = 0;
    int deliveredCount = 0;
    final Map<String, int> productFrequency = {};

    // ── Row generation with simulated heavy processing ──
    for (final map in orderMaps) {
      final orderId = map['id'] as String? ?? '';
      final userName = map['userName'] as String? ?? '';
      final userEmail = map['userEmail'] as String? ?? '';
      final status = map['status'] as String? ?? '';
      final totalAmount = (map['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final shippingAddress = map['shippingAddress'] as String? ?? '';
      final paymentMethod = map['paymentMethod'] as String? ?? '';

      DateTime timestamp;
      if (map['timestamp'] is String) {
        timestamp = DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now();
      } else {
        timestamp = DateTime.now();
      }

      final items = map['items'] as List<dynamic>? ?? [];
      int orderItemCount = 0;
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final qty = item['quantity'] as int? ?? 1;
          final name = item['name'] as String? ?? 'Unknown';
          orderItemCount += qty;
          productFrequency[name] = (productFrequency[name] ?? 0) + qty;
        }
      }

      totalRevenue += totalAmount;
      totalItemsSold += orderItemCount;

      switch (status.toLowerCase()) {
        case 'pending':
          pendingCount++;
          break;
        case 'shipped':
          shippedCount++;
          break;
        case 'delivered':
          deliveredCount++;
          break;
      }

      // Escape commas in fields
      String esc(String val) => '"${val.replaceAll('"', '""')}"';

      buffer.writeln(
        '${esc(orderId)},${esc(userName)},${esc(userEmail)},'
        '${dateFormat.format(timestamp)},${esc(status)},'
        '$orderItemCount,\$${totalAmount.toStringAsFixed(2)},'
        '${esc(shippingAddress)},${esc(paymentMethod)}',
      );

      // Simulate heavy CPU work (e.g., aggregation, hashing) per order
      // This ensures the isolate is doing meaningful background work.
      _simulateHeavyWork();
    }

    // ── Summary Section ──
    buffer.writeln();
    buffer.writeln('--- REPORT SUMMARY ---');
    buffer.writeln('Total Orders: ${orderMaps.length}');
    buffer.writeln('Total Revenue: \$${totalRevenue.toStringAsFixed(2)}');
    buffer.writeln('Total Items Sold: $totalItemsSold');
    buffer.writeln('Pending: $pendingCount');
    buffer.writeln('Shipped: $shippedCount');
    buffer.writeln('Delivered: $deliveredCount');

    // Top selling products
    if (productFrequency.isNotEmpty) {
      final sorted = productFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      buffer.writeln();
      buffer.writeln('--- TOP SELLING PRODUCTS ---');
      for (var i = 0; i < sorted.length && i < 5; i++) {
        buffer.writeln('${i + 1}. ${sorted[i].key} (${sorted[i].value} sold)');
      }
    }

    buffer.writeln();
    buffer.writeln('Report generated at: ${dateFormat.format(DateTime.now())}');

    return buffer.toString();
  }

  /// Simulates heavy computation to demonstrate UI stays responsive.
  static void _simulateHeavyWork() {
    // Perform some CPU-bound work (e.g., 50K iterations of math)
    double dummy = 0;
    for (int i = 0; i < 50000; i++) {
      dummy += i * 0.001;
      dummy = dummy / (1 + dummy.abs());
    }
  }
}

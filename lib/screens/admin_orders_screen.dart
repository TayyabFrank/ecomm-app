import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../services/firestore_service.dart';
import '../services/isolate_service.dart';
import '../services/log_service.dart';
import '../services/event_bus.dart';

class AdminOrdersScreen extends StatefulWidget {
  static const routeName = '/admin-orders';

  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _isGeneratingReport = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'shipped':
        return Colors.blue.shade700;
      case 'delivered':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade50;
      case 'shipped':
        return Colors.blue.shade50;
      case 'delivered':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  void _showStatusUpdateDialog(
      BuildContext context, String orderId, String currentStatus) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Pending', 'Shipped', 'Delivered'].map((status) {
              final isCurrent =
                  status.toLowerCase() == currentStatus.toLowerCase();
              return ListTile(
                title: Text(
                  status,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? Colors.black : Colors.grey.shade700,
                  ),
                ),
                trailing: isCurrent
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(dialogContext);
                  try {
                    await FirestoreService.updateOrderStatus(orderId, status);
                    EventBus.instance.fire(OrderStatusChangedEvent(orderId, status));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Order $orderId updated to $status'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating order: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Launches report generation in a background isolate.
  Future<void> _generateReport(List<OrderModel> orders) async {
    if (_isGeneratingReport) return;

    setState(() => _isGeneratingReport = true);

    LogService.info('AdminOrdersScreen',
        'Starting background report generation for ${orders.length} orders');

    // Serialize orders into plain maps for isolate transfer.
    final orderMaps = orders
        .map((o) => {
              'id': o.id,
              'userName': o.userName,
              'userEmail': o.userEmail,
              'status': o.status,
              'totalAmount': o.totalAmount,
              'shippingAddress': o.shippingAddress,
              'paymentMethod': o.paymentMethod,
              'timestamp': o.timestamp.toIso8601String(),
              'items': o.items
                  .map((item) => {
                        'productId': item.productId,
                        'name': item.name,
                        'price': item.price,
                        'quantity': item.quantity,
                      })
                  .toList(),
            })
        .toList();

    try {
      final csvReport = await IsolateService.generateSalesReport(orderMaps);

      if (!mounted) return;

      _showReportDialog(csvReport);
    } catch (e) {
      LogService.error(
          'AdminOrdersScreen', 'Background report generation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  void _showReportDialog(String csvReport) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Report Generated!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generated in a background isolate.\nUI stayed responsive the entire time!',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      csvReport,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.greenAccent,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Orders Trackrecord'),
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: FirestoreService.allOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 70,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders in the system',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          // Compute basic stats
          final totalSales =
              orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
          final pendingCount = orders
              .where((o) => o.status.toLowerCase() == 'pending')
              .length;
          final deliveredCount = orders
              .where((o) => o.status.toLowerCase() == 'delivered')
              .length;

          return Column(
            children: [
              // Stats Panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Revenue',
                        value: '\$${totalSales.toStringAsFixed(2)}',
                        icon: Icons.monetization_on_outlined,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Pending',
                        value: '$pendingCount',
                        icon: Icons.hourglass_empty_outlined,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Completed',
                        value: '$deliveredCount',
                        icon: Icons.check_circle_outline,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final dateString =
                        DateFormat('MMM dd, yyyy • hh:mm a')
                            .format(order.timestamp);

                    return Card(
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.04),
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          title: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.id,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Customer: ${order.userName}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => _showStatusUpdateDialog(
                                    context, order.id, order.status),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusBg(order.status),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _getStatusColor(
                                                order.status)
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        order.status,
                                        style: TextStyle(
                                          color: _getStatusColor(
                                              order.status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 12,
                                        color: _getStatusColor(
                                            order.status),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateString,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '\$${order.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF2D2E32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          children: [
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Email: ${order.userEmail}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                    Icons.local_shipping_outlined,
                                    size: 16,
                                    color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Address: ${order.shippingAddress}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Items Purchased',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF2D2E32),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: order.items.length,
                              itemBuilder: (context, i) {
                                final item = order.items[i];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.name} (x${item.quantity})',
                                          style: const TextStyle(
                                              fontSize: 12),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      // ── Export Report FAB ──
      floatingActionButton: StreamBuilder<List<OrderModel>>(
        stream: FirestoreService.allOrdersStream(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed:
                _isGeneratingReport ? null : () => _generateReport(orders),
            backgroundColor:
                _isGeneratingReport ? Colors.grey : const Color(0xFF1E1F22),
            foregroundColor: Colors.white,
            icon: _isGeneratingReport
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.summarize_outlined),
            label: Text(
                _isGeneratingReport ? 'Generating...' : 'Export Report'),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
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
                ),
              ),
              Icon(icon, size: 16, color: color.shade400),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

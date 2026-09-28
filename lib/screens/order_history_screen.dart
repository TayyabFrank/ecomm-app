import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';

class OrderHistoryScreen extends StatelessWidget {
  static const routeName = '/order-history';

  const OrderHistoryScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final firebaseUser = authProvider.firebaseUser;

    if (firebaseUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view order history'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: FirestoreService.userOrdersStream(firebaseUser.uid),
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
                    Icons.receipt_long_outlined,
                    size: 70,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders placed yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your purchase records will appear here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final dateString = DateFormat('MMM dd, yyyy • hh:mm a').format(order.timestamp);

              return Card(
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.05),
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            order.id,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusBg(order.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order.status,
                            style: TextStyle(
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateString,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '\$${order.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
                          const Icon(Icons.local_shipping_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Address: ${order.shippingAddress}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.payment_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Paid via: ${order.paymentMethod}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Items Ordered',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF2D2E32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items.length,
                        itemBuilder: (context, i) {
                          final item = order.items[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.network(
                                            item.imageURL,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.image, size: 16),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Qty: ${item.quantity} • \$${item.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
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
          );
        },
      ),
    );
  }
}

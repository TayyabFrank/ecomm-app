import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class NotificationCenterScreen extends StatefulWidget {
  static const routeName = '/notification-center';

  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Orders', 'Security', 'Products', 'System'];

  String _mapTypeToCategory(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return 'Orders';
      case 'security':
        return 'Security';
      case 'product':
        return 'Products';
      case 'system':
      default:
        return 'System';
    }
  }

  IconData _getCategoryIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'security':
        return Icons.lock_outline_rounded;
      case 'product':
        return Icons.sell_outlined;
      case 'system':
      default:
        return Icons.info_outline;
    }
  }

  Color _getCategoryColor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return const Color(0xFF4CAF50); // Emerald green
      case 'security':
        return const Color(0xFFF44336); // Crimson red
      case 'product':
        return const Color(0xFF9C27B0); // Deep purple
      case 'system':
      default:
        return const Color(0xFF2196F3); // Ocean blue
    }
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF1E1F22);
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    // Filter notifications
    final filteredNotifications = notifications.where((notification) {
      if (_selectedCategory == 'All') return true;
      return _mapTypeToCategory(notification.type) == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Notification Center',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          if (notifications.isNotEmpty) ...[
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Read All', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: primaryDark),
              onPressed: () {
                notificationProvider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              tooltip: 'Clear All',
              onPressed: () {
                _showClearConfirmation(context, notificationProvider);
              },
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          // Sleek Horizontal Filters
          Container(
            height: 48,
            margin: const EdgeInsets.only(top: 8, bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: primaryDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? primaryDark : Colors.grey.shade200,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          
          // Notifications List
          Expanded(
            child: filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      return _buildNotificationItem(context, notification, notificationProvider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All Caught Up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategory == 'All'
                ? 'You do not have any notifications yet.'
                : 'No $_selectedCategory alerts found.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    AppNotificationModel notification,
    NotificationProvider provider,
  ) {
    final isUnread = !notification.isRead;
    final color = _getCategoryColor(notification.type);
    final icon = _getCategoryIcon(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (isUnread) {
            provider.markAsRead(notification.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread Blue Dot Indicator
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 8),

              // Category Styled Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),

              // Notification text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(notification.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnread ? Colors.grey.shade800 : Colors.grey.shade600,
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This will delete all notifications from your history permanently.'),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Clear All'),
            onPressed: () {
              provider.clearAllNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications cleared')),
              );
            },
          ),
        ],
      ),
    );
  }
}

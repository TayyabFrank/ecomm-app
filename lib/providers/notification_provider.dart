import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';
import '../services/event_bus.dart';
import '../services/notification_service.dart';
import '../services/log_service.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotificationModel> _notifications = [];
  String? _currentUserId;

  StreamSubscription? _authSubscription;
  StreamSubscription? _firestoreSubscription;
  StreamSubscription? _eventSubscription;

  final _inAppNotificationController = StreamController<AppNotificationModel>.broadcast();

  List<AppNotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Stream of notifications received in the foreground.
  Stream<AppNotificationModel> get inAppNotifications => _inAppNotificationController.stream;

  NotificationProvider() {
    _setupAuthListener();
    _setupEventListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _firestoreSubscription?.cancel();
    _eventSubscription?.cancel();
    _inAppNotificationController.close();
    super.dispose();
  }

  void _setupAuthListener() {
    try {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _currentUserId = user.uid;
          _listenToFirestoreNotifications(user.uid);
        } else {
          _currentUserId = null;
          _notifications.clear();
          _firestoreSubscription?.cancel();
          notifyListeners();
        }
      });
    } catch (e) {
      LogService.error('NotificationProvider', 'Firebase Auth state listener failed', error: e);
    }
  }

  void _listenToFirestoreNotifications(String uid) {
    try {
      _firestoreSubscription?.cancel();
      _firestoreSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .snapshots()
          .listen((snapshot) {
        _notifications.clear();
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            _notifications.add(AppNotificationModel.fromMap(data));
          } catch (e) {
            LogService.error('NotificationProvider', 'Failed to parse notification doc: ${doc.id}', error: e);
          }
        }
        // Sort by timestamp descending
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }, onError: (e) {
        LogService.error('NotificationProvider', 'Firestore notification query stream error', error: e);
      });
    } catch (e) {
      LogService.error('NotificationProvider', 'Could not listen to firestore notifications', error: e);
    }
  }

  void _setupEventListener() {
    _eventSubscription = EventBus.instance.on<dynamic>().listen((event) {
      if (event is OrderPlacedEvent) {
        _handleOrderPlaced(event);
      } else if (event is OrderStatusChangedEvent) {
        _handleOrderStatusChanged(event);
      } else if (event is SecurityAlertEvent) {
        _handleSecurityAlert(event);
      } else if (event is ReportReadyEvent) {
        _handleReportReady(event);
      } else if (event is ProductPriceDropEvent) {
        _handleProductPriceDrop(event);
      }
    });
  }

  // --- Event Handlers ---

  void _handleOrderPlaced(OrderPlacedEvent event) {
    final title = '🎉 Order Placed!';
    final body = 'Order ${event.order.id} for \$${event.order.totalAmount.toStringAsFixed(2)} has been successfully placed.';
    _createNotification(title: title, body: body, type: 'order');
  }

  void _handleOrderStatusChanged(OrderStatusChangedEvent event) {
    final title = '📦 Order Update';
    final body = 'Order ${event.orderId} status changed to "${event.status}".';
    _createNotification(title: title, body: body, type: 'order');
  }

  void _handleSecurityAlert(SecurityAlertEvent event) {
    final title = '🔒 Security Alert';
    final body = event.message;
    _createNotification(title: title, body: body, type: 'security');
  }

  void _handleReportReady(ReportReadyEvent event) {
    final title = '📊 CSV Export Ready';
    final fileName = event.filePath.split('\\').last.split('/').last;
    final body = 'The CSV report "$fileName" has been generated and saved.';
    _createNotification(title: title, body: body, type: 'system');
  }

  void _handleProductPriceDrop(ProductPriceDropEvent event) {
    final title = '🔥 Price Drop Alert';
    final body = '${event.productName} dropped from \$${event.originalPrice.toStringAsFixed(2)} to \$${event.newPrice.toStringAsFixed(2)}!';
    _createNotification(title: title, body: body, type: 'product');
  }

  /// Central method to build, save, and alert a notification.
  Future<void> _createNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final id = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}-${title.hashCode.abs()}';
    final notification = AppNotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Persist notification
    if (_currentUserId == null) {
      _notifications.insert(0, notification);
      notifyListeners();
    } else {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('notifications')
            .doc(id)
            .set(notification.toMap());
      } catch (e) {
        LogService.error('NotificationProvider', 'Failed to save notification in Firestore', error: e);
        // Fallback local persistence
        _notifications.insert(0, notification);
        notifyListeners();
      }
    }

    // Trigger local push notification (OS level)
    await NotificationService.instance.showNotification(
      id: id.hashCode.abs(),
      title: title,
      body: body,
    );

    // Broadcast for in-app alert toast
    _inAppNotificationController.add(notification);
  }

  // --- Helper Methods ---

  Future<void> markAsRead(String id) async {
    if (_currentUserId == null) {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } else {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('notifications')
            .doc(id)
            .update({'isRead': true});
      } catch (e) {
        LogService.error('NotificationProvider', 'Failed to mark notification $id as read', error: e);
      }
    }
  }

  Future<void> deleteNotification(String id) async {
    if (_currentUserId == null) {
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    } else {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('notifications')
            .doc(id)
            .delete();
      } catch (e) {
        LogService.error('NotificationProvider', 'Failed to delete notification $id', error: e);
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (_currentUserId == null) {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
      notifyListeners();
    } else {
      try {
        final unreadNotifs = _notifications.where((n) => !n.isRead).toList();
        if (unreadNotifs.isEmpty) return;

        final batch = FirebaseFirestore.instance.batch();
        for (var notif in unreadNotifs) {
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserId)
              .collection('notifications')
              .doc(notif.id);
          batch.update(docRef, {'isRead': true});
        }
        await batch.commit();
      } catch (e) {
        LogService.error('NotificationProvider', 'Failed to mark all notifications as read', error: e);
      }
    }
  }

  Future<void> clearAllNotifications() async {
    if (_currentUserId == null) {
      _notifications.clear();
      notifyListeners();
    } else {
      try {
        if (_notifications.isEmpty) return;

        final batch = FirebaseFirestore.instance.batch();
        for (var notif in _notifications) {
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserId)
              .collection('notifications')
              .doc(notif.id);
          batch.delete(docRef);
        }
        await batch.commit();
      } catch (e) {
        LogService.error('NotificationProvider', 'Failed to clear notifications', error: e);
      }
    }
  }
}

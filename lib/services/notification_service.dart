import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'log_service.dart';
import 'permission_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _tag = 'NotificationService';
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initializes local notifications with platform settings.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Use standard launcher icon for Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Darwin settings for iOS/macOS
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          LogService.info(_tag, 'Notification tapped with payload: ${details.payload}');
        },
      );

      _isInitialized = true;
      LogService.info(_tag, 'Notification plugin initialized successfully');
    } catch (e, stack) {
      LogService.error(
        _tag,
        'Failed to initialize local notifications. Running in simulated fallback mode.',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Request permissions dynamically and trigger system notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'ecom_channel',
    String channelName = 'E-Commerce Notifications',
    String channelDescription = 'General notifications for orders, products and security',
  }) async {
    await initialize();

    try {
      // Ask user for permissions (dynamic)
      await PermissionService.requestNotifications();

      if (!_isInitialized) {
        LogService.warning(_tag, 'Notification service not initialized. Skipping OS notification.');
        return;
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _localNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      
      LogService.info(_tag, 'System notification sent: "$title"');
    } catch (e, stack) {
      LogService.error(
        _tag,
        'Error displaying local notification: "$title"',
        error: e,
        stackTrace: stack,
      );
    }
  }
}

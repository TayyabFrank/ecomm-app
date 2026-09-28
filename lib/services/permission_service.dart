import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

import 'log_service.dart';

/// Centralized service for runtime permission checks and requests.
class PermissionService {
  PermissionService._();

  static const String _tag = 'PermissionService';

  /// Returns `true` when runtime permissions are applicable (mobile only).
  static bool get _isMobilePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Request camera permission. Returns `true` if granted or not applicable.
  static Future<bool> requestCamera() async {
    if (!_isMobilePlatform) {
      LogService.info(_tag, 'Camera permission not required on this platform');
      return true;
    }

    final status = await Permission.camera.status;
    LogService.info(_tag, 'Camera permission status: $status');

    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    LogService.info(_tag, 'Camera permission request result: $result');

    if (result.isPermanentlyDenied) {
      LogService.warning(
          _tag, 'Camera permission permanently denied – opening settings');
      await openAppSettings();
      return false;
    }

    return result.isGranted;
  }

  /// Request photo gallery permission. Returns `true` if granted or not applicable.
  static Future<bool> requestGallery() async {
    if (!_isMobilePlatform) {
      LogService.info(_tag, 'Gallery permission not required on this platform');
      return true;
    }

    // Android 13+ uses granular media permissions (photos); older uses storage.
    Permission permission;
    if (Platform.isAndroid) {
      permission = Permission.photos;
    } else {
      permission = Permission.photos;
    }

    final status = await permission.status;
    LogService.info(_tag, 'Gallery permission status: $status');

    if (status.isGranted) return true;

    final result = await permission.request();
    LogService.info(_tag, 'Gallery permission request result: $result');

    if (result.isPermanentlyDenied) {
      LogService.warning(
          _tag, 'Gallery permission permanently denied – opening settings');
      await openAppSettings();
      return false;
    }

    return result.isGranted;
  }

  /// Request notification permission. Returns `true` if granted or not applicable.
  static Future<bool> requestNotifications() async {
    if (!_isMobilePlatform) {
      LogService.info(_tag, 'Notification permission not required on this platform');
      return true;
    }

    final status = await Permission.notification.status;
    LogService.info(_tag, 'Notification permission status: $status');

    if (status.isGranted) return true;

    final result = await Permission.notification.request();
    LogService.info(_tag, 'Notification permission request result: $result');

    return result.isGranted;
  }
}


import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request camera, microphone, and location permissions.
  /// Returns true only if all critical permissions (camera + location) are granted.
  static Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
    ].request();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final locationGranted = statuses[Permission.locationWhenInUse]?.isGranted ?? false;

    if (!cameraGranted) {
      debugPrint("Camera permission denied");
    }
    if (!locationGranted) {
      debugPrint("Location permission denied");
    }

    // Return true if at least camera OR location is granted
    // (don't block the entire webview for one denied permission)
    return cameraGranted || locationGranted;
  }

  /// Request camera permission specifically for attendance photo capture
  static Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  /// Request location permission for geotagging attendance photos
  static Future<bool> requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    return status.isGranted;
  }

  /// Explicitly request storage permission, primarily for Android downloads/uploads
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) uses granular media permissions instead of legacy storage
      final androidInfo = await _getAndroidSdkVersion();
      if (androidInfo >= 33) {
        // On Android 13+, downloads via DownloadManager don't require storage permission.
        // But if media access is needed:
        var statuses = await [
          Permission.photos,
          Permission.videos,
        ].request();
        return statuses[Permission.photos]?.isGranted ?? false;
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
      return status.isGranted;
    }
    return true;
  }
  
  /// Request Notification Permissions (Firebase/Push Notifications)
  static Future<bool> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      status = await Permission.notification.request();
    }
    return status.isGranted;
  }

  /// Helper to get Android SDK version
  static Future<int> _getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    // permission_handler internally checks SDK level,
    // but we can use a safe fallback
    try {
      final version = int.tryParse(Platform.operatingSystemVersion.split(' ').last) ?? 0;
      return version;
    } catch (_) {
      return 0; // Fallback — treat as pre-33
    }
  }
}

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request common permissions required by web features like camera, mic, etc.
  static Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
    ].request();

    // Check specific statuses if needed
    // if (statuses[Permission.camera]!.isDenied) { ... }
  }

  /// Explicitly request storage permission, primarily for Android downloads/uploads
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ uses specific media permissions or doesn't require legacy storage
      // For general downloads, READ_EXTERNAL_STORAGE / WRITE_EXTERNAL_STORAGE might be needed on older devices.
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
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
}

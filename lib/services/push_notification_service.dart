import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:network_events/services/permission_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `await Firebase.initializeApp()` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  /// Get the cached FCM token (available after initialize())
  static String? get fcmToken => _fcmToken;

  static Future<void> initialize() async {
    // Request notification permissions (required on Android 13+ and iOS)
    final granted = await PermissionService.requestNotificationPermission();
    
    if (granted) {
      // Also request via Firebase's own permission API for iOS foreground settings
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
        }
      });

      // Handle notification taps when app is in background (not terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification tapped (background): ${message.data}');
        // You can navigate to a specific page here based on message.data
      });

      // Check if app was opened via a notification while terminated
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from terminated state via notification: ${initialMessage.data}');
      }

      // Get the FCM token for the device
      try {
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint("FCM Registration Token: $_fcmToken");
      } catch (e) {
        debugPrint("Error fetching FCM token: $e");
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint("FCM Token refreshed: $newToken");
      });
    } else {
      debugPrint("Notification permission denied — push notifications disabled.");
    }
  }
}

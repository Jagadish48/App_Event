import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:network_events/screens/webview_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:network_events/services/permission_service.dart';
import 'package:network_events/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Flutter Downloader for file downloads
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  
  // Initialize Firebase (Requires google-services.json / GoogleService-Info.plist)
  try {
    await Firebase.initializeApp();
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e. Ensure config files are present.");
  }
  
  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(const NetworkEventsApp());
}

class NetworkEventsApp extends StatelessWidget {
  const NetworkEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetworkEvents',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WebViewScreen(),
    );
  }
}

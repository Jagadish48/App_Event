import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:network_events/screens/webview_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:network_events/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable edge-to-edge — app draws behind system bars, no white bar
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  
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
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
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

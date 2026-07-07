import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:network_events/services/permission_service.dart';
import 'package:network_events/services/download_service.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone; geolocation",
      iframeAllowFullscreen: true,
      javaScriptEnabled: true,
      domStorageEnabled: true,
      supportZoom: false,
      disableContextMenu: false,
      builtInZoomControls: false,
      displayZoomControls: false,
      // Cookie handling
      thirdPartyCookiesEnabled: true,
      // Geolocation — required for location capture / geotagging
      geolocationEnabled: true,
  );

  PullToRefreshController? pullToRefreshController;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  String url = "https://app.networkevents.net/";
  double progress = 0;
  bool isOffline = false;
  Color scaffoldBgColor = const Color(0xFF0F172A);
  Brightness iconBrightness = Brightness.light;

  @override
  void initState() {
    super.initState();
    
    // Proactively request Camera and Location permissions on startup.
    // Android requires CAMERA permission to be granted at runtime before allowing
    // the WebView to launch the camera via a file chooser intent.
    PermissionService.requestPermissions();
    
    // Check initial connectivity
    Connectivity().checkConnectivity().then((results) {
      if (results.contains(ConnectivityResult.none)) {
        setState(() { isOffline = true; });
      }
    });
    
    // Listen to connectivity changes — store subscription for cleanup
    _connectivitySub = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        setState(() { isOffline = true; });
      } else {
        setState(() { isOffline = false; });
        webViewController?.reload();
      }
    });

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  // Handle Android Back button properly
  Future<bool> _goBack(BuildContext context) async {
    if (webViewController != null) {
      if (await webViewController!.canGoBack()) {
        webViewController!.goBack();
        return false;
      }
    }
    return true; // Exit app if at root
  }

  @override
  Widget build(BuildContext context) {
    if (isOffline) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 100,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Internet Connection',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please check your network settings and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Connectivity().checkConnectivity().then((results) {
                      if (!results.contains(ConnectivityResult.none)) {
                        setState(() { isOffline = false; });
                        webViewController?.reload();
                      }
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _goBack(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBgColor, // Dynamic background
        body: SafeArea(
          top: true,
          bottom: false,
          child: Stack(
            children: [
              InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(url: WebUri(url)),
                initialSettings: settings,
                pullToRefreshController: pullToRefreshController,
                onWebViewCreated: (controller) {
                  webViewController = controller;
                  
                  controller.addJavaScriptHandler(handlerName: 'themeChange', callback: (args) {
                    if (args.length >= 4) {
                      bool isDark = args[3] as bool;
                      
                      if (!mounted) return;
                      setState(() {
                        // Hardcode the expected background colors because the web body might be transparent (rgb 0,0,0)
                        scaffoldBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFEBF2F8);
                        iconBrightness = isDark ? Brightness.light : Brightness.dark;
                        
                        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                          statusBarColor: Colors.transparent,
                          systemNavigationBarColor: Colors.transparent,
                          statusBarIconBrightness: iconBrightness,
                          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
                        ));
                      });
                    }
                  });
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    this.url = url.toString();
                  });
                },
                // Handle runtime permissions for Camera/Mic/Location from the webview
                onPermissionRequest: (controller, request) async {
                  // Request native permissions for camera, mic, location
                  final granted = await PermissionService.requestPermissions();
                  
                  if (granted) {
                    return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.GRANT);
                  } else {
                    return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.DENY);
                  }
                },
                // Android-specific: handle geolocation permission prompts from the WebView
                onGeolocationPermissionsShowPrompt: (controller, origin) async {
                  final locationGranted = await PermissionService.requestLocationPermission();
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: locationGranted,
                    retain: true,
                  );
                },
                // Handle external vs internal link routing
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url!;
                  
                  // If it's not our app domain, try to launch externally
                  if (!uri.host.contains("app.networkevents.net")) {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onDownloadStartRequest: (controller, request) async {
                   await PermissionService.requestStoragePermission();
                   await DownloadService.downloadFile(request.url.toString(), request.suggestedFilename ?? 'download');
                },
                onLoadStop: (controller, url) async {
                  pullToRefreshController?.endRefreshing();
                  setState(() {
                    this.url = url.toString();
                  });
                  
                  // Force camera app for file uploads and sync theme colors
                  await controller.evaluateJavascript(source: """
                    (function() {
                      // 1. Camera Fix
                      function forceCamera() {
                        document.querySelectorAll('input[type="file"][accept*="image"]').forEach(function(el) {
                          if (!el.hasAttribute('capture')) {
                            el.setAttribute('capture', 'user');
                          }
                        });
                      }
                      forceCamera();
                      const camObserver = new MutationObserver(forceCamera);
                      camObserver.observe(document.body, { childList: true, subtree: true });

                      // 2. Theme Sync
                      function sendTheme() {
                        var isDark = document.documentElement.getAttribute('data-theme') === 'dark';
                        var bgColor = window.getComputedStyle(document.body).backgroundColor;
                        var rgb = bgColor.match(/\\d+/g);
                        if (rgb && rgb.length >= 3 && window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                          window.flutter_inappwebview.callHandler('themeChange', parseInt(rgb[0]), parseInt(rgb[1]), parseInt(rgb[2]), isDark);
                        }
                      }
                      sendTheme();
                      const themeObserver = new MutationObserver(function(mutations) {
                        mutations.forEach(function(m) {
                          if (m.attributeName === 'data-theme' || m.attributeName === 'class') {
                            sendTheme();
                          }
                        });
                      });
                      themeObserver.observe(document.documentElement, { attributes: true });
                      themeObserver.observe(document.body, { attributes: true });
                    })();
                  """);
                },
                onReceivedError: (controller, request, error) {
                  pullToRefreshController?.endRefreshing();
                  if (request.isForMainFrame ?? true) {
                    setState(() {
                      isOffline = true;
                    });
                  }
                },
                onProgressChanged: (controller, progress) {
                  if (progress == 100) {
                    pullToRefreshController?.endRefreshing();
                  }
                  setState(() {
                    this.progress = progress / 100;
                  });
                },
              ),
              progress < 1.0
                  ? LinearProgressIndicator(value: progress, color: Colors.blue)
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

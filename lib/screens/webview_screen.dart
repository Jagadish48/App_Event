import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:network_events/screens/offline_screen.dart';
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
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true,
      javaScriptEnabled: true,
      domStorageEnabled: true,
      supportZoom: false,
      disableContextMenu: false,
      builtInZoomControls: false,
      displayZoomControls: false,
      // Cookie handling
      thirdPartyCookiesEnabled: true,
  );

  PullToRefreshController? pullToRefreshController;
  String url = "https://app.networkevents.net/";
  double progress = 0;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    
    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      if (result == ConnectivityResult.none) {
        setState(() { isOffline = true; });
      }
    });
    
    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
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
      return OfflineScreen(onRetry: () {
        Connectivity().checkConnectivity().then((result) {
          if (result != ConnectivityResult.none) {
            setState(() { isOffline = false; });
            webViewController?.reload();
          }
        });
      });
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _goBack(context);
        if (shouldPop && context.mounted) {
          // If we can't go back in webview, pop the screen
          // Use SystemNavigator.pop() or Navigator.pop(context)
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Match web app dark background
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
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    this.url = url.toString();
                  });
                },
                // Handle runtime permissions for Camera/Mic/Storage directly from webview
                onPermissionRequest: (controller, request) async {
                  await PermissionService.requestPermissions();
                  return PermissionResponse(
                      resources: request.resources,
                      action: PermissionResponseAction.GRANT);
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

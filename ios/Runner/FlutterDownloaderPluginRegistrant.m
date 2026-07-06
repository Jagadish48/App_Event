#import "FlutterDownloaderPluginRegistrant.h"
#import "FlutterDownloaderPlugin.h"

void RegisterFlutterDownloaderPluginRegistrant(id<FlutterPluginRegistry> registry) {
  if (![registry hasPlugin:@"FlutterDownloaderPlugin"]) {
    [FlutterDownloaderPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterDownloaderPlugin"]];
  }
}

void SetFlutterDownloaderPluginRegistrantCallback(void) {
  [FlutterDownloaderPlugin setPluginRegistrantCallback:RegisterFlutterDownloaderPluginRegistrant];
}

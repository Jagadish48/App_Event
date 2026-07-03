import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static Future<void> downloadFile(String url, String filename) async {
    Directory? baseStorage;
    
    if (Platform.isAndroid) {
      baseStorage = await getExternalStorageDirectory();
    } else {
      baseStorage = await getApplicationDocumentsDirectory();
    }
    
    if (baseStorage != null) {
      await FlutterDownloader.enqueue(
        url: url,
        savedDir: baseStorage.path,
        fileName: filename,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true,
      );
    }
  }
}

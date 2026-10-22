import 'dart:io' show Platform;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

abstract final class FolderPickerService {
  /// Request permissions for reading audio media files on the current platform.
  static Future<bool> requestStoragePermission() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }

    // Android 13+ (API 33+) requires READ_MEDIA_AUDIO
    final audioStatus = await Permission.audio.status;
    if (audioStatus.isGranted) return true;

    if (audioStatus.isDenied) {
      final requested = await Permission.audio.request();
      if (requested.isGranted) return true;
    }

    // Fallback for Android 12 and below (READ_EXTERNAL_STORAGE)
    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) return true;

    final storageRequested = await Permission.storage.request();
    return storageRequested.isGranted;
  }

  /// Prompts user to select a directory folder.
  static Future<String?> pickFolder() async {
    try {
      final granted = await requestStoragePermission();
      if (!granted) return null;

      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Music Folder',
      );
      return result;
    } catch (_) {
      return null;
    }
  }
}

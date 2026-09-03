// lib/services/file_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FileService {
  /// Save bytes into a temp file (overwrites if exists).
  Future<File> saveTempFile(String fileName, List<int> bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$fileName';
      final file = File(path);
      return await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      // Bubble up a consistent error
      throw FileSystemException('Failed to write temp file: $fileName', e.toString());
    }
  }

  /// Save bytes into app documents dir, creating parent dirs if needed.
  Future<File> saveInDocuments(String relativePath, List<int> bytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$relativePath');
      await file.parent.create(recursive: true);
      return await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      throw FileSystemException('Failed to write document: $relativePath', e.toString());
    }
  }

  Future<void> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {/* ignore */}
  }

  Future<Directory> getAppDocumentsDirectory() => getApplicationDocumentsDirectory();

  Future<Directory> getTempDirectory() => getTemporaryDirectory();
}

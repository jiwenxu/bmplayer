// lib/data/services/file_import_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class FileImportService {
  // 导入 TXT 文件
  static Future<List<String>> importFromTxt() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        // 按行分割并过滤空行
        return content
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
      }

      return [];
    } catch (e) {
      print('导入 TXT 文件失败: $e');
      rethrow;
    }
  }

  // 导出播放列表到 TXT 文件
  static Future<void> exportToTxt(List<String> urls, String filename) async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '导出播放列表',
        fileName: '$filename.txt',
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(urls.join('\n'));
      }
    } catch (e) {
      print('导出 TXT 文件失败: $e');
      rethrow;
    }
  }

  // 检查文件是否为支持的文本文件
  static bool isSupportedTextFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.txt';
  }
}

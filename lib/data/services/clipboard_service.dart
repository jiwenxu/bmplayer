// lib/data/services/clipboard_service.dart
import 'package:flutter/services.dart';

class ClipboardService {
  // 监听剪贴板变化（需要用户交互）
  static Future<String?> getClipboardText() async {
    try {
      final text = await Clipboard.getData(Clipboard.kTextPlain);
      return text?.text;
    } catch (e) {
      print('获取剪贴板内容失败: $e');
      return null;
    }
  }

  // 检查文本中是否包含 B站链接
  static bool containsBilibiliUrl(String text) {
    final regex = RegExp(
      r'https?://(?:www\.)?bilibili\.com/video/((BV[0-9A-Za-z]+)|(av\d+))[/\?]?',
      caseSensitive: false,
    );
    return regex.hasMatch(text);
  }

  // 从文本中提取所有 B站链接
  static List<String> extractBilibiliUrls(String text) {
    final regex = RegExp(
      r'https?://(?:www\.)?bilibili\.com/video/((BV[0-9A-Za-z]+)|(av\d+))[/\?]?',
      caseSensitive: false,
    );

    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  // 复制文本到剪贴板
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}

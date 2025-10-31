// lib/presentation/screens/import_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/audio_info.dart';
import '../providers/audio_provider.dart';
import '../../data/services/clipboard_service.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isParsing = false;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    final clipboardText = await ClipboardService.getClipboardText();
    if (clipboardText != null &&
        ClipboardService.containsBilibiliUrl(clipboardText)) {
      _textController.text = clipboardText;
    }
  }

  Future<void> _parseUrls() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isParsing = true;
    });

    try {
      final batchImport = ref.read(batchImportProvider.notifier);
      await batchImport.parseMultipleUrls(_textController.text);

      // 显示解析结果
      _showParseResults();
    } catch (e) {
      _showError('解析失败: $e');
    } finally {
      setState(() {
        _isParsing = false;
      });
    }
  }

  Future<void> _importFromTxt() async {
    setState(() {
      _isParsing = true;
    });

    try {
      final batchImport = ref.read(batchImportProvider.notifier);
      await batchImport.importFromTxt();

      // 显示解析结果
      _showParseResults();
    } catch (e) {
      _showError('导入失败: $e');
    } finally {
      setState(() {
        _isParsing = false;
      });
    }
  }

  void _showParseResults() {
    final results = ref.read(batchImportProvider);

    results.when(
      data: (audios) {
        if (audios.isNotEmpty) {
          _showAddToPlaylistDialog(audios);
        } else {
          _showError('未找到可解析的B站链接');
        }
      },
      loading: () {},
      error: (error, stack) {
        _showError('解析失败: $error');
      },
    );
  }

  void _showAddToPlaylistDialog(List<AudioInfo> audios) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解析成功'),
        content: Text('成功解析 ${audios.length} 个音频，是否添加到播放列表？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final batchImport = ref.read(batchImportProvider.notifier);
              batchImport.addToPlaylist(audios);
              Navigator.pop(context);
              Navigator.pop(context); // 返回主界面
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _clearInput() {
    _textController.clear();
    final batchImport = ref.read(batchImportProvider.notifier);
    batchImport.clearResults();
  }

  @override
  Widget build(BuildContext context) {
    final batchImportState = ref.watch(batchImportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('导入音频'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 输入框
            Expanded(
              child: Column(
                children: [
                  const Text(
                    '粘贴B站视频链接（支持批量，每行一个链接）',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText:
                            '例如: https://www.bilibili.com/video/BV1xx411c7mD\nhttps://www.bilibili.com/video/av123456',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.paste),
                          label: const Text('检查剪贴板'),
                          onPressed: _checkClipboard,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.clear),
                          label: const Text('清空'),
                          onPressed: _clearInput,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 导入按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isParsing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: _isParsing ? const Text('解析中...') : const Text('解析链接'),
                onPressed: _isParsing ? null : _parseUrls,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 文件导入按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.file_open),
                label: const Text('从TXT文件导入'),
                onPressed: _isParsing ? null : _importFromTxt,
              ),
            ),
            // 解析结果预览
            if (batchImportState is AsyncData<List<AudioInfo>> &&
                batchImportState.value.isNotEmpty)
              _buildResultsPreview(batchImportState.value),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsPreview(List<AudioInfo> audios) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '解析结果 (${audios.length} 个音频)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          ...audios
              .take(3)
              .map(
                (audio) => Text(
                  '• ${audio.title}',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          if (audios.length > 3) Text('... 还有 ${audios.length - 3} 个音频'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

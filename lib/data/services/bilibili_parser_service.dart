// lib/data/services/bilibili_parser_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../domain/models/bilibili_audio_info.dart';

class BilibiliParserService {
  Logger logger = Logger();
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';

  // 解析单个 B站链接
  Future<BilibiliAudioInfo?> parseUrl(String url) async {
    try {
      // 提取视频 ID
      final videoId = _extractVideoId(url);
      if (videoId == null) {
        throw Exception('无法解析 B站链接: $url');
      }

      // 获取视频信息
      final videoInfo = await _getVideoInfo(videoId);
      if (videoInfo == null) {
        throw Exception('无法获取视频信息');
      }

      return videoInfo;
    } catch (e) {
      logger.e('解析 B站链接失败: $e');
      rethrow;
    }
  }

  // 批量解析多个链接
  Future<List<BilibiliAudioInfo>> parseMultiple(String text) async {
    final urls = _extractUrls(text);
    final results = <BilibiliAudioInfo>[];

    for (final url in urls) {
      try {
        final audioInfo = await parseUrl(url);
        if (audioInfo != null) {
          results.add(audioInfo);
        }
      } catch (e) {
        logger.e('解析链接失败 $url: $e');
        // 继续处理其他链接
      }
    }

    return results;
  }

  // 从文本中提取所有 B站链接
  List<String> _extractUrls(String text) {
    final regex = RegExp(
      r'https?://(?:www\.)?bilibili\.com/video/((BV[0-9A-Za-z]+)|(av\d+))[/\?]?',
      caseSensitive: false,
    );

    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  // 提取视频 ID
  String? _extractVideoId(String url) {
    final bvRegex = RegExp(r'BV[0-9A-Za-z]+');
    final avRegex = RegExp(r'av\d+');

    final bvMatch = bvRegex.firstMatch(url);
    if (bvMatch != null) {
      return bvMatch.group(0);
    }

    final avMatch = avRegex.firstMatch(url);
    if (avMatch != null) {
      return avMatch.group(0);
    }

    return null;
  }

  // 获取视频信息
  Future<BilibiliAudioInfo?> _getVideoInfo(String videoId) async {
    try {
      // 构造 API 请求 URL
      final apiUrl =
          'https://api.bilibili.com/x/web-interface/view?bvid=$videoId';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['code'] == 0) {
          return await _parseVideoData(jsonData['data']);
        }
      }

      return null;
    } catch (e) {
      logger.e('获取视频信息失败: $e');
      return null;
    }
  }

  // 解析视频数据
  Future<BilibiliAudioInfo> _parseVideoData(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? '未知标题';
    final cover = data['pic'] as String?;
    final owner = data['owner'] as Map<String, dynamic>?;
    final artist = owner?['name'] as String? ?? '未知UP主';
    final duration = data['duration'] as int? ?? 0;

    // 构造音频 URL（这里需要实际的音频流地址）
    // 注意：实际应用中需要获取真实的音频流地址
    final audioUrl = await _constructAudioUrl(data['bvid'] as String? ?? '');
    final savePath = await getSavePath(data['bvid'] as String? ?? '');
    await downloadAudio(audioUrl, data['bvid'] as String? ?? '', savePath);
    final audioPath = await convertToMp3(savePath);
    await File(savePath).delete();
    
    return BilibiliAudioInfo(
      id: data['bvid'] as String? ?? '',
      title: _cleanTitle(title),
      audioUrl: audioUrl,
      coverUrl: cover,
      audioPath: audioPath,
      artist: artist,
      duration: Duration(seconds: duration),
      originalUrl: 'https://www.bilibili.com/video/${data['bvid']}',
    );
  }

  // 清理标题
  String _cleanTitle(String title) {
    // 移除可能影响文件名的字符
    return title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
  }

  // 构造音频 URL（模拟，实际需要真实实现）
  Future<String> _constructAudioUrl(String bvid) async {
    // 第一步：获取视频CID
    final infoUrl = 'https://api.bilibili.com/x/web-interface/view?bvid=$bvid';
    final infoResp = await http.get(Uri.parse(infoUrl));
    final infoJson = jsonDecode(infoResp.body);
    final cid = infoJson['data']['cid'];
    if (cid == null) throw '未能获取视频CID';

    // 第二步：获取播放信息
    final playUrl =
        'https://api.bilibili.com/x/player/playurl?bvid=$bvid&cid=$cid&fnval=16';
    final playResp = await http.get(Uri.parse(playUrl));
    final playJson = jsonDecode(playResp.body);

    final audioList = playJson['data']?['dash']?['audio'];
    if (audioList == null || audioList.isEmpty) throw '未找到音频流信息';

    final audioUrl = audioList[0]['baseUrl'];
    if (audioUrl == null) throw '未获取到音频URL';

    return audioUrl;
  }

  /// 下载音频文件
  Future<void> downloadAudio(
    String audioUrl,
    String bvId,
    String savePath,
  ) async {
    final headers = {
      'Referer': 'https://www.bilibili.com/',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      'Origin': 'https://www.bilibili.com',
    };

    final response = await http.get(Uri.parse(audioUrl), headers: headers);
    if (response.statusCode != 200) {
      throw '请求失败，状态码 ${response.statusCode}';
    }
    final file = File(savePath);
    await file.writeAsBytes(response.bodyBytes);
  }

  /// 获取保存路径（跨平台）
  Future<String> getSavePath(String bvId) async {
    final fileName = '$bvId.m4s';

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // 与程序同目录
      final dir = '${Directory.current.path}${p.separator}save';
      if (!Directory(dir).existsSync()) {
        Directory(dir).createSync(recursive: true);
      }
      return p.join(dir, fileName);
    } else if (Platform.isAndroid || Platform.isIOS) {
      // 使用可写目录（Documents）
      final dir = await getApplicationDocumentsDirectory();
      return p.join(dir.path, fileName);
    } else {
      // 其他平台默认当前目录
      return p.join(Directory.current.path, fileName);
    }
  }

  Future<String> convertToMp3(String inputPath) async {
    final outputPath = inputPath.replaceAll('.m4s', '.mp3');
    if (Platform.isWindows) {
      try {
        final result = await Process.run('ffmpeg', [
          '-i',
          inputPath,
          '-vn',
          '-acodec',
          'libmp3lame',
          '-q:a',
          '2',
          outputPath,
        ]);

        if (result.exitCode == 0) {
          logger.i('✅ FFmpeg 转换成功: $outputPath');
        } else {
          logger.e('❌ FFmpeg 转换失败:\n${result.stderr}');
          throw 'FFmpeg 转换失败';
        }
      } catch (e) {
        logger.e('❌ 调用 FFmpeg 出错: $e');
        rethrow;
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      await FFmpegKit.execute(
        '-i "$inputPath" -vn -acodec libmp3lame -q:a 2 "$outputPath"',
      );
    }
    return Directory(outputPath).path;
  }
}

import 'dart:io';

import 'package:flutter/services.dart';

import 'audio_player_service.dart';

class NativeIntegrationService {
  NativeIntegrationService(this._audioServiceAccessor);

  final AudioPlayerService Function() _audioServiceAccessor;
  final MethodChannel _channel = const MethodChannel('bmplayer/system_tray');

  bool _initialized = false;

  Future<void> init() async {
    if (!Platform.isWindows || _initialized) {
      return;
    }
    _initialized = true;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> dispose() async {
    if (!Platform.isWindows || !_initialized) {
      return;
    }
    _channel.setMethodCallHandler(null);
    _initialized = false;
  }

  Future<void> showWindow() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('showWindow');
    } catch (_) {}
  }

  Future<void> hideWindow() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('hideWindow');
    } catch (_) {}
  }

  Future<void> toggleWindow() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('toggleWindow');
    } catch (_) {}
  }

  Future<void> exitApp() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('exitApp');
    } catch (_) {}
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'trayEvent') {
      return;
    }
    final event = call.arguments as String?;
    if (event == null) {
      return;
    }

    final audioService = _audioServiceAccessor();

    switch (event) {
      case 'trayPlayPause':
        await audioService.togglePlayPause();
        break;
      case 'trayNext':
        await audioService.next();
        break;
      case 'trayPrevious':
        await audioService.previous();
        break;
      case 'trayShow':
      case 'trayHide':
      case 'trayToggle':
      default:
        break;
    }
  }
}

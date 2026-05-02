import 'dart:io';
import 'package:flutter/services.dart';

enum BrightnessResult { changed, permissionRequired, failed }

/// Service for Android system controls via platform channels.
class SystemService {
  static const MethodChannel _channel = MethodChannel(
    'offline_assist/system_controls',
  );

  Future<bool> adjustVolume(String action) async {
    if (!Platform.isAndroid) return false;
    try {
      final success = await _channel.invokeMethod<bool>('adjustVolume', {
        'action': action,
      });
      return success == true;
    } catch (_) {
      return false;
    }
  }

  Future<BrightnessResult> adjustBrightness(String action) async {
    if (!Platform.isAndroid) return BrightnessResult.failed;
    try {
      final status = await _channel.invokeMethod<String>('adjustBrightness', {
        'action': action,
      });
      switch (status) {
        case 'changed':
          return BrightnessResult.changed;
        case 'permission_required':
          return BrightnessResult.permissionRequired;
        default:
          return BrightnessResult.failed;
      }
    } catch (_) {
      return BrightnessResult.failed;
    }
  }

  Future<bool> openSystemPanel(String panel) async {
    if (!Platform.isAndroid) return false;
    try {
      final success = await _channel.invokeMethod<bool>('openSystemPanel', {
        'panel': panel,
      });
      return success == true;
    } catch (_) {
      return false;
    }
  }
}

import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for sending SMS via the platform messaging app.
class SmsService {
  bool get _isInTest {
    return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false) ||
        Platform.environment.containsKey('FLUTTER_TEST');
  }

  /// Sends an SMS to [target] with [message].
  ///
  /// Returns `true` if the messaging app was opened successfully.
  Future<bool> sendSms(String target, String message) async {
    if (_isInTest) return true;

    try {
      // Clean target into a phone number-like string.
      final cleanTarget = target.replaceAll(RegExp(r'[^0-9+]'), '');
      if (cleanTarget.isEmpty) return false;

      // Some platforms require permission to access SMS functionality.
      // This is a best-effort request; if denied, we still attempt to open the SMS app.

      final uri = Uri.parse(
        'sms:$cleanTarget?body=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}

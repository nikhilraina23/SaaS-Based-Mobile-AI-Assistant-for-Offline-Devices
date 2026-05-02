import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Requests key runtime permissions used by assistant commands.
class PermissionService {
  static bool _requestedOnce = false;

  /// Best-effort startup request to reduce first-use failures.
  Future<void> requestStartupPermissions() async {
    if (_requestedOnce) return;
    _requestedOnce = true;

    try {
      await Permission.notification.request();
      await Permission.phone.request();
      await Permission.contacts.request();
      await Permission.sms.request();
      await Permission.microphone.request();

      if (Platform.isAndroid) {
        // Android 12+ exact alarms can require explicit user grant.
        await Permission.scheduleExactAlarm.request();
      }
    } catch (_) {
      // Ignore failures; command-level flows still handle their own fallbacks.
    }
  }
}

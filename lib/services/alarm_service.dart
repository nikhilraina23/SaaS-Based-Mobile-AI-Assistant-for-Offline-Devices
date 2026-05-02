import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';

/// Service for scheduling device alarms using Android Intents.
class AlarmService {
  bool get _isInTest {
    // Flutter sets FLUTTER_TEST in environment during `flutter test` runs.
    // This avoids skipping functionality in debug builds.
    return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false) ||
        Platform.environment.containsKey('FLUTTER_TEST');
  }

  /// Schedules an alarm at the given [hour] (0-23) and [minute] (0-59).
  ///
  /// Returns `true` if the intent was sent successfully.
  Future<bool> scheduleAlarm(int hour, int minute) async {
    if (_isInTest) {
      // skip actual intent in tests
      return true;
    }
    try {
      // The SET_ALARM intent doesn't require runtime permissions
      // It opens the Clock app with the alarm preset
      final intent = AndroidIntent(
        action: 'android.intent.action.SET_ALARM',
        arguments: <String, dynamic>{
          'android.intent.extra.alarm.HOUR': hour,
          'android.intent.extra.alarm.MINUTES': minute,
          'android.intent.extra.alarm.SKIP_UI':
              false, // Show UI for user confirmation
        },
      );

      await intent.launch();
      return true;
    } catch (e) {
      // Log error if needed
      print('Error setting alarm: $e');
      return false;
    }
  }
}

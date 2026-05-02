import 'package:flutter_test/flutter_test.dart';
import 'package:offline_assist/core/intent_detector.dart';
import 'package:offline_assist/models/intent.dart';

void main() {
  final detector = IntentDetector();

  group('IntentDetector', () {
    // --- Alarm ---
    test('detects "alarm" prefix', () {
      expect(detector.detect('alarm 7:00 am'), Intent.alarm);
    });

    test('detects "set alarm"', () {
      expect(detector.detect('set alarm 7:00 am'), Intent.alarm);
    });

    test('detects "set an alarm"', () {
      expect(detector.detect('set an alarm for 7 am'), Intent.alarm);
    });

    test('detects alarm with mixed case', () {
      expect(detector.detect('SET ALARM 7:00 AM'), Intent.alarm);
    });

    // --- Reminder ---
    test('detects "remind me"', () {
      expect(detector.detect('remind me meeting at 6 pm'), Intent.reminder);
    });

    test('detects "remind" alone', () {
      expect(detector.detect('remind call john at 5 pm'), Intent.reminder);
    });

    // --- Call ---
    test('detects "call"', () {
      expect(detector.detect('call mom'), Intent.call);
    });

    test('detects call with number', () {
      expect(detector.detect('call 9876543210'), Intent.call);
    });

    // --- Open app ---
    test('detects "open"', () {
      expect(detector.detect('open calculator'), Intent.openApp);
    });

    // --- SMS ---
    test('detects "sms"', () {
      expect(detector.detect('sms john hello'), Intent.sms);
    });

    test('detects "send sms"', () {
      expect(detector.detect('send sms john hello'), Intent.sms);
    });

    // --- Unknown ---
    test('returns unknown for unrecognised input', () {
      expect(detector.detect('dance'), Intent.unknown);
    });

    test('returns unknown for empty input', () {
      expect(detector.detect(''), Intent.unknown);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_assist/core/entity_extractor.dart';

void main() {
  final extractor = EntityExtractor();

  // ---------------------------------------------------------------------------
  // Alarm extraction
  // ---------------------------------------------------------------------------
  group('EntityExtractor.extractAlarm', () {
    test('parses "alarm 7:30 am"', () {
      final result = extractor.extractAlarm('alarm 7:30 am');
      expect(result['hour'], 7);
      expect(result['minute'], 30);
      expect(result.containsKey('count'), false);
    });

    test('parses 24h format "alarm 19:45"', () {
      final result = extractor.extractAlarm('alarm 19:45');
      expect(result['hour'], 19);
      expect(result['minute'], 45);
    });

    test('parses "set alarm 7 am" (no minutes)', () {
      final result = extractor.extractAlarm('set alarm 7 am');
      expect(result['hour'], 7);
      expect(result['minute'], 0);
    });

    test('parses "set alarm at 7" (no period)', () {
      final result = extractor.extractAlarm('set alarm at 7');
      expect(result['hour'], 7);
      expect(result['minute'], 0);
    });

    test('parses "set alarm 7:00 am 5" (with count)', () {
      final result = extractor.extractAlarm('set alarm 7:00 am 5');
      expect(result['hour'], 7);
      expect(result['minute'], 0);
      expect(result['count'], 5);
    });

    test('converts 12 pm to 12 (noon)', () {
      final result = extractor.extractAlarm('alarm 12:00 pm');
      expect(result['hour'], 12);
      expect(result['minute'], 0);
    });

    test('converts 12 am to 0 (midnight)', () {
      final result = extractor.extractAlarm('alarm 12:00 am');
      expect(result['hour'], 0);
      expect(result['minute'], 0);
    });

    test('returns error for invalid input', () {
      final result = extractor.extractAlarm('alarm now');
      expect(result.containsKey('error'), true);
    });
  });

  // ---------------------------------------------------------------------------
  // Reminder extraction
  // ---------------------------------------------------------------------------
  group('EntityExtractor.extractReminder', () {
    test('parses "remind me meeting at 6 pm"', () {
      final result = extractor.extractReminder('remind me meeting at 6 pm');
      expect(result['message'], 'meeting');
      expect(result['hour'], 18);
      expect(result['minute'], 0);
    });

    test('parses "remind me to call john at 5:30 pm"', () {
      final result =
          extractor.extractReminder('remind me to call john at 5:30 pm');
      expect(result['message'], 'call john');
      expect(result['hour'], 17);
      expect(result['minute'], 30);
    });

    test('parses reminder without am/pm', () {
      final result = extractor.extractReminder('remind me standup at 9');
      expect(result['message'], 'standup');
      expect(result['hour'], 9);
      expect(result['minute'], 0);
    });

    test('parses 24h format with minutes', () {
      final result = extractor.extractReminder('remind me workout at 17:22');
      expect(result['message'], 'workout');
      expect(result['hour'], 17);
      expect(result['minute'], 22);
    });

    test('returns error when no time found', () {
      final result = extractor.extractReminder('remind me something');
      expect(result.containsKey('error'), true);
    });
  });

  // ---------------------------------------------------------------------------
  // Call extraction
  // ---------------------------------------------------------------------------
  group('EntityExtractor.extractCall', () {
    test('parses "call mom"', () {
      final result = extractor.extractCall('call mom');
      expect(result['target'], 'mom');
    });

    test('parses "call 9876543210"', () {
      final result = extractor.extractCall('call 9876543210');
      expect(result['target'], '9876543210');
    });

    test('returns error for empty call', () {
      final result = extractor.extractCall('call');
      expect(result.containsKey('error'), true);
    });
  });
}

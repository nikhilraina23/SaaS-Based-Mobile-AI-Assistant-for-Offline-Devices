import 'package:flutter_test/flutter_test.dart';
import 'package:offline_assist/commands/alarm_command.dart';

void main() {
  final command = AlarmCommand();

  group('AlarmCommand', () {
    test('single alarm', () async {
      final result = await command.execute({'hour': 7, 'minute': 0});
      expect(result, 'Alarm set for 7:00');
    });

    test('single alarm with minutes', () async {
      final result = await command.execute({'hour': 19, 'minute': 45});
      expect(result, 'Alarm set for 19:45');
    });

    test('multi-alarm with count=3', () async {
      final result =
          await command.execute({'hour': 7, 'minute': 0, 'count': 3});
      expect(result, 'Set 3 alarms: 7:00, 7:01, 7:02');
    });

    test('multi-alarm with count=5', () async {
      final result =
          await command.execute({'hour': 7, 'minute': 0, 'count': 5});
      expect(result, 'Set 5 alarms: 7:00, 7:01, 7:02, 7:03, 7:04');
    });

    test('returns error from entities', () async {
      final result =
          await command.execute({'error': 'Invalid time format'});
      expect(result, 'Invalid time format');
    });
  });
}

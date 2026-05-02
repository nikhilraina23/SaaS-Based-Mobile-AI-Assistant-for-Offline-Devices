import 'package:flutter_test/flutter_test.dart';
import 'package:offline_assist/core/command_engine.dart';

void main() {
  final engine = CommandEngine();

  // ---- Original tests (backward compatibility) ----

  test('call command', () async {
    final result = await engine.process('call mom');
    expect(result, 'Calling mom...');
  });

  test('unknown command', () async {
    final result = await engine.process('dance');
    expect(result, 'Unknown command');
  });

  test('alarm parsing with am', () async {
    final result = await engine.process('alarm 7:30 am');
    expect(result, 'Alarm set for 7:30');
  });

  test('alarm parsing 24h', () async {
    final result = await engine.process('alarm 19:45');
    expect(result, 'Alarm set for 19:45');
  });

  // ---- New tests ----

  group('Alarm variations', () {
    test('"set alarm 7:00 am" via multi-word trigger', () async {
      final result = await engine.process('set alarm 7:00 am');
      expect(result, 'Alarm set for 7:00');
    });

    test('"set alarm 7 am" (no minutes)', () async {
      final result = await engine.process('set alarm 7 am');
      expect(result, 'Alarm set for 7:00');
    });

    test('"set alarm 7:00 am 3" (multi-alarm)', () async {
      final result = await engine.process('set alarm 7:00 am 3');
      expect(result, 'Set 3 alarms: 7:00, 7:01, 7:02');
    });
  });

  group('Reminder', () {
    test('"remind me meeting at 6 pm"', () async {
      final result = await engine.process('remind me meeting at 6 pm');
      expect(result, 'Reminder set: "meeting" at 18:00');
    });

    test('"remind me to call john at 5:30 pm"', () async {
      final result =
          await engine.process('remind me to call john at 5:30 pm');
      expect(result, 'Reminder set: "call john" at 17:30');
    });
  });

  group('Call', () {
    test('"call 9876543210"', () async {
      final result = await engine.process('call 9876543210');
      expect(result, 'Calling 9876543210...');
    });
  });

  group('Open app', () {
    test('"open calculator"', () async {
      final result = await engine.process('open calculator');
      expect(result, 'Opening calculator...');
    });
  });

  group('SMS', () {
    test('"sms john hello"', () async {
      final result = await engine.process('sms john hello');
      expect(result, 'Sending SMS...');
    });
  });
}
import '../utils/text_normalizer.dart';

/// Extracts structured entities from normalized user input for each intent type.
class EntityExtractor {
  // ---------------------------------------------------------------------------
  // Alarm
  // ---------------------------------------------------------------------------

  /// Parses alarm entities from [input].
  ///
  /// Recognised formats:
  /// - `set alarm 7:00 am`
  /// - `set alarm 7 am`
  /// - `alarm 19:30`
  /// - `set alarm 7:00 am 5`  (with count)
  /// - `set alarm at 7`
  ///
  /// Returns keys: `hour`, `minute`, and optionally `count`.
  /// On failure returns `{"error": "..."}`.
  Map<String, dynamic> extractAlarm(String input) {
    final normalized = TextNormalizer.normalize(input);

    // Regex: optional hours:minutes, optional am/pm, optional trailing count
    final regex = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s?(am|pm)?\s*(\d+)?$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(normalized);

    if (match == null) {
      return {'error': 'Invalid time format'};
    }

    int hour = int.parse(match.group(1)!);
    int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
    String? period = match.group(3)?.toLowerCase();
    int? count = match.group(4) != null ? int.parse(match.group(4)!) : null;

    // 12-hour → 24-hour conversion
    if (period == 'pm' && hour < 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;

    final result = <String, dynamic>{'hour': hour, 'minute': minute};
    if (count != null && count > 1) {
      result['count'] = count;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Reminder
  // ---------------------------------------------------------------------------

  /// Parses reminder entities from [input].
  ///
  /// Recognised formats:
  /// - `remind me meeting at 6 pm`
  /// - `remind me to call john at 5:30 pm`
  /// - `
  /// `
  /// - `remind me lunch at 12`
  ///
  /// Returns keys: `message`, `hour`, `minute`.
  /// On failure returns `{"error": "..."}`.
  Map<String, dynamic> extractReminder(String input) {
    final normalized = TextNormalizer.normalize(input);

    // Strip "remind me (to)?" prefix to isolate the body
    final body = normalized
        .replaceFirst(RegExp(r'^remind\s+me\s+(to\s+)?'), '')
        .trim();

    // Look for "at <time>" at the end; allow optional punctuation after time
    final regex = RegExp(
      r'(.+?)\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?[\.!?]?$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(body);

    if (match == null) {
      return {'error': 'Could not parse reminder'};
    }

    final String message = match.group(1)!.trim();
    int hour = int.parse(match.group(2)!);
    int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
    String? period = match.group(4)?.toLowerCase();

    if (period == 'pm' && hour < 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;

    return {'message': message, 'hour': hour, 'minute': minute};
  }

  // ---------------------------------------------------------------------------
  // Call
  // ---------------------------------------------------------------------------

  /// Parses call entities from [input].
  ///
  /// Recognised formats:
  /// - `call mom`
  /// - `call 9876543210`
  ///
  /// Returns key: `target`.
  /// On failure returns `{"error": "..."}`.
  Map<String, dynamic> extractCall(String input) {
    final normalized = TextNormalizer.normalize(input);

    // Strip the "call" prefix. If the input is just "call" with nothing after,
    // the replace won't remove anything, so we check against the original.
    final target = normalized.replaceFirst(RegExp(r'^call\s*'), '').trim();

    if (target.isEmpty || target == normalized) {
      return {'error': 'No contact or number provided'};
    }

    return {'target': target};
  }

  // ---------------------------------------------------------------------------
  // Open App
  // ---------------------------------------------------------------------------

  /// Parses open app entities from [input].
  ///
  /// Recognised formats:
  /// - `open calculator`
  /// - `open chrome`
  /// - `open youtube`
  ///
  /// Returns key: `app`.
  /// On failure returns `{"error": "..."}`.
  Map<String, dynamic> extractOpenApp(String input) {
    final normalized = TextNormalizer.normalize(input);

    // Strip the "open" prefix
    final app = normalized.replaceFirst(RegExp(r'^open\s+'), '').trim();

    if (app.isEmpty || app == normalized) {
      return {'error': 'No app name provided'};
    }

    return {'app': app};
  }

  // ---------------------------------------------------------------------------
  // SMS
  // ---------------------------------------------------------------------------

  /// Parses SMS entities from [input].
  ///
  /// Recognised formats:
  /// - `sms john hello`
  /// - `sms 1234567890 hi`
  ///
  /// Returns keys: `target`, `message`.
  /// On failure returns `{"error": "..."}`.
  Map<String, dynamic> extractSms(String input) {
    final normalized = TextNormalizer.normalize(input);

    // Strip the "sms" prefix
    final body = normalized.replaceFirst(RegExp(r'^sms\s+'), '').trim();
    if (body.isEmpty) {
      return {'error': 'No recipient or message provided'};
    }

    final parts = body.split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return {'error': 'No message provided'};
    }

    final target = parts.first;
    final message = parts.sublist(1).join(' ').trim();

    if (message.isEmpty) {
      return {'error': 'No message provided'};
    }

    return {'target': target, 'message': message};
  }

  // ---------------------------------------------------------------------------
  // System controls
  // ---------------------------------------------------------------------------

  /// Parses system control entities from [input].
  ///
  /// Supported controls:
  /// - `volume` (increase/decrease/mute/max)
  /// - `brightness` (increase/decrease)
  /// - `wifi` (on/off)
  /// - `mobile_data` (on/off)
  /// - `airplane_mode` (on/off)
  /// - `bluetooth` (on/off)
  Map<String, dynamic> extractSystem(String input) {
    final normalized = TextNormalizer.normalize(input);

    String? action;
    if (normalized.contains('increase') || normalized.contains('up')) {
      action = 'increase';
    } else if (normalized.contains('decrease') || normalized.contains('down')) {
      action = 'decrease';
    } else if (normalized.contains('turn on') || normalized.contains('enable')) {
      action = 'on';
    } else if (normalized.contains('turn off') || normalized.contains('disable')) {
      action = 'off';
    } else if (normalized.contains('mute')) {
      action = 'mute';
    } else if (normalized.contains('max')) {
      action = 'max';
    }

    if (normalized.contains('volume')) {
      return {'control': 'volume', 'action': action ?? 'increase'};
    }

    if (normalized.contains('brightness')) {
      return {'control': 'brightness', 'action': action ?? 'increase'};
    }

    if (normalized.contains('wi fi') || normalized.contains('wifi')) {
      return {'control': 'wifi', 'action': action ?? 'open'};
    }

    if (normalized.contains('mobile data')) {
      return {'control': 'mobile_data', 'action': action ?? 'open'};
    }

    if (normalized.contains('airplane mode')) {
      return {'control': 'airplane_mode', 'action': action ?? 'open'};
    }

    if (normalized.contains('bluetooth')) {
      return {'control': 'bluetooth', 'action': action ?? 'open'};
    }

    return {'error': 'Could not parse system command'};
  }
}

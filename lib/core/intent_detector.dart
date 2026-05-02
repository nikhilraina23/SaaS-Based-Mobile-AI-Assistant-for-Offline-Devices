import '../models/intent.dart';
import '../utils/text_normalizer.dart';

/// Detects the user's intent from a natural language command.
///
/// Supports multi-word triggers (e.g. "set alarm", "remind me") as well as
/// single-word prefixes for backward compatibility.
class IntentDetector {
  /// Ordered list of (pattern, intent) pairs. Longer / more specific patterns
  /// are checked first so that "set alarm" matches before a hypothetical "set".
  static final List<_Rule> _rules = [
    _Rule('set alarm', Intent.alarm),
    _Rule('set an alarm', Intent.alarm),
    _Rule('alarm', Intent.alarm),
    _Rule('remind me', Intent.reminder),
    _Rule('remind', Intent.reminder),
    _Rule('increase volume', Intent.system),
    _Rule('decrease volume', Intent.system),
    _Rule('volume up', Intent.system),
    _Rule('volume down', Intent.system),
    _Rule('mute volume', Intent.system),
    _Rule('max volume', Intent.system),
    _Rule('increase brightness', Intent.system),
    _Rule('decrease brightness', Intent.system),
    _Rule('brightness up', Intent.system),
    _Rule('brightness down', Intent.system),
    _Rule('turn on wifi', Intent.system),
    _Rule('turn off wifi', Intent.system),
    _Rule('turn on wi fi', Intent.system),
    _Rule('turn off wi fi', Intent.system),
    _Rule('turn on mobile data', Intent.system),
    _Rule('turn off mobile data', Intent.system),
    _Rule('turn on airplane mode', Intent.system),
    _Rule('turn off airplane mode', Intent.system),
    _Rule('turn on bluetooth', Intent.system),
    _Rule('turn off bluetooth', Intent.system),
    _Rule('wifi', Intent.system),
    _Rule('wi fi', Intent.system),
    _Rule('mobile data', Intent.system),
    _Rule('airplane mode', Intent.system),
    _Rule('bluetooth', Intent.system),
    _Rule('brightness', Intent.system),
    _Rule('volume', Intent.system),
    _Rule('send sms', Intent.sms),
    _Rule('sms', Intent.sms),
    _Rule('call', Intent.call),
    _Rule('open', Intent.openApp),
  ];

  /// Returns the detected [Intent] for the given [input].
  Intent detect(String input) {
    final normalized = TextNormalizer.normalize(input);

    for (final rule in _rules) {
      if (normalized.startsWith(rule.prefix)) {
        return rule.intent;
      }
    }

    return Intent.unknown;
  }
}

/// A simple prefix → intent mapping rule.
class _Rule {
  final String prefix;
  final Intent intent;
  const _Rule(this.prefix, this.intent);
}

import '../models/intent.dart';
import '../utils/text_normalizer.dart';
import 'intent_detector.dart';
import 'entity_extractor.dart';
import '../commands/base_command.dart';
import '../commands/alarm_command.dart';
import '../commands/reminder_command.dart';
import '../commands/call_command.dart';
import '../commands/open_app_command.dart';
import '../commands/sms_command.dart';
import '../commands/system_command.dart';

/// Central orchestrator that processes a raw user command through the
/// normalise → detect → extract → execute pipeline.
class CommandEngine {
  final IntentDetector _detector = IntentDetector();
  final EntityExtractor _extractor = EntityExtractor();

  /// Registry mapping each [Intent] to its [CommandHandler].
  final Map<Intent, CommandHandler> _handlers = {
    Intent.alarm: AlarmCommand(),
    Intent.reminder: ReminderCommand(),
    Intent.call: CallCommand(),
    Intent.openApp: OpenAppCommand(),
    Intent.sms: SmsCommand(),
    Intent.system: SystemCommand(),
  };

  /// Processes raw [input] and returns a human-readable response.
  Future<String> process(String input) async {
    final normalized = TextNormalizer.normalize(input);
    final intent = _detector.detect(normalized);

    // Extract entities based on intent type.
    final Map<String, dynamic> entities;
    switch (intent) {
      case Intent.alarm:
        entities = _extractor.extractAlarm(normalized);
        break;
      case Intent.reminder:
        entities = _extractor.extractReminder(normalized);
        break;
      case Intent.call:
        entities = _extractor.extractCall(normalized);
        break;
      case Intent.openApp:
        entities = _extractor.extractOpenApp(normalized);
        break;
      case Intent.sms:
        entities = _extractor.extractSms(normalized);
        break;
      case Intent.system:
        entities = _extractor.extractSystem(normalized);
        break;
      case Intent.unknown:
        return 'Unknown command';
    }

    // Delegate to the registered command handler.
    final handler = _handlers[intent];
    if (handler == null) {
      return 'No handler registered for $intent';
    }
    return handler.execute(entities);
  }
}

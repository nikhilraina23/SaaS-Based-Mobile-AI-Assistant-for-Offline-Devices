import 'base_command.dart';
import '../services/app_service.dart';

/// Handles reminder intent commands by opening a notes app.
class ReminderCommand extends CommandHandler {
  final AppService _service = AppService();

  @override
  Future<String> execute(Map<String, dynamic> entities) async {
    if (entities.containsKey('error')) {
      return entities['error'] as String;
    }

    final success = await _service.openApp('notes');
    if (success) {
      return 'Opening notes...';
    }
    return 'Failed to open notes app. Please check app availability.';
  }
}

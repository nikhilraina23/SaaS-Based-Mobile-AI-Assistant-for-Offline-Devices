import 'base_command.dart';
import '../services/app_service.dart';

/// Handles SMS intent commands by opening the messaging app.
class SmsCommand extends CommandHandler {
  final AppService _service = AppService();

  @override
  Future<String> execute(Map<String, dynamic> entities) async {
    if (entities.containsKey('error')) {
      return entities['error'] as String;
    }

    final success = await _service.openApp('messages');
    if (success) {
      return 'Opening messages...';
    }

    return 'Failed to open messages app. Please check app availability.';
  }
}

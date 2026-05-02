import 'base_command.dart';
import '../services/app_service.dart';

/// Handles alarm intent commands by opening the clock/alarm app.
class AlarmCommand extends CommandHandler {
  final AppService _service = AppService();

  @override
  Future<String> execute(Map<String, dynamic> entities) async {
    if (entities.containsKey('error')) {
      return entities['error'] as String;
    }

    final success = await _service.openApp('clock');
    if (success) {
      return 'Opening alarm...';
    }

    return 'Failed to open alarm app. Please check app availability.';
  }
}

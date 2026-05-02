import 'base_command.dart';
import '../services/app_service.dart';

/// Handles open app intent commands.
///
/// Expects entities with key: `app` (app name to open).
class OpenAppCommand extends CommandHandler {
  final AppService _service = AppService();

  @override
  Future<String> execute(Map<String, dynamic> entities) async {
    if (entities.containsKey('error')) {
      return entities['error'] as String;
    }

    final String app = entities['app'] as String;
    final success = await _service.openApp(app);

    if (success) {
      return 'Opening $app...';
    } else {
      return 'Failed to open $app. App not found or not installed.';
    }
  }
}

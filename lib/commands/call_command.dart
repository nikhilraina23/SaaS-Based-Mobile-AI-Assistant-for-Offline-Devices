import 'base_command.dart';
import '../services/phone_service.dart';

/// Handles call intent commands.
///
/// Expects entities with key: `target` (a contact name or phone number).
class CallCommand extends CommandHandler {
  final PhoneService _service = PhoneService();

  @override
  Future<String> execute(Map<String, dynamic> entities) async {
    if (entities.containsKey('error')) {
      return entities['error'] as String;
    }

    final String target = entities['target'] as String;
    final success = await _service.makeCall(target);
    if (success) {
      return 'Calling $target...';
    } else {
      return 'Failed to initiate call to $target. Please check permissions.';
    }
  }
}

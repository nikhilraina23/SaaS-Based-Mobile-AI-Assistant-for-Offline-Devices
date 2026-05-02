import 'base_command.dart';
import '../services/system_service.dart';

/// Handles system control commands (volume, brightness, connectivity settings).
class SystemCommand extends CommandHandler {
  final SystemService _service = SystemService();

  @override
  Future<String> execute(Map<String, dynamic> entities) async {
    if (entities.containsKey('error')) {
      return entities['error'] as String;
    }

    final String control = entities['control'] as String;
    final String action = entities['action'] as String;

    switch (control) {
      case 'volume':
        final success = await _service.adjustVolume(action);
        if (!success) return 'Failed to change volume.';
        if (action == 'mute') return 'Volume muted.';
        if (action == 'max') return 'Volume set to maximum.';
        return action == 'increase' ? 'Volume increased.' : 'Volume decreased.';

      case 'brightness':
        final result = await _service.adjustBrightness(action);
        if (result == BrightnessResult.changed) {
          return action == 'increase'
              ? 'Brightness increased.'
              : 'Brightness decreased.';
        }
        if (result == BrightnessResult.permissionRequired) {
          return 'Brightness permission required. Opened settings, please allow modify system settings.';
        }
        return 'Failed to change brightness.';

      case 'wifi':
        final success = await _service.openSystemPanel('wifi');
        if (success) {
          return 'Opened Wi-Fi panel. Android may require manual toggle for security.';
        }
        return 'Failed to open Wi-Fi settings.';

      case 'mobile_data':
        final success = await _service.openSystemPanel('mobile_data');
        if (success) {
          return 'Opened internet/mobile data panel. Android may require manual toggle.';
        }
        return 'Failed to open mobile data settings.';

      case 'airplane_mode':
        final success = await _service.openSystemPanel('airplane_mode');
        if (success) {
          return 'Opened airplane mode settings. Android requires manual toggle.';
        }
        return 'Failed to open airplane mode settings.';

      case 'bluetooth':
        final success = await _service.openSystemPanel('bluetooth');
        if (success) {
          return 'Opened Bluetooth settings. You can toggle it there.';
        }
        return 'Failed to open Bluetooth settings.';

      default:
        return 'Unsupported system control.';
    }
  }
}

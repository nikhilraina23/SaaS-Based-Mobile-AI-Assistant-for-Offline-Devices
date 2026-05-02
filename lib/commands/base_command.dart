/// Abstract interface for all command handlers.
///
/// Each intent type (alarm, reminder, call, etc.) has a concrete handler
/// that implements [execute] to perform the action and return a user-facing
/// response string.
abstract class CommandHandler {
  /// Executes the command using the provided [entities] extracted from user input.
  ///
  /// Returns a human-readable response describing what was done.
  Future<String> execute(Map<String, dynamic> entities);
}

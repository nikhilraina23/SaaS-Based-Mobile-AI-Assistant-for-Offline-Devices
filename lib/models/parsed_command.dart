import 'intent.dart';

class ParsedCommand {
  final Intent intent;
  final Map<String, dynamic> entities;

  ParsedCommand({required this.intent, required this.entities});
}

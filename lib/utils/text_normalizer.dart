/// Preprocesses raw user input before intent detection and entity extraction.
class TextNormalizer {
  /// Lowercases, trims, and collapses multiple spaces into one.
  static String normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_assist/utils/text_normalizer.dart';

void main() {
  group('TextNormalizer', () {
    test('converts to lowercase', () {
      expect(TextNormalizer.normalize('CALL MOM'), 'call mom');
    });

    test('trims leading and trailing whitespace', () {
      expect(TextNormalizer.normalize('  call mom  '), 'call mom');
    });

    test('collapses multiple spaces', () {
      expect(TextNormalizer.normalize('set   alarm    7'), 'set alarm 7');
    });

    test('handles mixed case, spaces, and tabs', () {
      expect(
        TextNormalizer.normalize('  Set  ALARM   7:00  AM  '),
        'set alarm 7:00 am',
      );
    });

    test('returns empty string for blank input', () {
      expect(TextNormalizer.normalize('   '), '');
    });
  });
}

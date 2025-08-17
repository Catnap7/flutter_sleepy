import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sleepy/utils/duration_formatter.dart';

void main() {
  group('DurationFormatter', () {
    test('formats zero as 00:00:00', () {
      expect(DurationFormatter.format(Duration.zero), '00:00:00');
    });

    test('formats hours, minutes, seconds', () {
      expect(
        DurationFormatter.format(const Duration(hours: 1, minutes: 23, seconds: 45)),
        '01:23:45',
      );
    });

    test('formats minutes only', () {
      expect(DurationFormatter.format(const Duration(minutes: 10)), '00:10:00');
    });

    test('formats long duration', () {
      expect(DurationFormatter.format(const Duration(hours: 27, minutes: 5, seconds: 9)), '27:05:09');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:safelog/validators.dart';

void main() {
  group('Title validation', () {
    test('empty title is rejected', () {
      expect(Validators.title(''), 'Please enter a title');
      expect(Validators.title('   '), 'Please enter a title');
      expect(Validators.title(null), 'Please enter a title');
    });

    test('short title is rejected', () {
      expect(Validators.title('ab'), 'Title must be at least 3 characters');
    });

    test('title over 60 characters is rejected', () {
      expect(Validators.title('a' * 61), isNotNull);
      expect(Validators.title('a' * 60), isNull);
    });

    test('script injection in title is rejected', () {
      expect(Validators.title('<script>alert(1)</script>'), isNotNull);
    });

    test('SQL injection in title is rejected', () {
      expect(Validators.title("x'; DROP TABLE incidents;--"), isNotNull);
    });

    test('normal title is accepted', () {
      expect(Validators.title('Phishing email to finance team'), isNull);
      expect(Validators.title("Lost laptop, O'Neil - room 3"), isNull);
    });
  });

  group('Description validation', () {
    test('empty description is allowed', () {
      expect(Validators.description(''), isNull);
    });

    test('description over 500 characters is rejected', () {
      expect(Validators.description('a' * 501), isNotNull);
    });

    test('HTML tags are rejected', () {
      expect(Validators.description('<img src=x onerror=alert(1)>'), isNotNull);
    });
  });

  group('Date validation', () {
    final now = DateTime(2026, 11, 19, 10, 0);

    test('future date is rejected', () {
      expect(Validators.date(DateTime(2026, 11, 20), now: now),
          'The date cannot be in the future');
    });

    test('today is accepted', () {
      expect(Validators.date(DateTime(2026, 11, 19, 23, 59), now: now), isNull);
    });

    test('past date is accepted', () {
      expect(Validators.date(DateTime(2026, 1, 1), now: now), isNull);
    });

    test('missing date is rejected', () {
      expect(Validators.date(null, now: now), isNotNull);
    });
  });

  group('Severity and status validation', () {
    test('only listed values are accepted', () {
      expect(Validators.severity('High'), isNull);
      expect(Validators.severity('Urgent'), isNotNull);
      expect(Validators.status('Closed'), isNull);
      expect(Validators.status('Pending'), isNotNull);
    });
  });
}

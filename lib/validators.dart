import 'models/incident.dart';

/// Input validation rules for SafeLog.
///
/// Every form field is checked here before anything is written to the
/// database. Each method returns an error message, or null when the
/// value is valid (the convention used by Flutter's TextFormField).
class Validators {
  Validators._();

  static const titleMin = 3;
  static const titleMax = 60;
  static const descriptionMax = 500;

  // Allow-list: letters, numbers, spaces and basic punctuation only.
  // Rejects <, >, ;, quotes used in SQL payloads, etc.
  static final _allowed = RegExp(r"^[a-zA-Z0-9 .,'-]+$");

  static String? title(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Please enter a title';
    if (value.length < titleMin) {
      return 'Title must be at least $titleMin characters';
    }
    if (value.length > titleMax) {
      return 'Title must be $titleMax characters or fewer';
    }
    if (!_allowed.hasMatch(value)) {
      return 'Only letters, numbers and basic punctuation are allowed';
    }
    return null;
  }

  static String? description(String? v) {
    final value = v?.trim() ?? '';
    if (value.length > descriptionMax) {
      return 'Description must be $descriptionMax characters or fewer';
    }
    if (value.contains('<') || value.contains('>')) {
      return 'The characters < and > are not allowed';
    }
    return null;
  }

  static String? severity(String? v) {
    if (v == null || !Incident.severities.contains(v)) {
      return 'Please choose a severity';
    }
    return null;
  }

  static String? status(String? v) {
    if (v == null || !Incident.statuses.contains(v)) {
      return 'Please choose a status';
    }
    return null;
  }

  /// [now] can be injected so the rule is testable.
  static String? date(DateTime? v, {DateTime? now}) {
    if (v == null) return 'Please choose a date';
    final today = _dayOnly(now ?? DateTime.now());
    if (_dayOnly(v).isAfter(today)) return 'The date cannot be in the future';
    return null;
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

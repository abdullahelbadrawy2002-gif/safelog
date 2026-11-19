/// A single security incident recorded in SafeLog.
class Incident {
  static const severities = ['Low', 'Medium', 'High', 'Critical'];
  static const statuses = ['Open', 'Closed'];

  final int? id;
  final String title;
  final String description;
  final String severity;
  final DateTime date;
  final String status;

  const Incident({
    this.id,
    required this.title,
    this.description = '',
    required this.severity,
    required this.date,
    this.status = 'Open',
  });

  Incident copyWith({
    int? id,
    String? title,
    String? description,
    String? severity,
    DateTime? date,
    String? status,
  }) {
    return Incident(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'severity': severity,
        // Stored as ISO-8601 (yyyy-MM-dd) so text sorting equals date sorting.
        'date': date.toIso8601String().substring(0, 10),
        'status': status,
      };

  static Incident fromMap(Map<String, Object?> map) => Incident(
        id: map['id'] as int?,
        title: map['title'] as String,
        description: (map['description'] as String?) ?? '',
        severity: map['severity'] as String,
        date: DateTime.parse(map['date'] as String),
        status: map['status'] as String,
      );
}

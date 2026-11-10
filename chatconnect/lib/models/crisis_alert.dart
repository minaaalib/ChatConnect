/// Where the crisis signal came from in Kai chat.
enum CrisisSource {
  /// kai-backend's hardcoded keyword filter. Hard signal: the student was
  /// shown the SOS overlay.
  keyword,

  /// Gemini's own is_crisis judgment. Softer signal.
  ai,
}

enum CrisisAlertStatus { newAlert, acknowledged, contacted, resolved }

extension CrisisAlertStatusX on CrisisAlertStatus {
  /// Value stored in the database (`new` is a Dart keyword, hence newAlert).
  String get dbValue => this == CrisisAlertStatus.newAlert ? 'new' : name;

  String get label => switch (this) {
    CrisisAlertStatus.newAlert => 'New',
    CrisisAlertStatus.acknowledged => 'Acknowledged',
    CrisisAlertStatus.contacted => 'Student contacted',
    CrisisAlertStatus.resolved => 'Resolved',
  };

  static CrisisAlertStatus fromDb(String value) => value == 'new'
      ? CrisisAlertStatus.newAlert
      : CrisisAlertStatus.values.byName(value);
}

class CrisisAlert {
  const CrisisAlert({
    required this.id,
    required this.studentId,
    required this.source,
    required this.status,
    required this.createdAt,
    this.excerpt,
    this.counselorNote,
  });

  final String id;
  final String studentId;
  final CrisisSource source;
  final CrisisAlertStatus status;
  final DateTime createdAt;

  /// The student's message that triggered the alert (trimmed).
  final String? excerpt;
  final String? counselorNote;

  bool get isOpen => status != CrisisAlertStatus.resolved;

  factory CrisisAlert.fromRow(Map<String, dynamic> row) {
    return CrisisAlert(
      id: row['id'] as String,
      studentId: row['student_id'] as String,
      source: CrisisSource.values.byName(row['source'] as String),
      status: CrisisAlertStatusX.fromDb(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      excerpt: row['excerpt'] as String?,
      counselorNote: row['counselor_note'] as String?,
    );
  }
}

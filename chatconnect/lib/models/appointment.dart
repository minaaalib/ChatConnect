enum AppointmentType { academic, personal, crisis }

enum AppointmentStatus { pending, confirmed, declined }

extension AppointmentTypeLabel on AppointmentType {
  String get label => switch (this) {
    AppointmentType.academic => 'Academic',
    AppointmentType.personal => 'Personal',
    AppointmentType.crisis => 'Crisis',
  };
}

class Appointment {
  const Appointment({
    required this.id,
    required this.userId,
    required this.type,
    required this.subject,
    required this.preferredDate,
    required this.createdAt,
    this.description,
    this.status = AppointmentStatus.pending,
    this.calendarEventLink,
    this.meetLink,
    this.counselorNote,
  });

  final String id;

  /// The student who requested it.
  final String userId;
  final AppointmentType type;
  final String subject;
  final DateTime preferredDate;
  final DateTime createdAt;
  final String? description;
  final AppointmentStatus status;

  /// Set by the counselor app when the appointment is confirmed: the event
  /// on the counselor's Google Calendar and its Meet link.
  final String? calendarEventLink;
  final String? meetLink;

  /// Optional message from the counselor when confirming or declining.
  final String? counselorNote;

  factory Appointment.fromRow(Map<String, dynamic> row) {
    return Appointment(
      id: row['id'] as String,
      userId: row['student_id'] as String,
      type: AppointmentType.values.byName(row['type'] as String),
      subject: row['subject'] as String,
      description: row['description'] as String?,
      preferredDate: DateTime.parse(row['preferred_at'] as String).toLocal(),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      status: AppointmentStatus.values.byName(row['status'] as String),
      calendarEventLink: row['calendar_event_link'] as String?,
      meetLink: row['meet_link'] as String?,
      counselorNote: row['counselor_note'] as String?,
    );
  }

  Appointment copyWith({
    AppointmentStatus? status,
    String? counselorNote,
    String? meetLink,
    String? calendarEventLink,
  }) {
    return Appointment(
      id: id,
      userId: userId,
      type: type,
      subject: subject,
      preferredDate: preferredDate,
      createdAt: createdAt,
      description: description,
      status: status ?? this.status,
      calendarEventLink: calendarEventLink ?? this.calendarEventLink,
      meetLink: meetLink ?? this.meetLink,
      counselorNote: counselorNote ?? this.counselorNote,
    );
  }
}

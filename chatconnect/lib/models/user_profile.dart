enum UserRole { student, counselor }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.studentId,
    required this.course,
    required this.email,
    this.avatarUrl,
    this.kaiCompanionActive = true,
    this.role = UserRole.student,
  });

  final String id;
  final String fullName;
  final String studentId;
  final String course;
  final String email;
  final String? avatarUrl;
  final bool kaiCompanionActive;
  final UserRole role;

  bool get isCounselor => role == UserRole.counselor;

  /// Builds a profile from a row of the Supabase `profiles` table.
  factory UserProfile.fromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      fullName: (row['full_name'] as String?) ?? '',
      studentId: (row['student_id'] as String?) ?? '',
      course: (row['course'] as String?) ?? '',
      email: (row['email'] as String?) ?? '',
      role: row['role'] == 'counselor' ? UserRole.counselor : UserRole.student,
    );
  }

  UserProfile copyWith({bool? kaiCompanionActive}) {
    return UserProfile(
      id: id,
      fullName: fullName,
      studentId: studentId,
      course: course,
      email: email,
      avatarUrl: avatarUrl,
      kaiCompanionActive: kaiCompanionActive ?? this.kaiCompanionActive,
      role: role,
    );
  }
}

import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

abstract class AuthService extends ChangeNotifier {
  UserProfile? get currentUser;
  bool get isSignedIn => currentUser != null;

  Future<void> signIn({required String identifier, required String password});

  Future<void> signUp({
    required String fullName,
    required String studentId,
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Turns the Kai companion on or off for the signed-in user.
  void toggleKaiCompanion(bool active);

  /// A counselor who passed email + password but hasn't entered their staff
  /// school ID yet (second sign-in step). [currentUser] stays null until then.
  /// Always null in the student app.
  UserProfile? get pendingStaffIdUser => null;
  bool get awaitingStaffId => pendingStaffIdUser != null;

  /// Second sign-in step for counselors. Throws with a readable message
  /// when the staff ID is wrong or entry is locked.
  Future<void> verifyStaffId(String staffId) async => throw UnsupportedError(
    'Staff ID check is only used in the counselor app.',
  );
}

/// Shown when someone signs in to the app meant for the other role.
String wrongAppMessage(UserRole appRole) => appRole == UserRole.counselor
    ? 'This app is for Guidance Office staff only. Students, please use the '
          'ChatConnect mobile app.'
    : 'Counselor accounts sign in through the ChatConnect Guidance Office '
          'web app.';

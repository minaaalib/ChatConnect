import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import 'auth_service.dart';

/// Real sign-in backed by Supabase Auth plus the `profiles` table (which
/// holds the student/counselor role — see supabase/migrations/).
///
/// Each app accepts one role only: the student app ([UserRole.student]) and
/// the Guidance Office web app ([UserRole.counselor]). Signing in with the
/// other kind of account is refused.
class SupabaseAuthService extends AuthService {
  SupabaseAuthService(this._client, {required this.appRole}) {
    _sub = _client.auth.onAuthStateChange.listen(
      (state) => _syncSession(state.session),
    );
    // Restores a session saved from a previous launch.
    _syncSession(_client.auth.currentSession);
  }

  final SupabaseClient _client;
  final UserRole appRole;
  late final StreamSubscription<AuthState> _sub;
  UserProfile? _currentUser;
  UserProfile? _pendingIdUser;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  UserProfile? get pendingStaffIdUser => _pendingIdUser;

  Future<void> _syncSession(Session? session) async {
    if (session == null) {
      if (_currentUser != null || _pendingIdUser != null) {
        _currentUser = null;
        _pendingIdUser = null;
        notifyListeners();
      }
      return;
    }
    if (_currentUser?.id == session.user.id ||
        _pendingIdUser?.id == session.user.id) {
      return;
    }
    try {
      final profile = await _loadProfile(session.user.id);
      if (profile.role != appRole) {
        // A saved session for the wrong kind of account: drop it.
        await _client.auth.signOut();
        _currentUser = null;
      } else if (appRole == UserRole.counselor) {
        // A reload keeps the session; only ask for the staff ID again if this
        // session hasn't passed it yet.
        final verified = await _client.rpc('staff_id_verified') == true;
        _currentUser = verified ? profile : null;
        _pendingIdUser = verified ? null : profile;
      } else {
        _currentUser = profile;
      }
    } catch (_) {
      // Signed in but no readable profile row (e.g. the migration wasn't
      // run): treat as signed out rather than half-signed-in.
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<UserProfile> _loadProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromRow(row);
  }

  @override
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    final email = identifier.trim();
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Please enter your email and password.');
    }
    if (!email.contains('@')) {
      throw Exception('Please sign in with your WVSU email address.');
    }
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw Exception('Sign-in failed. Please try again.');
      final profile = await _loadProfile(user.id);
      if (profile.role != appRole) {
        await _client.auth.signOut();
        throw Exception(wrongAppMessage(appRole));
      }
      if (appRole == UserRole.counselor) {
        // Step 2: the staff school ID screen (see verifyStaffId).
        _currentUser = null;
        _pendingIdUser = profile;
      } else {
        _currentUser = profile;
      }
      notifyListeners();
    } on AuthException catch (e) {
      throw Exception(_friendly(e));
    } on PostgrestException {
      await _client.auth.signOut();
      throw Exception(
        "Your account exists but has no profile yet. Ask the Guidance "
        'Office to finish setting it up.',
      );
    }
  }

  @override
  Future<void> signUp({
    required String fullName,
    required String studentId,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        // Read by the handle_new_user trigger. Role is never taken from here.
        data: {'full_name': fullName.trim(), 'student_id': studentId.trim()},
      );
      if (res.session == null) {
        throw Exception(
          'Account created. Check your email to confirm it, then log in.',
        );
      }
      final profile = await _loadProfile(res.user!.id);
      if (profile.role != appRole) {
        await _client.auth.signOut();
        throw Exception(wrongAppMessage(appRole));
      }
      _currentUser = profile;
      notifyListeners();
    } on AuthException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  @override
  Future<void> verifyStaffId(String staffId) async {
    final pending = _pendingIdUser;
    if (pending == null) throw Exception('Please sign in again.');
    final String result;
    try {
      result =
          await _client.rpc(
                'verify_staff_id',
                params: {'p_staff_id': staffId.trim()},
              )
              as String;
    } on PostgrestException {
      throw Exception('Could not check your staff ID. Please try again.');
    }
    switch (result) {
      case 'ok':
        _currentUser = pending;
        _pendingIdUser = null;
        notifyListeners();
      case 'wrong':
        throw Exception('Staff school ID does not match. Please try again.');
      case 'locked':
        throw Exception(
          'Too many wrong tries. Verification is locked for 15 minutes.',
        );
      case 'no_id':
        throw Exception(
          'No staff school ID is on file for this account yet. Ask the '
          'system administrator to add it.',
        );
      default:
        throw Exception('Please sign in again.');
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _currentUser = null;
    _pendingIdUser = null;
    notifyListeners();
  }

  /// Kept on-device only for now (no column for it yet).
  @override
  void toggleKaiCompanion(bool active) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(kaiCompanionActive: active);
    notifyListeners();
  }

  String _friendly(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login')) return 'Wrong email or password.';
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email first, then log in.';
    }
    return e.message;
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

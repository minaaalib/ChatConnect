import '../models/user_profile.dart';
import 'auth_service.dart';
import 'demo/demo_store.dart';

/// Offline sign-in used when Supabase isn't configured. Any email/password
/// works. In the student app ([UserRole.student]) you become a sample
/// student; in the Guidance Office app ([UserRole.counselor]) you become the
/// sample counselor from [DemoStore].
class MockAuthService extends AuthService {
  MockAuthService({DemoStore? demoStore, this.appRole = UserRole.student})
    : _store = demoStore;

  /// Staff school ID for the sample counselor in offline demo mode.
  static const demoStaffSchoolId = '001325';

  final DemoStore? _store;
  final UserRole appRole;
  UserProfile? _pendingIdUser;
  int _wrongIds = 0;
  DateTime? _idLockedUntil;

  @override
  UserProfile? get pendingStaffIdUser => _pendingIdUser;
  UserProfile? _currentUser;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final id = identifier.trim().toLowerCase();
    if (id.isEmpty || password.trim().isEmpty) {
      throw Exception('Please enter your student ID/email and password.');
    }
    if (appRole == UserRole.counselor) {
      final store = _store;
      if (store == null) throw Exception('Demo data is not available.');
      _pendingIdUser = store.counselor; // step 2: staff school ID
      notifyListeners();
      return;
    }
    _setStudent(
      UserProfile(
        id: 'mock-user-1',
        fullName: 'User',
        studentId: '2025-12345',
        course: 'BS Information Technology',
        email: identifier.contains('@')
            ? identifier.trim()
            : '${identifier.trim()}@wvsu.edu.ph',
      ),
    );
  }

  @override
  Future<void> signUp({
    required String fullName,
    required String studentId,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _setStudent(
      UserProfile(
        id: 'mock-user-1',
        fullName: fullName,
        studentId: studentId,
        course: 'BS Information Technology',
        email: email,
      ),
    );
  }

  void _setStudent(UserProfile profile) {
    _currentUser = profile;
    // So the demo counselor sees this student's name on alerts/requests.
    _store?.upsertProfile(profile);
    notifyListeners();
  }

  @override
  Future<void> verifyStaffId(String staffId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final pending = _pendingIdUser;
    if (pending == null) throw Exception('Please sign in again.');
    final lockedUntil = _idLockedUntil;
    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
      throw Exception(
        'Too many wrong tries. Verification is locked for 15 minutes.',
      );
    }
    if (staffId.trim().toUpperCase() != demoStaffSchoolId) {
      _wrongIds += 1;
      if (_wrongIds >= 5) {
        _wrongIds = 0;
        _idLockedUntil = DateTime.now().add(const Duration(minutes: 15));
        throw Exception(
          'Too many wrong tries. Verification is locked for 15 minutes.',
        );
      }
      throw Exception('Staff school ID does not match. Please try again.');
    }
    _wrongIds = 0;
    _currentUser = pending;
    _pendingIdUser = null;
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _pendingIdUser = null;
    notifyListeners();
  }

  @override
  void toggleKaiCompanion(bool active) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(kaiCompanionActive: active);
    notifyListeners();
  }
}

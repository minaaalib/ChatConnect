/// Central place for every phone number shown on crisis/SOS UI.
///
/// TODO(product): these are placeholders. Replace with WVSU Guidance
/// Office's actual verified numbers (campus security, on-call counselor,
/// and the nearest partnered psychiatric hospital/ER) before this reaches
/// real students. Do not guess a real hospital's number here — a wrong
/// number on a crisis screen is worse than an honest "not configured yet".
class CrisisContact {
  const CrisisContact({required this.label, required this.phone});

  final String label;

  /// Digits/+/- only, or null if not configured yet. [SosOverlay] disables
  /// the call button instead of launching a broken `tel:` link when null.
  final String? phone;
}

class CrisisContacts {
  CrisisContacts._();

  static const guidanceOffice = CrisisContact(
    label: 'WVSU Guidance Office',
    phone: null, // TODO: verified crisis line number
  );

  static const campusSecurity = CrisisContact(
    label: 'Campus Security',
    phone: null, // TODO: verified number
  );

  static const psychiatricEmergency = CrisisContact(
    label: 'Psychiatric Emergency / Nearest ER',
    phone: null, // TODO: verified partnered hospital number
  );

  static const all = [guidanceOffice, campusSecurity, psychiatricEmergency];
}

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads the Supabase project settings from `.env`. While they're empty the
/// app runs fully offline on mock services (no counselor side).
class BackendConfig {
  BackendConfig._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL']?.trim() ?? '';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

  static bool get supabaseEnabled =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// OAuth web client ID for Google Meet in the counselor web app. Empty =
  /// demo Meet links. See docs/GOOGLE_MEET_SETUP.md.
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';
}

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Future<bool> isUserAdmin(String? userId) async {
    if (userId == null) return false;

    try {
      final user =
          await _supabase.from('users').select().eq('id', userId).single();

      return user['is_tester'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    return isUserAdmin(_supabase.auth.currentSession?.user.id);
  }

  Session? get currentSession => _supabase.auth.currentSession;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

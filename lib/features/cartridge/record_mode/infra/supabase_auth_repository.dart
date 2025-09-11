import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../domain/repositories/auth_repository.dart';

/// Supabase 구현체
/// - 현 스키마: users.email = 표시용 닉네임
class SupabaseAuthRepository implements AuthRepository {
  final supabase.SupabaseClient _sp;
  SupabaseAuthRepository(this._sp);

  @override
  Future<({String? displayName, bool isAdmin})?> fetchProfile(String uid) async {
    final row = await _sp
        .from('users')
        .select('id,email,is_tester')
        .eq('id', uid)
        .maybeSingle();

    if (row == null) return null;
    final display = row['email']?.toString();
    final isAdmin = (row['is_tester'] ?? false) == true;
    return (displayName: display, isAdmin: isAdmin);
  }

  @override
  Future<void> upsertDisplayName({
    required String uid,
    required String displayName,
  }) async {
    await _sp.from('users').upsert({'id': uid, 'email': displayName});
  }
}

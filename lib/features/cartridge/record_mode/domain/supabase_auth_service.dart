import 'dart:async';
import 'package:cartridge/core/log.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'models/auth_user.dart';
import 'interfaces.dart';
import 'repositories/auth_repository.dart';

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._sp, this._repo) {
    final u = _sp.auth.currentUser;
    if (u != null) {
      _hydrate(u.id).then((_) => _profileEvents.add(null));
    }
  }

  static const _tag = 'SupabaseAuthService';

  final supabase.SupabaseClient _sp;
  final AuthRepository _repo;

  AuthUser? _cached;
  final _profileEvents = StreamController<void>.broadcast();

  Future<void> _hydrate(String uid) async {
    try {
      final row = await _repo.fetchProfile(uid);
      final display = (row?.displayName ?? '').trim();
      final emailLocal = _sp.auth.currentUser?.email?.split('@').first;
      final nickname = display.isNotEmpty ? display : (emailLocal ?? 'Unknown');
      final isAdmin = row?.isAdmin ?? false;

      _cached = AuthUser(uid: uid, nickname: nickname, isAdmin: isAdmin);
      logI(_tag, 'hydrate ok | nickname=${_cached!.nickname}, isAdmin=$isAdmin');
    } catch (e, st) {
      final emailLocal = _sp.auth.currentUser?.email?.split('@').first ?? 'Unknown';
      _cached = AuthUser(uid: uid, nickname: emailLocal, isAdmin: false);
      logW(_tag, 'hydrate failed, fallback(email-local). $e');
      logE(_tag, 'hydrate stack', e, st);
    }
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return Stream<AuthUser?>.multi((controller) {
      logI(_tag, 'authStateChanges: subscribed');
      controller.add(_cached);

      final sub1 = _sp.auth.onAuthStateChange.listen((ev) async {
        final uid = ev.session?.user.id;
        logI(_tag, 'onAuthStateChange | event=${ev.event.name}');
        if (uid == null) {
          _cached = null;
          controller.add(null);
        } else {
          await _hydrate(uid);
          controller.add(_cached);
        }
      });

      final sub2 = _profileEvents.stream.listen((_) => controller.add(_cached));

      controller.onCancel = () async {
        logI(_tag, 'authStateChanges: unsubscribed');
        await sub1.cancel();
        await sub2.cancel();
      };
    });
  }

  @override
  AuthUser? get currentUser => _cached;

  @override
  Future<void> signInWithPassword(String email, String password) async {
    logI(_tag, 'signIn start | email=$email');
    try {
      final dynamic fut =
          _sp.auth.signInWithPassword(email: email, password: password);
      if (fut is Future) {
        await fut;
      } else {
        logW(_tag,
            'GoTrue.signInWithPassword returned null/non-Future (mock?). Skipping await.');
      }
    } catch (e, st) {
      logE(_tag, 'signIn failed', e, st);
      rethrow;
    }
  }

  @override
  Future<void> signUpWithPassword(String email, String password) async {
    logI(_tag, 'signUp start | email=$email');

    // 1) 회원가입 시도
    final res = await _sp.auth.signUp(email: email, password: password);
    final hasSession = res.session != null;
    final hasUser = _sp.auth.currentUser != null;

    // 2) 세션도 없고 currentUser도 없으면(둘 다 없을 때만) 폴백 로그인 시도
    if (!hasSession && !hasUser) {
      try {
        logI(_tag, 'signUp done. session missing → signIn fallback | email=$email');
        await signInWithPassword(email, password);
      } catch (e, st) {
        logE(_tag, 'auto signIn after signUp failed', e, st);
        rethrow; // UI에서 안내 다이얼로그를 띄울 수 있도록 그대로 던짐
      }
    }
  }

  @override
  Future<void> signOut() async {
    logI(_tag, 'signOut start');
    await _sp.auth.signOut();
  }

  @override
  Future<void> changeNickname(String nickname) async {
    final uid = _sp.auth.currentUser?.id;
    if (uid == null) {
      logW(_tag, 'changeNickname ignored: no current user');
      return;
    }
    logI(_tag, 'changeNickname | nickname="$nickname"');
    await _repo.upsertDisplayName(uid: uid, displayName: nickname);
    await _hydrate(uid);
    _profileEvents.add(null);
  }

  void dispose() {
    _profileEvents.close();
  }
}

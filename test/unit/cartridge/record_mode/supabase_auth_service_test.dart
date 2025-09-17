// test/unit/cartridge/record_mode/supabase_auth_service_test.dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;

import 'package:cartridge/features/cartridge/record_mode/domain/models/auth_user.dart';
import 'package:cartridge/features/cartridge/record_mode/domain/repositories/auth_repository.dart';
import 'package:cartridge/features/cartridge/record_mode/domain/supabase_auth_service.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────
class _MockSupabaseClient extends Mock implements sp.SupabaseClient {}
class _MockGoTrueClient extends Mock implements sp.GoTrueClient {}
class _MockAuthRepository extends Mock implements AuthRepository {}

// ── Test helpers (nullable 반환으로 변경된 버전) ───────────────────────────────
sp.User? _mkUser({required String id, required String email}) {
  return sp.User.fromJson({
    'id': id,
    'email': email,
    'aud': 'authenticated',
    'role': 'authenticated',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-01-01T00:00:00Z',
    'identities': <Map<String, dynamic>>[],
  });
}

sp.Session? _mkSession(sp.User user) {
  return sp.Session.fromJson({
    'access_token': 'test-token',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    'user': user.toJson(),
  });
}

sp.AuthResponse _mkAuthResp({sp.Session? session, sp.User? user}) {
  return sp.AuthResponse(session: session, user: user);
}

void main() {
  group('SupabaseAuthService', () {
    late _MockSupabaseClient spClient;
    late _MockGoTrueClient auth;
    late _MockAuthRepository repo;
    late StreamController<sp.AuthState> authEvents;

    setUp(() {
      spClient = _MockSupabaseClient();
      auth = _MockGoTrueClient();
      repo = _MockAuthRepository();
      authEvents = StreamController<sp.AuthState>.broadcast();

      when(() => spClient.auth).thenReturn(auth);
      when(() => auth.onAuthStateChange).thenAnswer((_) => authEvents.stream);

      when(() => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => _mkAuthResp());

      when(() => auth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => _mkAuthResp(session: null, user: null));
    });

    tearDown(() async {
      await authEvents.close();
    });

    test('초기 hydrate: currentUser가 있으면 null → hydrated 순서로 발행', () async {
      final u = _mkUser(id: 'u-1', email: 'alice@example.com')!; // ← non-null 단언
      when(() => auth.currentUser).thenReturn(u);

      when(() => repo.fetchProfile('u-1'))
          .thenAnswer((_) async => (displayName: 'Alice', isAdmin: true));

      final svc = SupabaseAuthService(spClient, repo);

      final emissions = <AuthUser?>[];
      final sub = svc.authStateChanges().listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.first, isNull);
      final last = emissions.last!;
      expect(last.uid, 'u-1');
      expect(last.nickname, 'Alice');
      expect(last.isAdmin, isTrue);

      await sub.cancel();
      svc.dispose();
    });

    test('초기 hydrate: displayName 비어있으면 email local-part로 대체', () async {
      final u = _mkUser(id: 'u-2', email: 'bob@domain.dev')!;
      when(() => auth.currentUser).thenReturn(u);

      when(() => repo.fetchProfile('u-2'))
          .thenAnswer((_) async => (displayName: '   ', isAdmin: false));

      final svc = SupabaseAuthService(spClient, repo);

      final out = await svc.authStateChanges().skip(1).firstWhere((e) => e != null);
      expect(out!.nickname, 'bob');
      expect(out.isAdmin, isFalse);

      svc.dispose();
    });

    test('authStateChanges: onAuthStateChange(signedIn/out) 이벤트에 반응', () async {
      when(() => auth.currentUser).thenReturn(null);

      final u = _mkUser(id: 'u-3', email: 'carol@example.com')!;
      when(() => repo.fetchProfile('u-3'))
          .thenAnswer((_) async => (displayName: 'Carol', isAdmin: false));

      final svc = SupabaseAuthService(spClient, repo);
      final received = <AuthUser?>[];
      final sub = svc.authStateChanges().listen(received.add);

      // signedIn
      final sess = _mkSession(u)!;
      authEvents.add(sp.AuthState(sp.AuthChangeEvent.signedIn, sess));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(received.last, isA<AuthUser>());
      expect(received.last!.uid, 'u-3');
      expect(received.last!.nickname, 'Carol');

      // signedOut
      authEvents.add(sp.AuthState(sp.AuthChangeEvent.signedOut, null));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(received.last, isNull);

      await sub.cancel();
      svc.dispose();
    });

    test('changeNickname(): repo.upsertDisplayName 호출 후 재-hydrate 및 emit', () async {
      final u = _mkUser(id: 'u-4', email: 'dave@example.com')!;
      when(() => auth.currentUser).thenReturn(u);
      when(() => repo.fetchProfile('u-4'))
          .thenAnswer((_) async => (displayName: 'Dave', isAdmin: false));

      final svc = SupabaseAuthService(spClient, repo);
      await svc.authStateChanges().take(2).last; // 초기 null→hydrate 소비

      when(() => repo.upsertDisplayName(uid: 'u-4', displayName: 'NewNick'))
          .thenAnswer((_) async {});
      when(() => repo.fetchProfile('u-4'))
          .thenAnswer((_) async => (displayName: 'NewNick', isAdmin: false));

      final nextF = svc.authStateChanges()
          .where((u) => u?.nickname == 'NewNick')
          .first;
      await svc.changeNickname('NewNick');
      final after = await nextF;

      verify(() => repo.upsertDisplayName(uid: 'u-4', displayName: 'NewNick')).called(1);
      expect(after!.nickname, 'NewNick');

      svc.dispose();
    });

    test('signInWithPassword(): GoTrueClient로 위임', () async {
      when(() => auth.signInWithPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => _mkAuthResp());

      final svc = SupabaseAuthService(spClient, repo);
      await svc.signInWithPassword('x@y.z', 'pw1234');

      verify(() => auth.signInWithPassword(email: 'x@y.z', password: 'pw1234')).called(1);
      svc.dispose();
    });

    test('signUpWithPassword(): session 없으면 signIn fallback 호출', () async {
      when(() => auth.currentUser).thenReturn(null);

      when(() => auth.signUp(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => _mkAuthResp(session: null, user: null));

      when(() => auth.signInWithPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => _mkAuthResp());

      final svc = SupabaseAuthService(spClient, repo);
      await svc.signUpWithPassword('foo@bar.com', 'pw');

      verify(() => auth.signUp(email: 'foo@bar.com', password: 'pw')).called(1);
      verify(() => auth.signInWithPassword(email: 'foo@bar.com', password: 'pw')).called(1);
      svc.dispose();
    });

    test('signUpWithPassword(): session 있으면 fallback 로그인 호출 안 함', () async {
      when(() => auth.currentUser).thenReturn(null);

      final u = _mkUser(id: 'u-5', email: 'eve@site.tld')!;
      final sess = _mkSession(u)!;
      when(() => auth.signUp(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => _mkAuthResp(session: sess, user: u));

      final svc = SupabaseAuthService(spClient, repo);
      await svc.signUpWithPassword('eve@site.tld', 'pw');

      verify(() => auth.signUp(email: 'eve@site.tld', password: 'pw')).called(1);
      verifyNever(() => auth.signInWithPassword(email: any(named: 'email'), password: any(named: 'password')));
      svc.dispose();
    });

    test('signOut(): GoTrueClient로 위임', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});
      final svc = SupabaseAuthService(spClient, repo);

      await svc.signOut();
      verify(() => auth.signOut()).called(1);
      svc.dispose();
    });
  });
}

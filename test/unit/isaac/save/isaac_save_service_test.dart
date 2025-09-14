import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cartridge/features/isaac/save/application/isaac_save_service.dart';
import 'package:cartridge/features/steam/domain/steam_users_port.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';

class _MockUsersPort extends Mock implements SteamUsersPort {}
class _FakeProfile extends Fake implements SteamAccountProfile {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeProfile());
  });

  group('IsaacSaveService', () {
    test('포트가 0개 반환 시 빈 리스트를 그대로 반환한다 (AAA)', () async {
      // Arrange
      final port = _MockUsersPort();
      when(() => port.findAccountsWithIsaacSaves()).thenAnswer((_) async => <SteamAccountProfile>[]);
      final sut = IsaacSaveService(users: port);

      // Act
      final r = await sut.findSaveCandidates();

      // Assert
      expect(r, isEmpty);
      verify(() => port.findAccountsWithIsaacSaves()).called(1);
    });

    test('포트가 2개 반환 시 동일 2개를 그대로 반환한다 (AAA)', () async {
      // Arrange
      final port = _MockUsersPort();
      final p1 = _FakeProfile();
      final p2 = _FakeProfile();
      when(() => port.findAccountsWithIsaacSaves()).thenAnswer((_) async => [p1, p2]);
      final sut = IsaacSaveService(users: port);

      // Act
      final r = await sut.findSaveCandidates();

      // Assert
      expect(r, hasLength(2));
      expect(r.first, same(p1));
      expect(r.last, same(p2));
      verify(() => port.findAccountsWithIsaacSaves()).called(1);
    });

    test('포트가 예외를 던지면 rethrow 한다 (AAA)', () async {
      // Arrange
      final port = _MockUsersPort();
      when(() => port.findAccountsWithIsaacSaves()).thenThrow(StateError('boom'));
      final sut = IsaacSaveService(users: port);

      // Act & Assert
      expect(() => sut.findSaveCandidates(), throwsA(isA<StateError>()));
      verify(() => port.findAccountsWithIsaacSaves()).called(1);
    });
  });
}

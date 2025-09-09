import 'package:flutter_test/flutter_test.dart';
import 'package:cartridge/features/steam/domain/steam_link_builder.dart';

void main() {
  group('SteamLinkBuilder — Unit', () {
    test('스팀 도메인은 steam://openurl 로 감싼다 (AAA)', () {
      // Arrange
      const url = 'https://store.steampowered.com/app/250900/';

      // Act
      final result = SteamLinkBuilder.preferSteamClientIfPossible(url);

      // Assert
      expect(result, 'steam://openurl/$url');
    });

    test('화이트리스트 외 URL은 원본 유지 (AAA)', () {
      // Arrange
      const url = 'https://example.com/anything?q=1';

      // Act
      final result = SteamLinkBuilder.preferSteamClientIfPossible(url);

      // Assert
      expect(result, url);
    });

    test('잘못된 URL 입력 시 원본 유지 (AAA)', () {
      // Arrange
      const url = '::not a url::';

      // Act
      final result = SteamLinkBuilder.preferSteamClientIfPossible(url);

      // Assert
      expect(result, url);
    });
  });
}

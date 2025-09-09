import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';

abstract class SteamUsersPort {
  /// Isaac(250900) 세이브가 존재하는 계정만 반환
  Future<List<SteamAccountProfile>> findAccountsWithIsaacSaves();
}

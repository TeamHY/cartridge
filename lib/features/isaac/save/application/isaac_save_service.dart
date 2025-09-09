import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/steam/domain/steam_users_port.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';

class IsaacSaveService {
  static const _tag = 'IsaacSaveService';
  final SteamUsersPort users;
  const IsaacSaveService({required this.users});

  Future<List<SteamAccountProfile>> findSaveCandidates() async {
    const op = 'findCandidates';
    logI(_tag, 'op=$op fn=findSaveCandidates msg=start');
    try {
      final r = await users.findAccountsWithIsaacSaves();
      logI(_tag, 'op=$op fn=findSaveCandidates msg=done count=${r.length}');
      return r;
    } catch (e, st) {
      logE(_tag, 'op=$op fn=findSaveCandidates msg=failed', e, st);
      rethrow;
    }
  }
}

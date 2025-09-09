import 'dart:io';
import 'dart:typed_data';
import 'package:cartridge/features/isaac/save/domain/ports/eden_tokens_port.dart';
import 'package:path/path.dart' as p;
import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/isaac/save/infra/isaac_save_codec.dart';
import 'package:cartridge/features/isaac/save/infra/isaac_save_file_namer.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';


class IsaacEdenFileAdapter implements EdenTokensPort {
  static const _tag = 'IsaacEdenFileAdapter';
  final IsaacSaveCodec codec;
  IsaacEdenFileAdapter({required this.codec});

  File? _resolveFile(SteamAccountProfile acc, IsaacEdition e, int slot) {
    final name = IsaacSaveFileNamer.fileName(e, slot);
    final f = File(p.join(acc.savePath, name));
    return f.existsSync() ? f : null;
  }

  @override
  Future<int> read(SteamAccountProfile acc, IsaacEdition e, int slot) async {
    final f = _resolveFile(acc, e, slot);
    if (f == null) {
      throw StateError('Save not found: $e slot:$slot under ${acc.savePath}');
    }
    final bytes = await f.readAsBytes();
    final eden = codec.readEdenTokens(Uint8List.fromList(bytes));
    logI(_tag, 'read eden=$eden ($e:$slot) file=${f.path}');
    return eden;
  }

  @override
  Future<void> write(
      SteamAccountProfile acc,
      IsaacEdition e,
      int slot,
      int value, {
        bool makeBackup = true,
        SaveWriteMode mode = SaveWriteMode.atomicRename,
      }) async {
    final f = _resolveFile(acc, e, slot);
    if (f == null) throw StateError('Save not found: $e slot:$slot');

    // 음수 방지(게임 카운터 의미상)
    if (value < 0) value = 0;

    final original = await f.readAsBytes();
    final data = Uint8List.fromList(original);

    // 1) 값 쓰기 (codec 내부에서 32-bit LE로 기록)
    final modified = codec.writeEdenTokens(data, value);

    // 2) 체크섬 (Rebirth 제외, AB/AB+/Rep/Rep+만)
    final finalized = (e == IsaacEdition.rebirth)
        ? modified
        : codec.updateChecksumAfterbirthFamily(modified);

    // 3) 길이 보존(파일 길이 변화는 무결성 실패의 흔한 원인)
    if (finalized.length != original.length) {
      throw StateError('Length changed ${original.length} -> ${finalized.length}');
    }

    // 4) 백업 + 저장 방식(원자적 교체가 기본)
    if (makeBackup) {
      await File('${f.path}.bak').writeAsBytes(original, flush: true);
    }

    if (mode == SaveWriteMode.atomicRename) {
      final tmpPath = '${f.path}.tmp';
      final tmp = File(tmpPath);
      // 임시파일에 먼저 기록
      await tmp.writeAsBytes(finalized, flush: true);
      try {
        // 가능한 경우 원자적 교체 시도
        await tmp.rename(f.path);
      } on FileSystemException catch (e1) {
        // 일부 플랫폼/상황(특히 대상이 열려있을 때)에서 rename이 덮어쓰기를 못할 수 있음
        logW(_tag, 'atomic rename failed, fallback to in-place. err=$e1');
        // 안전을 위해 마지막 수단으로 인플레이스 기록
        await f.writeAsBytes(finalized, flush: true);
        // 실패 시 tmp 제거 시도
        try { if (await tmp.exists()) await tmp.delete(); } catch (_) {}
      }
    } else {
      // 인플레이스
      await f.writeAsBytes(finalized, flush: true);
    }

    // 5) **무결성 검증**: 파일 재열기 → 계산값 == 꼬리 4바이트?
    if (e != IsaacEdition.rebirth) {
      final reread = await f.readAsBytes();
      final calc = codec.calcAfterbirthChecksum(
        Uint8List.fromList(reread),
        0x10,
        reread.length - 0x10 - 4,
      );
      final tail = ByteData.sublistView(
        Uint8List.fromList(reread),
        reread.length - 4,
        reread.length,
      ).getUint32(0, Endian.little);

      if ((calc & 0xFFFFFFFF) != tail) {
        throw StateError(
          'Checksum mismatch after write: '
              'calc=0x${calc.toRadixString(16)} tail=0x${tail.toRadixString(16)}',
        );
      }

      logI(_tag, 'write ok: $value ($e:$slot) file=${f.path} '
          'cs=0x${calc.toRadixString(16)} mode=$mode');
    }
  }
}

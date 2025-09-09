import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/features/isaac/save/infra/isaac_save_codec.dart';

/// 테스트용: UInt16/UInt32 LE 쓰기 헬퍼
void _putU16LE(Uint8List b, int ofs, int v) {
  b[ofs] = v & 0xFF;
  b[ofs + 1] = (v >> 8) & 0xFF;
}
void _putU32LE(Uint8List b, int ofs, int v) {
  b[ofs] = v & 0xFF;
  b[ofs + 1] = (v >> 8) & 0xFF;
  b[ofs + 2] = (v >> 16) & 0xFF;
  b[ofs + 3] = (v >> 24) & 0xFF;
}

/// 테스트용 가짜 세이브 생성:
/// - 헤더 테이블(0x14부터)과 섹션 엔트리 길이 규칙을 대략 맞춰서
///   section[1]의 오프셋이 충분히 뒤쪽을 가리키도록 만듭니다.
/// - 그 위치 + 0x04 + 0x50 에 eden 값을 심습니다.
class _FakeSave {
  final Uint8List bytes;
  final int section1Offset;
  final int edenAbsOfs;

  _FakeSave(this.bytes, this.section1Offset, this.edenAbsOfs);
}

_FakeSave _makeFakeSave({
  int len = 0x300,        // 전체 파일 길이
  int s0Count = 256,      // section[0] 엔트리 수(섹션1을 뒤로 밀기 위한 용)
  int initialEden = 0,    // 초기 에덴 값
}) {
  final entryLens = [1, 4, 4, 1, 1, 1, 1, 4, 4, 1];
  final counts = List<int>.filled(10, 0);
  counts[0] = s0Count; // 첫 섹션 엔트리를 채워 section[1] 시작점을 뒤로 밀기

  final buf = Uint8List(len);
  var ofs = 0x14;
  int? s1Ofs;

  for (var i = 0; i < 10; i++) {
    for (var j = 0; j < 3; j++) {
      _putU16LE(buf, ofs, j == 2 ? counts[i] : 0);
      ofs += 4; // 2바이트 + padding 2바이트
    }
    // 방금 섹션 i의 카운트 3개를 썼으니, entries 시작점이 현재 ofs
    if (i == 1) s1Ofs = ofs;

    // entries 영역으로 오프셋 전진
    ofs += entryLens[i] * counts[i];
  }

  final section1Offset = s1Ofs!;
  final edenAbs = section1Offset + 0x04 + 0x50;

  // 초기 에덴 값 심기 (UInt32 LE)
  _putU32LE(buf, edenAbs, initialEden);

  // 꼬리 4바이트(체크섬 자리)는 일단 0으로 둔다.
  return _FakeSave(buf, section1Offset, edenAbs);
}

void main() {
  group('IsaacSaveCodec (pure dart) — Eden/Checksum', () {
    test('readEdenTokens: 헤더 파싱을 통해 심어둔 값을 읽어온다 (AAA)', () {
      // Arrange
      final fake = _makeFakeSave(initialEden: 777);
      final codec = IsaacSaveCodec();

      // Act
      final v = codec.readEdenTokens(fake.bytes);

      // Assert
      expect(v, 777);
    });

    test('writeEdenTokens: 원본 불변 + 지정 위치에 UInt32 LE로 기록 (AAA)', () {
      // Arrange
      final fake = _makeFakeSave(initialEden: 0);
      final codec = IsaacSaveCodec();

      // 원본 백업
      final orig = Uint8List.fromList(fake.bytes);

      // Act
      final out = codec.writeEdenTokens(fake.bytes, 1234567890);

      // Assert: 원본은 변하면 안 됨
      expect(fake.bytes, equals(orig));

      // Assert: 새 버퍼의 지정 위치 값 확인 (read로도 한 번 더)
      final readBack = codec.readEdenTokens(out);
      expect(readBack, 1234567890);

      // 바이트 단위(LE) 확인
      final ofs = fake.edenAbsOfs;
      expect(out[ofs + 0], equals(0xD2)); // 1234567890 = 0x499602D2
      expect(out[ofs + 1], equals(0x02));
      expect(out[ofs + 2], equals(0x96));
      expect(out[ofs + 3], equals(0x49));
    });

    test('updateChecksumAfterbirthFamily: 꼬리 4바이트가 calc와 정확히 일치 (AAA)', () {
      // Arrange
      final fake = _makeFakeSave(initialEden: 42);
      final codec = IsaacSaveCodec();

      // Act
      final out = codec.updateChecksumAfterbirthFamily(fake.bytes);

      // Assert
      final offset = 0x10;
      final length = out.length - offset - 4;
      final calc = codec.calcAfterbirthChecksum(out, offset, length);

      final tail = ByteData.sublistView(out).getUint32(out.length - 4, Endian.little);
      expect(tail, equals(calc));
    });

    test('round-trip: write → checksum → read (AAA)', () {
      // Arrange
      final fake = _makeFakeSave(initialEden: 0);
      final codec = IsaacSaveCodec();

      // Act
      final written = codec.writeEdenTokens(fake.bytes, 9001);
      final withCs = codec.updateChecksumAfterbirthFamily(written);
      final back = codec.readEdenTokens(withCs);

      // Assert
      expect(back, 9001);
    });

    test('readEdenTokens(section1Offset 수동): 헤더를 무시하고 주어진 오프셋을 사용 (AAA)', () {
      // Arrange
      final buf = Uint8List(0x200);
      final manualS1 = 0x60; // 임의 섹션1 오프셋
      final edenAbs = manualS1 + 0x04 + 0x50;
      _putU32LE(buf, edenAbs, 321);

      final codec = IsaacSaveCodec();

      // Act
      final v = codec.readEdenTokens(buf, section1Offset: manualS1);

      // Assert
      expect(v, 321);
    });
  });
}

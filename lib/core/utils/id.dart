import 'dart:math';

/// 전역 ID/Key Generator & Parser 유틸.
///
/// - [genId] : prefix 기반 고유 ID 생성 (예: `mp_1712923123123456_4821_0`)
/// - [buildEntryKey] : ModEntry 등에서 쓰는 Key 생성 (`id:<id>` 또는 `local:<generated>`)
/// - [parseEntryKeyId] : `id:<id>` 형태의 Key에서 `<id>`만 추출
///
/// 설계 노트
/// - 동일 마이크로초 내 다중 호출 충돌 방지를 위해 sequence 포함
/// - 외부 저장소(Repository) 중복 최종 확인은 Service 레이어에서 수행
/// - `local` 키는 재시작 후에도 충돌 확률이 매우 낮도록 시간/랜덤/시퀀스 기반으로 생성
class IdUtil {
  IdUtil._();

  static final Random _rand = Random();
  static int _seq = 0;
  static int _lastMicros = 0;

  /// 고유 ID Generator.
  ///
  /// - [prefix]로 도메인 구분 (예: 'mp', 'inst', 'slot' 등)
  /// - 내부 구성: `prefix_nowMicros_random4digits_sequence`
  /// - 예: `mp_1712923123123456_4821_0`
  static String genId([String prefix = 'id']) {
    final now = DateTime.now().microsecondsSinceEpoch;

    if (now == _lastMicros) {
      _seq = (_seq + 1) & 0xFFFF; // 0..65535 롤오버
    } else {
      _lastMicros = now;
      _seq = 0;
    }

    final r = _rand.nextInt(9000) + 1000; // 1000~9999
    return '${prefix}_${now}_${r}_$_seq';
  }
}


/// 인증/프로필 저장소 추상화.
/// - DB 스키마가 바뀌어도 Service/상위 레이어는 안전하게 유지
abstract class AuthRepository {
  /// users 테이블에서 프로필 조회
  /// - displayName: UI 표시용 이름(현 스키마에서 users.email 사용)
  /// - isAdmin: 운영자/테스터 여부
  Future<({String? displayName, bool isAdmin})?> fetchProfile(String uid);

  /// 표시명 갱신(없으면 upsert)
  Future<void> upsertDisplayName({
    required String uid,
    required String displayName,
  });
}

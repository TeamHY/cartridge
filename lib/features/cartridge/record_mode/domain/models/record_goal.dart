import 'package:flutter/widgets.dart';
import 'package:cartridge/l10n/app_localizations.dart';

/// Record(기록) 목표의 정규화된 식별자.
/// - 문자열 id는 Lua RecorderMod의 BOSSES 키와 동일해야 합니다.
enum RecordGoalId {
  perfection,
  mom,
  blueBaby,
  mother,
  megaSatan,
  theLamb,
  theBeast,
  delirium,
}

/// id(String) ↔ enum 변환 및 리소스/로케일 매핑
extension RecordGoalIdX on RecordGoalId {
  /// DB/Lua와 동일한 문자열 id
  String get idString {
    switch (this) {
      case RecordGoalId.perfection: return 'perfection';
      case RecordGoalId.mom:        return 'mom';
      case RecordGoalId.blueBaby:   return 'blue_baby';
      case RecordGoalId.mother:     return 'mother';
      case RecordGoalId.megaSatan:  return 'mega_satan';
      case RecordGoalId.theLamb:    return 'the_lamb';
      case RecordGoalId.theBeast:   return 'the_beast';
      case RecordGoalId.delirium:   return 'delirium';
    }
  }

  /// 로컬라이즈된 타이틀
  String localizedTitle(AppLocalizations loc) {
    switch (this) {
      case RecordGoalId.perfection: return loc.record_goal_perfection;
      case RecordGoalId.mom:        return loc.record_goal_mom;
      case RecordGoalId.blueBaby:   return loc.record_goal_blue_baby;
      case RecordGoalId.mother:     return loc.record_goal_mother;
      case RecordGoalId.megaSatan:  return loc.record_goal_mega_satan;
      case RecordGoalId.theLamb:    return loc.record_goal_the_lamb;
      case RecordGoalId.theBeast:   return loc.record_goal_the_beast;
      case RecordGoalId.delirium:   return loc.record_goal_delirium;
    }
  }

  /// 목표 이미지 파일명 (148x125 리소스 폴더)
  String get imageFile {
    switch (this) {
      case RecordGoalId.perfection: return 'Perfection.png';
      case RecordGoalId.mom:        return 'mom.png';
      case RecordGoalId.blueBaby:   return 'isaac_bluebaby_boss.png';
      case RecordGoalId.mother:     return 'mother.png';
      case RecordGoalId.megaSatan:  return 'mega_satan.gif';
      case RecordGoalId.theLamb:    return 'the_lamb.png';
      case RecordGoalId.theBeast:   return 'the_beast.png';
      case RecordGoalId.delirium:   return 'delirium.png';
    }
  }

  /// 풀 경로
  String get imageAsset => 'assets/images/record_goal/$imageFile';

  /// String id → enum
  static RecordGoalId? fromId(String id) {
    switch (id) {
      case 'perfection':  return RecordGoalId.perfection;
      case 'mom':         return RecordGoalId.mom;
      case 'blue_baby':   return RecordGoalId.blueBaby;
      case 'mother':      return RecordGoalId.mother;
      case 'mega_satan':  return RecordGoalId.megaSatan;
      case 'the_lamb':    return RecordGoalId.theLamb;
      case 'the_beast':   return RecordGoalId.theBeast;
      case 'delirium':    return RecordGoalId.delirium;
      default:            return null;
    }
  }
}

/// 개발자는 id만 넘기면 됩니다.
/// 나머지 값(title, imageAsset)은 게터에서 자동 계산됩니다.
@immutable
class RecordGoal {
  final String id; // DB에서 온 원본 id (Lua BOSSES 키와 동일)
  const RecordGoal(this.id);

  RecordGoalId get _kind =>
      RecordGoalIdX.fromId(id) ?? RecordGoalId.perfection; // 안전 기본값

  /// 로컬라이즈된 제목(호출 시점 로케일 적용)
  String titleOf(BuildContext context) =>
      _kind.localizedTitle(AppLocalizations.of(context));

  /// 이미지 asset 경로
  String get imageAsset => _kind.imageAsset;
  String localizedTitle(AppLocalizations loc) => _kind.localizedTitle(loc);
  /// 현재 로케일로 확정 데이터를 뽑아 UI로 넘길 때 편리
  LocalizedRecordGoal localized(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return LocalizedRecordGoal(
      id: _kind.idString,
      title: _kind.localizedTitle(loc),
      imageAsset: _kind.imageAsset,
    );
  }
}

/// 한 프레임에서 고정 텍스트/이미지가 필요한 경우
@immutable
class LocalizedRecordGoal {
  final String id;
  final String title;
  final String imageAsset;
  const LocalizedRecordGoal({
    required this.id,
    required this.title,
    required this.imageAsset,
  });
}

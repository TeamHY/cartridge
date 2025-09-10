import 'package:flutter/widgets.dart';

/// 타이포그래피 디자인 토큰.
/// - 색상은 기본적으로 테마가 적용하므로 명시하지 않습니다(디폴트 텍스트 컬러 사용).
/// - 스타일 이름은 용도 중심으로 간결하게 유지합니다.
class AppTypography {
  // 기본 폰트 패밀리(없으면 시스템 기본 사용)
  static const String fontSans = 'Pretendard';
  static const String? fontMono = null; // 예: 'JetBrainsMono'

  /// 내비게이션 패널 아이템(좌측 사이드바)용
  static const TextStyle navigationPane = TextStyle(
    fontFamily: fontSans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.20,
    letterSpacing: 0.1,
  );

  /// 앱 타이틀(헤더/앱바 등)
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontSans,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.20,
  );

  /// 섹션 헤더(중간 굵기)
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontSans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  /// 본문 기본
  static const TextStyle body = TextStyle(
    fontFamily: fontSans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.40,
  );

  /// 본문 강조
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontSans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.40,
  );

  /// 보조 설명/캡션
  static const TextStyle caption = TextStyle(
    fontFamily: fontSans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.30,
    letterSpacing: 0.1,
  );

  /// 모노스페이스(코드/로그)
  static const TextStyle code = TextStyle(
    fontFamily: fontMono,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  /// 슬롯머신
  static const TextStyle slotItem = TextStyle(
    fontFamily: fontSans,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.20,
  );
}

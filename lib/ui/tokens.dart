import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.surfaceRaised,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.enabled,
    required this.enabledInk,
    required this.enabledSoft,
    required this.enabledLine,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.warn,
    required this.scrim,
    required this.shadowMenu,
    required this.shadowDialog,
  });

  final Color bg;
  final Color surface1;
  final Color surface2;
  final Color surface3;
  final Color surfaceRaised;
  final Color line;
  final Color lineStrong;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color enabled;
  final Color enabledInk;
  final Color enabledSoft;
  final Color enabledLine;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;
  final Color warn;
  final Color scrim;
  final Color shadowMenu;
  final Color shadowDialog;

  static const light = AppColors(
    bg: Color(0xFFFFFFFF),
    surface1: Color(0xFFFFFFFF),
    surface2: Color(0xFFFFFFFF),
    surface3: Color(0xFFF3F4F6),
    surfaceRaised: Color(0xFFFFFFFF),
    line: Color(0xFFE6E8EB),
    lineStrong: Color(0xFF8B9098),
    ink: Color(0xFF111318),
    ink2: Color(0xFF4A4F57),
    ink3: Color(0xFF6B7078),
    accent: Color(0xFF2563EB),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x142563EB),
    enabled: Color(0xFF2563EB),
    enabledInk: Color(0xFF1D4ED8),
    enabledSoft: Color(0x122563EB),
    enabledLine: Color(0x592563EB),
    success: Color(0xFF1A7F37),
    successSoft: Color(0x141A7F37),
    danger: Color(0xFFD92D20),
    dangerSoft: Color(0x14D92D20),
    warn: Color(0xFF946200),
    scrim: Color(0x660A0C10),
    shadowMenu: Color(0x1F0A0C10),
    shadowDialog: Color(0x290A0C10),
  );

  static const dark = AppColors(
    bg: Color(0xFF0F1012),
    surface1: Color(0xFF141518),
    surface2: Color(0xFF18191C),
    surface3: Color(0xFF222428),
    surfaceRaised: Color(0xFF2A2C31),
    line: Color(0xFF2C2E33),
    lineStrong: Color(0xFF767B84),
    ink: Color(0xFFF2F3F5),
    ink2: Color(0xFFB9BCC2),
    ink3: Color(0xFF969AA1),
    accent: Color(0xFF5C9DFF),
    onAccent: Color(0xFF0B0D10),
    accentSoft: Color(0x245C9DFF),
    enabled: Color(0xFF5C9DFF),
    enabledInk: Color(0xFFA9CBFF),
    enabledSoft: Color(0x1F5C9DFF),
    enabledLine: Color(0x665C9DFF),
    success: Color(0xFF5FCF80),
    successSoft: Color(0x245FCF80),
    danger: Color(0xFFFF7B72),
    dangerSoft: Color(0x24FF7B72),
    warn: Color(0xFFE3B341),
    scrim: Color(0xA6000000),
    shadowMenu: Color(0x80000000),
    shadowDialog: Color(0x99000000),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

abstract final class AppTextStyles {
  static const title =
      TextStyle(fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w700);
  static const section =
      TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600);
  static const body =
      TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400);
  static const bodyStrong =
      TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600);
  static const caption =
      TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w400);
  static const wordmark = TextStyle(
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 13 * 0.18,
  );
  static const value = TextStyle(
    fontFamily: 'Consolas',
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );
}

abstract final class AppRadius {
  static const sm = 4.0;
  static const md = 6.0;
  static const lg = 10.0;
}

const appControlHeight = 32.0;

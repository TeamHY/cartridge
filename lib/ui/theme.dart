import 'package:cartridge/ui/tokens.dart';
import 'package:flutter/material.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  return ThemeData(
    brightness: brightness,
    visualDensity: VisualDensity.standard,
    fontFamily: 'Pretendard',
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.danger,
      onError: c.onAccent,
      surface: c.surface2,
      onSurface: c.ink,
      onSurfaceVariant: c.ink2,
      outline: c.lineStrong,
      outlineVariant: c.line,
      surfaceContainerHighest: c.surface3,
      surfaceTint: Colors.transparent,
    ),
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    cardColor: c.surface1,
    dividerColor: c.line,
    hoverColor: c.surface3,
    focusColor: Colors.transparent,
    highlightColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    textTheme: TextTheme(
      bodyLarge: AppTextStyles.body.copyWith(color: c.ink),
      bodyMedium: AppTextStyles.body.copyWith(color: c.ink),
      bodySmall: AppTextStyles.caption.copyWith(color: c.ink3),
      titleLarge: AppTextStyles.title.copyWith(color: c.ink),
      titleMedium: AppTextStyles.section.copyWith(color: c.ink),
      titleSmall: AppTextStyles.bodyStrong.copyWith(color: c.ink),
      labelLarge: AppTextStyles.body.copyWith(color: c.ink),
    ),
    iconTheme: IconThemeData(color: c.ink2, size: 18),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      textStyle: AppTextStyles.caption
          .copyWith(color: c.bg, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      waitDuration: const Duration(milliseconds: 400),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.surfaceRaised),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(c.shadowMenu),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: c.line),
          ),
        ),
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(160, appControlHeight)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(AppTextStyles.body),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled) ? c.ink3 : c.ink),
        iconColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled) ? c.ink3 : c.ink2),
        iconSize: const WidgetStatePropertyAll(16),
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)
                ? c.surface3
                : Colors.transparent),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.accent,
      inactiveTrackColor: c.line,
      thumbColor: c.accent,
      overlayColor: c.accent.withValues(alpha: 0.1),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      valueIndicatorColor: c.ink,
      valueIndicatorTextStyle: AppTextStyles.caption.copyWith(color: c.bg),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.surface3,
      circularTrackColor: Colors.transparent,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(3),
      thumbColor: WidgetStatePropertyAll(c.lineStrong.withValues(alpha: 0.6)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withValues(alpha: 0.3),
      selectionHandleColor: c.accent,
    ),
    extensions: [c],
  );
}

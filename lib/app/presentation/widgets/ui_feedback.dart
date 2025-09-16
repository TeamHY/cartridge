import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// UI 피드백 헬퍼
///
/// InfoBar, SnackBar, 경고/에러 메시지 등을 간단하게 호출 가능
class UiFeedback {
  /// 정보 메시지
  static void info(BuildContext context, {String? title, required String content}) {
    _showInfoBar(context, title, content, InfoBarSeverity.info);
  }

  /// 경고 메시지
  static void warn(BuildContext context, {String? title, required String content}) {
    _showInfoBar(context, title, content, InfoBarSeverity.warning);
  }

  /// 에러 메시지
  static void error(BuildContext context, {String? title, required String content}) {
    _showInfoBar(context, title, content, InfoBarSeverity.error);
  }

  /// 성공 메시지
  static void success(BuildContext context, {String? title, required String content}) {
    _showInfoBar(context, title, content, InfoBarSeverity.success);
  }

  static void _showInfoBar(
      BuildContext context,
      String? title,
      String content,
      InfoBarSeverity severity,
      ) {
    final loc = AppLocalizations.of(context);
    final ft  = FluentTheme.of(context);

    final fallbackTitle = switch (severity) {
      InfoBarSeverity.info    => loc.common_info,
      InfoBarSeverity.warning => loc.common_warning,
      InfoBarSeverity.error   => loc.common_error,
      InfoBarSeverity.success => loc.common_success,
    };
    final resolvedTitle = (title == null || title.trim().isEmpty) ? fallbackTitle : title;

    displayInfoBar(
      context,
      builder: (ctx, close) {
        // 기본 InfoBar 테마(현재 컨텍스트 기준)
        final base = InfoBarTheme.of(ctx);

        final solidInfoDecoration = BoxDecoration(
          color: ft.cardColor,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: ft.resources.cardStrokeColorDefault),
        );

        return InfoBarTheme.merge(
          data: InfoBarThemeData(
            // info면 불투명, 아니면 기존 데코레이션 유지
            decoration: (sev) => (sev == InfoBarSeverity.info)
                ? solidInfoDecoration
                : base.decoration?.call(sev),
          ),
          child: InfoBar(
            title: Text(resolvedTitle),
            content: Text(content),
            severity: severity,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
        );
      },
    );
  }
}

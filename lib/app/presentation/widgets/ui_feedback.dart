import 'package:fluent_ui/fluent_ui.dart';

/// UI 피드백 헬퍼
///
/// InfoBar, SnackBar, 경고/에러 메시지 등을 간단하게 호출 가능
class UiFeedback {
  /// 정보 메시지
  static void info(BuildContext context, String title, String content) {
    _showInfoBar(context, title, content, InfoBarSeverity.info);
  }

  /// 경고 메시지
  static void warn(BuildContext context, String title, String content) {
    _showInfoBar(context, title, content, InfoBarSeverity.warning);
  }

  /// 에러 메시지
  static void error(BuildContext context, String title, String content) {
    _showInfoBar(context, title, content, InfoBarSeverity.error);
  }

  /// 성공 메시지
  static void success(BuildContext context, String title, String content) {
    _showInfoBar(context, title, content, InfoBarSeverity.success);
  }

  static void _showInfoBar(
      BuildContext context,
      String title,
      String content,
      InfoBarSeverity severity,
      ) {
    displayInfoBar(
      context,
      builder: (ctx, close) {
        return InfoBar(
          title: Text(title),
          content: Text(content),
          severity: severity,
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
        );
      },
    );
  }
}

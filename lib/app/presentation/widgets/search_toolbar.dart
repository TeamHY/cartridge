import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/theme/tokens/spacing.dart';
import 'package:flutter/services.dart';

class SearchToolbar extends StatelessWidget {
  const SearchToolbar({
    super.key,
    required this.controller,
    required this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.prefix,
    this.actions = const <Widget>[],
    this.padding = EdgeInsets.zero,
  });

  final TextEditingController controller;
  final String placeholder;

  /// 검색 텍스트 변경 콜백 (null 이면 콜백 생략)
  final ValueChanged<String>? onChanged;

  /// 엔터(Submit) 처리
  final ValueChanged<String>? onSubmitted;

  /// 검색 입력 활성화 여부
  final bool enabled;

  /// 좌측 prefix 슬롯(없으면 기본 검색 아이콘)
  final Widget? prefix;

  /// 우측 액션들 (예: [취소], [저장] / [생성] 등)
  final List<Widget> actions;

  /// 외부 패딩
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final hasClear = controller.text.isNotEmpty;

    void clear() {
      if (controller.text.isEmpty) return;
      controller.clear();
      if (enabled && onChanged != null) onChanged!('');
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  DismissIntent: CallbackAction<DismissIntent>(
                    onInvoke: (intent) {
                      clear();
                      return null;
                    },
                  ),
                },
                child: TextBox(
                  controller: controller,
                  placeholder: placeholder,
                  enabled: enabled,
                  prefix: prefix ??
                      const Padding(
                        padding: EdgeInsets.only(left: AppSpacing.xs),
                        child: Icon(FluentIcons.search),
                      ),
                  onChanged: enabled ? onChanged : null,
                  onSubmitted: enabled ? onSubmitted : null,
                  suffix: hasClear
                      ? IconButton(
                    icon: const Icon(FluentIcons.chrome_close),
                    onPressed: () {
                      controller.clear();
                      if (enabled && onChanged != null) onChanged!('');
                    },
                  )
                      : null,
                ),
              ),
            ),
          ),
          if (actions.isNotEmpty) ...[
            Gaps.w16,
            Row(children: actions),
          ],
        ],
      ),
    );
  }
}

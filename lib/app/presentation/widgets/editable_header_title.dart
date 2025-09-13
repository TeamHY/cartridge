import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:cartridge/theme/tokens/spacing.dart';
import 'package:cartridge/theme/tokens/typography.dart';

class EditableHeaderTitle extends StatefulWidget {
  final String title;
  final bool editing;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;
  final VoidCallback onStartEdit;

  final String? hintText;
  final bool autofocusWhenEditing;
  final int maxLines;
  final TextOverflow overflow;

  const EditableHeaderTitle({
    super.key,
    required this.title,
    required this.editing,
    required this.onSave,
    required this.onCancel,
    required this.onStartEdit,
    this.hintText,
    this.autofocusWhenEditing = true,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  State<EditableHeaderTitle> createState() => _EditableHeaderTitleState();
}

class _EditableHeaderTitleState extends State<EditableHeaderTitle> {
  late final TextEditingController _ctrl =
  TextEditingController(text: widget.title);
  final FocusNode _focus = FocusNode(debugLabel: 'EditableHeaderTitle');

  bool _hover = false;

  @override
  void didUpdateWidget(covariant EditableHeaderTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 편집 시작 시, 현재 타이틀을 입력값으로 동기화
    if (widget.editing && !oldWidget.editing) {
      _ctrl.text = widget.title;
      _ctrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
      if (widget.autofocusWhenEditing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus.requestFocus();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || text == widget.title) {
      widget.onCancel();
      return;
    }
    widget.onSave(text);
  }

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);

    // 보기 모드: 제목 + 연필 아이콘 전체가 클릭 영역, 아이콘은 hover시에만 나타남
    if (!widget.editing) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onStartEdit,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.title,
                  maxLines: widget.maxLines,
                  overflow: widget.overflow,
                  softWrap: false,
                  style: AppTypography.appBarTitle,
                ),
              ),
              Gaps.w4,
              AnimatedOpacity(
                opacity: _hover ? 0.7 : 0.0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: Icon(
                  FluentIcons.edit,
                  size: 16,
                  color: fTheme.accentColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hint = widget.hintText ?? loc.editable_title_hint;

    // 편집 모드
    return Row(
      children: [
        Expanded(
          child: Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
                  _submit();
                  return null;
                }),
                DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) {
                  widget.onCancel();
                  return null;
                }),
              },
              child: Focus(
                focusNode: _focus,
                child: TextBox(
                  controller: _ctrl,
                  placeholder: hint,
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ),
          ),
        ),
        Gaps.w4,
        Tooltip(
          message: loc.common_save,
          child: FilledButton(
            onPressed: _ctrl.text.trim().isEmpty ? null : _submit,
            child: const Icon(FluentIcons.save, size: 16),
          ),
        ),
        Gaps.w4,
        Tooltip(
          message: loc.common_cancel,
          child: Button(
            onPressed: widget.onCancel,
            child: const Icon(FluentIcons.chrome_close, size: 14),
          ),
        ),
      ],
    );
  }
}

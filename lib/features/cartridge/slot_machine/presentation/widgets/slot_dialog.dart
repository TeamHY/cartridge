import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class SlotDialog extends ConsumerStatefulWidget {
  const SlotDialog({
    super.key,
    required this.items,
    required this.onEdit,
  });

  final List<String> items;
  final Function(List<String> newItems) onEdit;

  @override
  ConsumerState<SlotDialog> createState() => _SlotDialogState();
}

class _SlotDialogState extends ConsumerState<SlotDialog> {
  late List<String> _items;
  final List<TextEditingController> _controllers = [];
  int _nextId = 0;
  final List<int> _ids = [];
  final List<FocusNode> _focusNodes = [];
  final ScrollController _scrollCtl = ScrollController();

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.items);
    _rebuildControllers();
  }

  void _rebuildControllers() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }

    _controllers
      ..clear()
      ..addAll(_items.map((e) => TextEditingController(text: e)));

    _focusNodes
      ..clear()
      ..addAll(List.generate(_items.length, (_) => FocusNode()));

    _ids
      ..clear()
      ..addAll(List.generate(_items.length, (_) => _nextId++));
  }

  void _focusAt(int i) {
    if (i < 0 || i >= _focusNodes.length) return;
    _focusNodes[i].requestFocus();
    final c = _controllers[i];
    c.selection = TextSelection.collapsed(offset: c.text.length);
  }

  void _ensureVisibleBottom() {
    if (!_scrollCtl.hasClients) return;
    _scrollCtl.animateTo(
      _scrollCtl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  void _add() => _addAfter(_items.length - 1);

  void _addAfter(int i, {String text = ''}) {
    final idx = (i < 0) ? 0 : i + 1;
    setState(() {
      _items.insert(idx, text);
      _controllers.insert(idx, TextEditingController(text: text));
      _focusNodes.insert(idx, FocusNode());
      _ids.insert(idx, _nextId++);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusAt(idx);
      _ensureVisibleBottom();
    });
  }

  void _removeAt(int i) {
    if (i < 0 || i >= _items.length) return;
    setState(() {
      _controllers[i].dispose();
      _focusNodes[i].dispose();
      _controllers.removeAt(i);
      _focusNodes.removeAt(i);
      _items.removeAt(i);
      _ids.removeAt(i);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_items.isEmpty) return;
      final next = (i - 1).clamp(0, _items.length - 1);
      _focusAt(next);
    });
  }

  bool _isEnter(KeyEvent e) =>
      e is KeyDownEvent &&
          (e.logicalKey == LogicalKeyboardKey.enter ||
              e.logicalKey == LogicalKeyboardKey.numpadEnter);

  bool _isBackspace(KeyEvent e) =>
      e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.backspace;

  void _onEnterAt(int i) {
    final composing = _controllers[i].value.composing;
    if (composing.isValid) return;
    _addAfter(i);
  }

  bool _onBackspaceAt(int i) {
    if (i < 0 || i >= _controllers.length) return false;
    final c = _controllers[i];
    final sel = c.selection;
    final caretAtStart = sel.baseOffset == 0 && sel.extentOffset == 0;
    if (c.text.isEmpty && caretAtStart) {
      _removeAt(i);
      return true;
    }
    return false;
  }

  Future<void> _onPasteAt(int i) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text ?? '';
    if (raw.isEmpty) return;

    final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');

    final nonEmpty =
    lines.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (nonEmpty.isEmpty) return;

    if (nonEmpty.length == 1) {
      final c = _controllers[i];
      final sel = c.selection;
      final start = (sel.start >= 0) ? sel.start : c.text.length;
      final end = (sel.end >= 0) ? sel.end : c.text.length;
      final inserted = nonEmpty.first;

      final newText = c.text.replaceRange(start, end, inserted);
      setState(() {
        c.text = newText;
        _items[i] = newText;
        c.selection =
            TextSelection.collapsed(offset: start + inserted.length);
      });
      return;
    }

    final c = _controllers[i];
    final targetLines = <String>[];
    setState(() {
      if (c.text.trim().isEmpty) {
        c.text = nonEmpty.first;
        _items[i] = c.text;
        targetLines.addAll(nonEmpty.skip(1)); // 첫 줄은 현재 행에
      } else {
        targetLines.addAll(nonEmpty);
      }

      var idx = i;
      for (final s in targetLines) {
        idx++;
        _items.insert(idx, s);
        _controllers.insert(idx, TextEditingController(text: s));
        _focusNodes.insert(idx, FocusNode());
        _ids.insert(idx, _nextId++);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final added = targetLines.length;
      final target = (i + added).clamp(0, _controllers.length - 1);
      _focusAt(target);
      _ensureVisibleBottom();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _scrollCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final fTheme = FluentTheme.of(context);
    final sem = ref.watch(themeSemanticsProvider);

    return ContentDialog(
      title: Row(
        children: [
          Icon(FluentIcons.edit, size: 18, color: sem.info.fg),
          Gaps.w4,
          Text(loc.slot_edit_title),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox(
          height: 560,
          child: Container(
            decoration: BoxDecoration(
              color: fTheme.cardColor,
              borderRadius: AppShapes.dialog,
              border: Border.all(color: sem.neutral.border),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      loc.slot_edit_title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: loc.slot_add_item,
                      style: const TooltipThemeData(
                        waitDuration: Duration.zero,
                      ),
                      child: IconButton(
                        icon: Icon(FluentIcons.add, color: sem.success.fg),
                        onPressed: _add,
                      ),
                    ),
                  ],
                ),
                Gaps.h8,
                Expanded(
                  child: Scrollbar(
                    controller: _scrollCtl,
                    interactive: true,
                    child: ListView.separated(
                      controller: _scrollCtl,
                      padding: EdgeInsets.zero,
                      itemCount: _items.length,
                      separatorBuilder: (_, __) =>
                      Gaps.h4,
                      itemBuilder: (context, i) {
                        return KeyedSubtree(
                          key: ValueKey(_ids[i]),
                          child: Row(
                            children: [
                              Expanded(
                                child: Focus(
                                  onKeyEvent: (node, event) {
                                    if (_isEnter(event)) {
                                      _onEnterAt(i);
                                      return KeyEventResult.handled;
                                    }
                                    if (_isBackspace(event)) {
                                      final removed = _onBackspaceAt(i);
                                      return removed
                                          ? KeyEventResult.handled
                                          : KeyEventResult.ignored;
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: Actions(
                                    actions: <Type, Action<Intent>>{
                                      PasteTextIntent:
                                      CallbackAction<PasteTextIntent>(
                                        onInvoke: (_) {
                                          _onPasteAt(i);
                                          return null;
                                        },
                                      ),
                                    },
                                    child: TextBox(
                                      controller: _controllers[i],
                                      focusNode: _focusNodes[i],
                                      onChanged: (v) => _items[i] = v,
                                      placeholder: loc.common_edit,
                                      maxLines: 1,
                                      onSubmitted: (_) => _onEnterAt(i),
                                    ),
                                  ),
                                ),
                              ),
                              Gaps.w4,
                              Tooltip(
                                message: loc.slot_remove_item,
                                style: const TooltipThemeData(
                                  waitDuration: Duration.zero,
                                ),
                                child: IconButton(
                                  icon: Icon(FluentIcons.remove,
                                      color: sem.danger.fg),
                                  onPressed: () => _removeAt(i),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Button(
          key: const Key('slotdialog-close'),
          onPressed: () => Navigator.pop(context),
          child: Text(loc.common_cancel),
        ),
        FilledButton(
          key: const Key('slotdialog-apply'),
          onPressed: () {
            final trimmed = _items
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            final result = trimmed.isEmpty
                ? <String>[AppLocalizations.of(context).slot_default]
                : trimmed;
            widget.onEdit(result);
            Navigator.pop(context);
          },
          child: Text(loc.common_apply),
        ),
      ],
    );
  }
}

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class HotkeyRecordDialog extends StatefulWidget {
  final String? initialHotkey;

  const HotkeyRecordDialog({super.key, this.initialHotkey});

  @override
  State<HotkeyRecordDialog> createState() => _HotkeyRecordDialogState();
}

class _HotkeyRecordDialogState extends State<HotkeyRecordDialog> {
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  String _displayText = '';
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _displayText = widget.initialHotkey ?? '';
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _pressedKeys.clear();
      _displayText = '';
    });
  }

  String _formatHotkey() {
    if (_pressedKeys.isEmpty) return '';

    final modifiers = <String>[];
    String? mainKey;

    for (final key in _pressedKeys) {
      if (key == LogicalKeyboardKey.control ||
          key == LogicalKeyboardKey.controlLeft ||
          key == LogicalKeyboardKey.controlRight) {
        if (!modifiers.contains('ctrl')) modifiers.add('ctrl');
      } else if (key == LogicalKeyboardKey.alt ||
          key == LogicalKeyboardKey.altLeft ||
          key == LogicalKeyboardKey.altRight) {
        if (!modifiers.contains('alt')) modifiers.add('alt');
      } else if (key == LogicalKeyboardKey.shift ||
          key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight) {
        if (!modifiers.contains('shift')) modifiers.add('shift');
      } else if (key == LogicalKeyboardKey.meta ||
          key == LogicalKeyboardKey.metaLeft ||
          key == LogicalKeyboardKey.metaRight) {
        if (!modifiers.contains('meta')) modifiers.add('meta');
      } else {
        mainKey = _getKeyLabel(key);
      }
    }

    if (mainKey == null) return '';

    return [...modifiers, mainKey].join('+');
  }

  String _getKeyLabel(LogicalKeyboardKey key) {
    if (key.keyId >= LogicalKeyboardKey.keyA.keyId &&
        key.keyId <= LogicalKeyboardKey.keyZ.keyId) {
      return String.fromCharCode(
              key.keyId - LogicalKeyboardKey.keyA.keyId + 'a'.codeUnitAt(0))
          .toLowerCase();
    }
    if (key.keyId >= LogicalKeyboardKey.digit0.keyId &&
        key.keyId <= LogicalKeyboardKey.digit9.keyId) {
      return (key.keyId - LogicalKeyboardKey.digit0.keyId).toString();
    }
    if (key.keyId >= LogicalKeyboardKey.f1.keyId &&
        key.keyId <= LogicalKeyboardKey.f12.keyId) {
      return 'f${key.keyId - LogicalKeyboardKey.f1.keyId + 1}';
    }

    final specialKeys = {
      LogicalKeyboardKey.space: 'space',
      LogicalKeyboardKey.enter: 'enter',
      LogicalKeyboardKey.tab: 'tab',
      LogicalKeyboardKey.escape: 'escape',
      LogicalKeyboardKey.backspace: 'backspace',
      LogicalKeyboardKey.delete: 'delete',
      LogicalKeyboardKey.home: 'home',
      LogicalKeyboardKey.end: 'end',
      LogicalKeyboardKey.pageUp: 'pageup',
      LogicalKeyboardKey.pageDown: 'pagedown',
      LogicalKeyboardKey.arrowUp: 'up',
      LogicalKeyboardKey.arrowDown: 'down',
      LogicalKeyboardKey.arrowLeft: 'left',
      LogicalKeyboardKey.arrowRight: 'right',
      LogicalKeyboardKey.bracketLeft: '[',
      LogicalKeyboardKey.bracketRight: ']',
      LogicalKeyboardKey.semicolon: ';',
      LogicalKeyboardKey.quote: '\'',
      LogicalKeyboardKey.comma: ',',
      LogicalKeyboardKey.period: '.',
      LogicalKeyboardKey.slash: '/',
      LogicalKeyboardKey.backslash: '\\',
      LogicalKeyboardKey.backquote: '`',
      LogicalKeyboardKey.minus: '-',
      LogicalKeyboardKey.equal: '=',
    };

    return specialKeys[key] ?? key.keyLabel.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ContentDialog(
      title: Text(loc.hotkey_record_dialog_title),
      content: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (event) {
          if (!_isRecording) return;

          if (event is KeyDownEvent) {
            setState(() {
              _pressedKeys.add(event.logicalKey);
              _displayText = _formatHotkey();
            });
          } else if (event is KeyUpEvent) {
            if (_pressedKeys.isNotEmpty) {
              setState(() {
                _isRecording = false;
              });
            }
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isRecording
                  ? loc.hotkey_record_dialog_recording
                  : loc.hotkey_record_dialog_prompt,
              style: FluentTheme.of(context).typography.body,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[20],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _isRecording
                      ? FluentTheme.of(context).accentColor
                      : Colors.grey[60],
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _displayText.isEmpty
                      ? loc.hotkey_record_dialog_waiting
                      : _displayText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _displayText.isEmpty ? Colors.grey[100] : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isRecording)
              Button(
                onPressed: _startRecording,
                child: Text(loc.hotkey_record_dialog_start_recording),
              ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.common_cancel),
        ),
        FilledButton(
          onPressed: _displayText.isNotEmpty && !_isRecording
              ? () => Navigator.pop(context, _displayText)
              : null,
          child: Text(loc.common_save),
        ),
      ],
    );
  }
}

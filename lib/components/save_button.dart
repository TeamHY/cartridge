import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SaveButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const SaveButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton> {
  static const _shortcut = SingleActivator(
    LogicalKeyboardKey.keyS,
    control: true,
    includeRepeats: false,
  );

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!mounted ||
        widget.onPressed == null ||
        event.synthesized ||
        !_shortcut.accepts(event, HardwareKeyboard.instance) ||
        ModalRoute.of(context)?.isCurrent != true) {
      return false;
    }

    widget.onPressed!();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(onPressed: widget.onPressed, child: widget.child);
  }
}

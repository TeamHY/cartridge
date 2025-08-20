import 'package:cartridge/models/mod.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModItem extends ConsumerWidget {
  const ModItem({
    super.key,
    required this.mod,
    required this.onChanged,
  });

  final Mod mod;
  final Function(bool value) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled = !mod.isDisable;

    return fluent.Tooltip(
      message: mod.name,
      useMousePosition: false,
      child: InkWell(
        onTap: () => onChanged(mod.isDisable),
        borderRadius: BorderRadius.circular(12),
        splashColor: enabled
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.1),
        highlightColor: enabled
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled
                ? Colors.green.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mod.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: enabled ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        mod.version != null && mod.version!.trim().isNotEmpty
                            ? 'v${mod.version}'
                            : '알 수 없음',
                        style: TextStyle(
                          fontSize: 12,
                          color: enabled ? Colors.green[600] : Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                enabled ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: enabled ? Colors.green[600] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

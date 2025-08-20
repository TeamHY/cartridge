import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class ModGroupDialog extends ConsumerStatefulWidget {
  final String? initialGroupName;
  final bool isEdit;

  const ModGroupDialog({
    super.key,
    this.initialGroupName,
    this.isEdit = false,
  });

  @override
  ConsumerState<ModGroupDialog> createState() => _ModGroupDialogState();
}

class _ModGroupDialogState extends ConsumerState<ModGroupDialog> {
  late TextEditingController _groupNameController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _groupNameController =
        TextEditingController(text: widget.initialGroupName ?? '');
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).group_name_required;
      });
      return;
    }

    final store = ref.read(storeProvider);

    if (store.groups.containsKey(groupName)) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).group_name_exists;
      });
      return;
    }

    if (widget.isEdit && widget.initialGroupName != null) {
      store.renameGroup(widget.initialGroupName!, groupName);
    } else {
      store.addGroup(groupName);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(widget.isEdit
          ? AppLocalizations.of(context).group_rename_title
          : AppLocalizations.of(context).group_create_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextBox(
            controller: _groupNameController,
            placeholder: AppLocalizations.of(context).group_name_placeholder,
            autofocus: true,
            onSubmitted: (_) => _handleCreate(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).common_cancel),
        ),
        FilledButton(
          onPressed: _handleCreate,
          child: Text(widget.isEdit
              ? AppLocalizations.of(context).common_update
              : AppLocalizations.of(context).common_save),
        ),
      ],
    );
  }
}

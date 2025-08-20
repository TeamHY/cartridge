import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    _groupNameController = TextEditingController(text: widget.initialGroupName ?? '');
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
        _errorMessage = '그룹 이름을 입력해주세요';
      });
      return;
    }

    final store = ref.read(storeProvider);
    
    if (store.groups.containsKey(groupName)) {
      setState(() {
        _errorMessage = '이미 존재하는 그룹 이름입니다';
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
      title: Text(widget.isEdit ? '그룹 이름 변경' : '새 그룹 생성'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextBox(
            controller: _groupNameController,
            placeholder: '그룹 이름을 입력하세요',
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
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _handleCreate,
          child: Text(widget.isEdit ? '변경' : '생성'),
        ),
      ],
    );
  }
}
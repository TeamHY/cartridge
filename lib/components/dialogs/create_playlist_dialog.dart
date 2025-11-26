import 'dart:io';
import 'package:cartridge/components/dialogs/playlist_dialog_content.dart';
import 'package:cartridge/constants/isaac_enums.dart';
import 'package:cartridge/models/music_playlist.dart';
import 'package:cartridge/models/music_trigger_condition.dart';
import 'package:cartridge/providers/music_player_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class CreatePlaylistDialog extends ConsumerStatefulWidget {
  const CreatePlaylistDialog({super.key});

  @override
  ConsumerState<CreatePlaylistDialog> createState() =>
      _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<CreatePlaylistDialog> {
  final _nameController = TextEditingController();
  final _folderPathController = TextEditingController();

  bool _isPickingFolder = false;
  String _conditionType = 'stage';

  final Set<IsaacStage> _selectedStages = {};

  IsaacRoomType _roomType = IsaacRoomType.defaultRoom;
  bool _isOnlyUncleared = false;

  IsaacBossType _bossType = IsaacBossType.blueBaby;

  @override
  void dispose() {
    _nameController.dispose();
    _folderPathController.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    setState(() {
      _isPickingFolder = true;
    });

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      final executablePath = path.dirname(Platform.resolvedExecutable);
      final relativePath =
          path.relative(selectedDirectory, from: executablePath);

      final isSubPath = !relativePath.startsWith('..');

      setState(() {
        _folderPathController.text =
            isSubPath ? relativePath : selectedDirectory;
      });
    }

    setState(() {
      _isPickingFolder = false;
    });
  }

  MusicTriggerCondition _buildCondition() {
    switch (_conditionType) {
      case 'stage':
        return StageStayingCondition(_selectedStages);
      case 'room':
        return RoomStayingCondition(_roomType, _isOnlyUncleared);
      case 'boss':
        return BossClearedCondition(_bossType);
      default:
        return StageStayingCondition(_selectedStages);
    }
  }

  void _createPlaylist() {
    final musicPlayer = ref.read(musicPlayerProvider);

    final playlist = MusicPlaylist(
      id: const Uuid().v4(),
      name: _nameController.text,
      condition: _buildCondition(),
      folderPath: _folderPathController.text,
    );
    playlist.loadTracks();

    musicPlayer.addPlaylist(playlist);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(
        maxWidth: 800,
        minHeight: 600,
        maxHeight: 600,
      ),
      title: const Text('새 플레이리스트 만들기'),
      content: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          child: PlaylistDialogContent(
            nameController: _nameController,
            folderPathController: _folderPathController,
            conditionType: _conditionType,
            onConditionTypeChanged: (value) {
              setState(() => _conditionType = value);
            },
            onFolderPick: _pickFolder,
            onNameChanged: () => setState(() {}),
            onFolderPathChanged: () => setState(() {}),
            conditionSettings: _buildConditionSettings(),
            isPickingFolder: _isPickingFolder,
          ),
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: (_nameController.text.isEmpty ||
                  _folderPathController.text.isEmpty)
              ? null
              : _createPlaylist,
          child: const Text('만들기'),
        ),
      ],
    );
  }

  Widget _buildConditionSettings() {
    switch (_conditionType) {
      case 'stage':
        return _buildStageSettings();
      case 'room':
        return _buildRoomSettings();
      case 'boss':
        return _buildBossSettings();
      default:
        return Container();
    }
  }

  Widget _buildStageSettings() {
    return StageSettings(
      selectedStages: _selectedStages,
      onStageToggle: (stage, value) {
        setState(() {
          if (value) {
            _selectedStages.add(stage);
          } else {
            _selectedStages.remove(stage);
          }
        });
      },
      onToggleAll: () {
        setState(() {
          if (_selectedStages.length == IsaacStage.values.length) {
            _selectedStages.clear();
          } else {
            _selectedStages.addAll(IsaacStage.values);
          }
        });
      },
      onGroupToggle: (stages, allSelected) {
        setState(() {
          if (allSelected) {
            _selectedStages.removeAll(stages);
          } else {
            _selectedStages.addAll(stages);
          }
        });
      },
    );
  }

  Widget _buildRoomSettings() {
    return RoomSettings(
      roomType: _roomType,
      isOnlyUncleared: _isOnlyUncleared,
      onRoomTypeChanged: (value) {
        setState(() {
          _roomType = value!;
        });
      },
      onUnclearedChanged: (value) {
        setState(() {
          _isOnlyUncleared = value ?? false;
        });
      },
    );
  }

  Widget _buildBossSettings() {
    return BossSettings(
      bossType: _bossType,
      onBossTypeChanged: (value) {
        setState(() {
          _bossType = value!;
        });
      },
    );
  }
}

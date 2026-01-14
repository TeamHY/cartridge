import 'dart:io';
import 'package:cartridge/components/dialogs/error_dialog.dart';
import 'package:cartridge/components/dialogs/playlist_dialog_content.dart';
import 'package:cartridge/constants/isaac_enums.dart';
import 'package:cartridge/models/music_playlist.dart';
import 'package:cartridge/models/music_trigger_condition.dart';
import 'package:cartridge/providers/music_player_provider.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

class EditPlaylistDialog extends ConsumerStatefulWidget {
  final MusicPlaylist playlist;

  const EditPlaylistDialog({super.key, required this.playlist});

  @override
  ConsumerState<EditPlaylistDialog> createState() => _EditPlaylistDialogState();
}

class _EditPlaylistDialogState extends ConsumerState<EditPlaylistDialog> {
  late final TextEditingController _nameController;

  late String _conditionType;

  late Set<IsaacStage> _selectedStages;

  late Set<IsaacRoomType> _selectedRoomTypes;
  late bool _isOnlyUncleared;
  late bool _filterByBossType;

  late Set<IsaacBossType> _selectedBossTypes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.id);

    final condition = widget.playlist.condition;
    if (condition is StageStayingCondition) {
      _conditionType = 'stage';
      _selectedStages = Set.from(condition.stage);
      _selectedRoomTypes = {};
      _isOnlyUncleared = false;
      _selectedBossTypes = {};
    } else if (condition is RoomStayingCondition) {
      _conditionType = 'room';
      _selectedStages = {};
      _selectedRoomTypes = Set.from(condition.roomTypes);
      _isOnlyUncleared = condition.isOnlyWithMonsters;
      _filterByBossType = condition.bossTypes != null;
      _selectedBossTypes =
          condition.bossTypes != null ? Set.from(condition.bossTypes!) : {};
    } else if (condition is BossClearedCondition) {
      _conditionType = 'boss';
      _selectedStages = {};
      _selectedRoomTypes = {};
      _isOnlyUncleared = false;
      _selectedBossTypes = Set.from(condition.bossTypes);
    } else {
      _conditionType = 'stage';
      _selectedStages = {};
      _selectedRoomTypes = {};
      _isOnlyUncleared = false;
      _filterByBossType = false;
      _selectedBossTypes = {};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  MusicTriggerCondition _buildCondition() {
    switch (_conditionType) {
      case 'stage':
        return StageStayingCondition(_selectedStages);
      case 'room':
        final bossTypes = _filterByBossType && _selectedBossTypes.isNotEmpty
            ? _selectedBossTypes
            : null;
        return RoomStayingCondition(
            _selectedRoomTypes, _isOnlyUncleared, bossTypes);
      case 'boss':
        return BossClearedCondition(_selectedBossTypes);
      default:
        return StageStayingCondition(_selectedStages);
    }
  }

  Future<void> _updatePlaylist() async {
    try {
      final setting = ref.read(settingProvider);
      final musicPlayer = ref.read(musicPlayerProvider);

      await musicPlayer.loadPlaylists();

      if (widget.playlist.id != _nameController.text) {
        final oldDir =
            Directory(path.join(setting.musicPlaylistPath, widget.playlist.id));
        final newDir = Directory(
            path.join(setting.musicPlaylistPath, _nameController.text));

        if (oldDir.existsSync()) {
          await oldDir.rename(newDir.path);
        }
      }

      final updatedPlaylist = MusicPlaylist(
        id: _nameController.text,
        rootPath: setting.musicPlaylistPath,
        condition: _buildCondition(),
      );
      await updatedPlaylist.loadTracks();

      musicPlayer.updatePlaylist(widget.playlist.id, updatedPlaylist);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => const ErrorDialog(
            text: '플레이리스트 수정 실패',
          ),
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(
        maxWidth: 800,
        minHeight: 600,
        maxHeight: 600,
      ),
      title: const Text('플레이리스트 수정'),
      content: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          child: PlaylistDialogContent(
            nameController: _nameController,
            conditionType: _conditionType,
            onConditionTypeChanged: (value) {
              setState(() => _conditionType = value);
            },
            onNameChanged: () => setState(() {}),
            conditionSettings: _buildConditionSettings(),
          ),
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: (_nameController.text.isEmpty) ? null : _updatePlaylist,
          child: const Text('수정'),
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
      selectedRoomTypes: _selectedRoomTypes,
      isOnlyUncleared: _isOnlyUncleared,
      filterByBossType: _filterByBossType,
      selectedBossTypes: _selectedBossTypes,
      onRoomTypeToggle: (roomType, value) {
        setState(() {
          if (value) {
            _selectedRoomTypes.add(roomType);
          } else {
            _selectedRoomTypes.remove(roomType);
          }
        });
      },
      onUnclearedChanged: (value) {
        setState(() {
          _isOnlyUncleared = value ?? false;
        });
      },
      onFilterByBossTypeChanged: (value) {
        setState(() {
          _filterByBossType = value ?? false;
          if (!_filterByBossType) {
            _selectedBossTypes.clear();
          }
        });
      },
      onBossTypeToggle: (bossType, value) {
        setState(() {
          if (value) {
            _selectedBossTypes.add(bossType);
          } else {
            _selectedBossTypes.remove(bossType);
          }
        });
      },
    );
  }

  Widget _buildBossSettings() {
    return BossSettings(
      selectedBossTypes: _selectedBossTypes,
      onBossTypeToggle: (bossType, value) {
        setState(() {
          if (value) {
            _selectedBossTypes.add(bossType);
          } else {
            _selectedBossTypes.remove(bossType);
          }
        });
      },
    );
  }
}

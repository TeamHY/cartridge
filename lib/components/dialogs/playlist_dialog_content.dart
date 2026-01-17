import 'package:cartridge/constants/isaac_enums.dart';
import 'package:fluent_ui/fluent_ui.dart';

class PlaylistDialogContent extends StatelessWidget {
  final TextEditingController nameController;
  final String conditionType;
  final Function(String) onConditionTypeChanged;
  final VoidCallback onNameChanged;
  final Widget conditionSettings;

  const PlaylistDialogContent({
    super.key,
    required this.nameController,
    required this.conditionType,
    required this.onConditionTypeChanged,
    required this.onNameChanged,
    required this.conditionSettings,
  });

  Widget _buildConditionButton(
      BuildContext context, String value, String label) {
    final isSelected = conditionType == value;
    return Expanded(
      child: isSelected
          ? FilledButton(
              onPressed: () => onConditionTypeChanged(value),
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              child: Text(label),
            )
          : Button(
              onPressed: () => onConditionTypeChanged(value),
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              child: Text(label),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('플레이리스트 이름'),
        const SizedBox(height: 8),
        TextBox(
          controller: nameController,
          onChanged: (value) => onNameChanged(),
          placeholder: '플레이리스트 이름을 입력하세요',
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('재생 조건',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildConditionButton(context, 'stage', '스테이지 체류'),
                  const SizedBox(width: 8),
                  _buildConditionButton(context, 'room', '방 체류'),
                  const SizedBox(width: 8),
                  _buildConditionButton(context, 'boss', '보스 클리어'),
                ],
              ),
              const SizedBox(height: 16),
              conditionSettings,
            ],
          ),
        ),
      ],
    );
  }
}

class StageSettings extends StatelessWidget {
  final Set<IsaacStage> selectedStages;
  final Function(IsaacStage, bool) onStageToggle;
  final VoidCallback onToggleAll;
  final Function(List<IsaacStage>, bool) onGroupToggle;

  const StageSettings({
    super.key,
    required this.selectedStages,
    required this.onStageToggle,
    required this.onToggleAll,
    required this.onGroupToggle,
  });

  @override
  Widget build(BuildContext context) {
    final stageGroups = <String, List<IsaacStage>>{
      '1~2': [
        IsaacStage.basement,
        IsaacStage.cellar,
        IsaacStage.burningBasement,
        IsaacStage.downpour,
        IsaacStage.dross
      ],
      '3~4': [
        IsaacStage.caves,
        IsaacStage.catacombs,
        IsaacStage.floodedCaves,
        IsaacStage.mines,
        IsaacStage.ashpit
      ],
      '5~6': [
        IsaacStage.depths,
        IsaacStage.necropolis,
        IsaacStage.dankDepths,
        IsaacStage.mausoleum,
        IsaacStage.gehenna
      ],
      '7~8': [
        IsaacStage.womb,
        IsaacStage.utero,
        IsaacStage.scarredWomb,
        IsaacStage.corpse
      ],
      '9': [IsaacStage.blueWomb],
      '10': [IsaacStage.sheol, IsaacStage.cathedral],
      '11': [IsaacStage.darkRoom, IsaacStage.chest],
      '12': [IsaacStage.theVoid],
      '13': [IsaacStage.homeDay, IsaacStage.homeNight],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('스테이지 선택 (복수 선택 가능)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Button(
              onPressed: onToggleAll,
              child: Text(
                selectedStages.length == IsaacStage.values.length
                    ? '전체 해제'
                    : '전체 선택',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...stageGroups.entries.map((entry) {
          final groupName = entry.key;
          final stages = entry.value;
          final allSelected = stages.every((s) => selectedStages.contains(s));

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        groupName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[140],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => onGroupToggle(stages, allSelected),
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4)),
                          backgroundColor: WidgetStateProperty.all(
                            allSelected ? Colors.grey[60] : Colors.blue.light,
                          ),
                        ),
                        child: Text(
                          allSelected ? '전체 해제' : '전체 선택',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: stages.map((stage) {
                      final isSelected = selectedStages.contains(stage);
                      return ToggleButton(
                        checked: isSelected,
                        onChanged: (value) => onStageToggle(stage, value),
                        child: Text(
                          stage.toDisplayString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class RoomSettings extends StatelessWidget {
  final Set<IsaacRoomType> selectedRoomTypes;
  final bool isOnlyUncleared;
  final Function(IsaacRoomType, bool) onRoomTypeToggle;
  final Function(bool?) onUnclearedChanged;

  const RoomSettings({
    super.key,
    required this.selectedRoomTypes,
    required this.isOnlyUncleared,
    required this.onRoomTypeToggle,
    required this.onUnclearedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('방 타입 (복수 선택 가능)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: IsaacRoomType.values
              .where((roomType) => roomType != IsaacRoomType.null_)
              .map((roomType) {
            final isSelected = selectedRoomTypes.contains(roomType);
            return ToggleButton(
              checked: isSelected,
              onChanged: (value) => onRoomTypeToggle(roomType, value),
              child: Text(
                roomType.toDisplayString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Checkbox(
          checked: isOnlyUncleared,
          onChanged: onUnclearedChanged,
          content: const Text('클리어 전까지만 재생'),
        ),
      ],
    );
  }
}

class BossSettings extends StatelessWidget {
  final Set<IsaacBossType> selectedBossTypes;
  final Function(IsaacBossType, bool) onBossTypeToggle;

  const BossSettings({
    super.key,
    required this.selectedBossTypes,
    required this.onBossTypeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('보스 타입 (복수 선택 가능)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: IsaacBossExtension.sortedValues.map((bossType) {
            final isSelected = selectedBossTypes.contains(bossType);
            return ToggleButton(
              checked: isSelected,
              onChanged: (value) => onBossTypeToggle(bossType, value),
              child: Text(
                bossType.toDisplayString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

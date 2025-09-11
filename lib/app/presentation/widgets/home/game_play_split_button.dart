import 'package:cartridge/features/cartridge/instances/presentation/widgets/instance_image/instance_image_thumb.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/controllers/home_controller.dart';
import 'package:cartridge/app/presentation/widgets/home/ut_split_button.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/instance_view.dart';


class GamePlaySplitButton extends ConsumerWidget {
  const GamePlaySplitButton({
    super.key,
    required this.instances,
    required this.buttonColor,
  });

  final List<InstanceView> instances;
  final Color buttonColor;

  // 메인 버튼 텍스트와 드롭다운 버튼을 분리하여 레이아웃을 구성
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentId = ref.watch(recentInstanceIdProvider);

    String? selectedId = recentId;
    String selectedName = '';
    if (instances.isNotEmpty) {
      final found = recentId == null
          ? null
          : instances.firstWhere((e) => e.id == recentId, orElse: () => InstanceView.empty);
      if (found != null && found.id.isNotEmpty) {
        selectedId = found.id;
        selectedName = found.name;
      } else {
        selectedId = instances.first.id;
        selectedName = instances.first.name;
      }
    }

    void playSelected() {
      final runId = selectedId;
      if (runId != null && runId.isNotEmpty) {
        ref.read(instancePlayServiceProvider).playByInstanceId(runId);
      }
    }

    return UtSplitButton(
      mainButtonText: '인스턴스 플레이',
      secondaryText: selectedName,
      buttonColor: buttonColor,
      onMainButtonPressed: playSelected,
      dropdownMenuItems: const [],
      dropdownBuilder: (ctx) => _InstancePickerPanel(
        instances: instances,
        selectedId: selectedId,
        onPick: (id) {
          ref.read(recentInstanceIdProvider.notifier).state = id; // 선택만 갱신
        },
        onPlayNow: playSelected, // 패널의 "바로 실행" 버튼
        width: 340,
        maxHeight: 320,
      ),
    );
  }
}


class _InstancePickerPanel extends StatefulWidget {
  const _InstancePickerPanel({
    required this.instances,
    required this.selectedId,
    required this.onPick,         // 선택만 갱신
    required this.onPlayNow,      // 즉시 실행(선택 유지)
    this.width = 340,
    this.maxHeight = 320,
  });

  final List<InstanceView> instances;
  final String? selectedId;
  final ValueChanged<String> onPick;
  final VoidCallback onPlayNow;
  final double width;
  final double maxHeight;

  @override
  State<_InstancePickerPanel> createState() => _InstancePickerPanelState();
}

class _InstancePickerPanelState extends State<_InstancePickerPanel> {
  late final ScrollController _scrollCtrl;
  late final TextEditingController _searchCtrl;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final divider = fTheme.dividerColor;

    final list = (_q.trim().isEmpty)
        ? widget.instances
        : widget.instances.where((v) {
      final q = _q.toLowerCase();
      return v.name.toLowerCase().contains(q);
    }).toList(growable: false);

    return Container(
      width: widget.width,
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: fTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: divider),
        boxShadow: [
          BoxShadow(
            color: fTheme.shadowColor.withAlpha(30),
            blurRadius: 14, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              const Icon(FluentIcons.server, size: 14),
              const SizedBox(width: 6),
              const Text('인스턴스 선택', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          Gaps.h8,
          // 검색
          TextBox(
            controller: _searchCtrl,
            onChanged: (s) => setState(() => _q = s),
            placeholder: '검색',
          ),
          Gaps.h8,

          // 목록
          Expanded(
            child: Scrollbar(
              controller: _scrollCtrl,
              interactive: true,
              child: ListView.separated(
                controller: _scrollCtrl,
                primary: false,               // ★ PrimaryScrollController 사용 금지
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final v = list[i];
                  final selected = v.id == widget.selectedId;

                  return _InstanceTile(
                    view: v,
                    selected: selected,
                    onTap: () {
                      widget.onPick(v.id);
                      Flyout.of(context).close();   // ★ 닫기
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstanceTile extends StatelessWidget {
  const _InstanceTile({
    required this.view,
    required this.selected,
    required this.onTap,
  });

  final InstanceView view;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final selColor = fTheme.accentColor;

    return HoverButton(
      onPressed: onTap,
      builder: (ctx, states) {
        final hovered = states.isHovered;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: hovered ? fTheme.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? selColor : Colors.transparent,
              width: selected ? 1.2 : 1.0,
            ),
          ),
          child: Row(
            children: [
              InstanceImageThumb(
                image: view.image,              // InstanceView.image
                fallbackSeed: view.name,        // 이름 해시로 스프라이트 인덱스 산출
                size: 32,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  view.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Gaps.w8,
              if (selected)
                Icon(FluentIcons.check_mark, size: 14, color: selColor),
            ],
          ),
        );
      },
    );
  }
}
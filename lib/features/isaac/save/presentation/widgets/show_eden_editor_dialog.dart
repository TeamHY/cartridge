import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/isaac/save/application/eden_editor_controller.dart';
import 'package:cartridge/features/isaac/save/presentation/widgets/show_choose_steam_account_dialog.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kEdenMax = 10000;

Future<void> openEdenTokenEditor(
    BuildContext context,
    WidgetRef ref, {
      IsaacEdition? detectedEdition,
    }) async {
  // 1) 계정 선택
  List<SteamAccountProfile> accounts;
  try {
    accounts = await ref.read(steamAccountsProvider.future);
  } catch (_) {
    if (context.mounted) {
      UiFeedback.error(context, '조회 실패', '세이브 목록을 불러오지 못했어요.');
    }
    return;
  }
  if (accounts.isEmpty) {
    if (context.mounted) {
      UiFeedback.warn(context, '세이브를 찾지 못했어요', 'Steam Cloud 또는 로컬 세이브가 감지되지 않았습니다.');
    }
    return;
  }
  if (!context.mounted) return;

  final account =
  (accounts.length == 1) ? accounts.first : await showChooseSteamAccountDialog(context, accounts);
  if (account == null) return;

  // 2) 에디션/슬롯
  final res = await ref.read(
    editionAndSlotsProvider((acc: account, detected: detectedEdition)).future,
  );
  if (res.slots.isEmpty) {
    if (context.mounted) {
      UiFeedback.warn(context, '세이브 파일이 없어요', '에디션/슬롯별 세이브 파일을 찾지 못했습니다.');
    }
    return;
  }

  // 3) 다이얼로그
  if (!context.mounted) return;
  final args = EdenEditorArgs(
    account: account,
    edition: res.edition,
    slots: res.slots,
    initialSlot: res.slots.first,
  );

  await showDialog<void>(
    context: context,
    useRootNavigator: false,
    builder: (_) => _EdenEditorDialog(args: args),
  );
}

class _EdenEditorDialog extends ConsumerStatefulWidget {
  final EdenEditorArgs args;
  const _EdenEditorDialog({required this.args});

  @override
  ConsumerState<_EdenEditorDialog> createState() => _EdenEditorDialogState();
}

class _EdenEditorDialogState extends ConsumerState<_EdenEditorDialog> {
  static const _r = 12.0;
  int? newValue;

  int _clamp(int v) => v < 0 ? 0 : (v > kEdenMax ? kEdenMax : v);

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final asyncState = ref.watch(edenEditorControllerProvider(widget.args));

    Color divider(FluentThemeData th) =>
        th.dividerColor ?? (th.resources.textFillColorSecondary).withAlpha(64);

    return asyncState.when(
      loading: () => const ContentDialog(content: Center(child: ProgressRing())),
      error: (e, _) => ContentDialog(
        title: const Text('에덴 토큰'),
        content: InfoBar(
          title: const Text('오류'),
          content: Text('$e'),
          severity: InfoBarSeverity.error,
        ),
        actions: [Button(child: const Text('닫기'), onPressed: () => Navigator.of(context).pop())],
      ),
      data: (s) {
        newValue ??= s.currentValue ?? 0;

        return ContentDialog(
          title: Row(
            children: [
              Icon(FluentIcons.pro_hockey, size: 18, color: t.accentColor.normal),
              SizedBox(width: AppSpacing.xs),
              const Text('에덴 토큰'),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 580),
          content: SingleChildScrollView(
            padding: EdgeInsets.only(right: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 에디션 레이블
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '${IsaacEditionInfo.folderName[s.edition]}',
                    style: TextStyle(
                      color: t.resources.textFillColorSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),

                if (s.error != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    child: InfoBar(
                      title: const Text('안내'),
                      content: Text(s.error!),
                      severity: InfoBarSeverity.warning,
                    ),
                  ),

                SizedBox(height: AppSpacing.md),

                // 슬롯 선택
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text('게임의 저장 칸(슬롯)을 선택하세요.', style: t.typography.caption),
                ),
                Row(
                  children: List.generate(3, (i) {
                    final slot = i + 1;
                    final exists = s.slots.contains(slot);
                    final selected = s.selectedSlot == slot;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(end: i < 2 ? AppSpacing.sm : 0),
                        child: Button(
                          onPressed: (!exists || s.loading || s.saving)
                              ? null
                              : () async {
                            await ref
                                .read(edenEditorControllerProvider(widget.args).notifier)
                                .selectSlot(slot);
                            setState(() => newValue = null);
                          },
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(
                              EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                            ),
                            backgroundColor: WidgetStateProperty.resolveWith((_) {
                              if (!exists) return t.inactiveColor.withAlpha(16);
                              if (selected) return t.accentColor.normal.withAlpha(36);
                              return null;
                            }),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected) const Icon(FluentIcons.check_mark, size: 14),
                              if (selected) SizedBox(width: AppSpacing.xs),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(text: '슬롯 '),
                                    TextSpan(
                                      text: '$slot',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                SizedBox(height: AppSpacing.md),

                if (s.loading) const ProgressBar(),

                if (!s.loading && s.selectedSlot != 0) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: t.cardColor,
                      borderRadius: BorderRadius.circular(_r),
                      border: Border.all(color: divider(t)),
                    ),
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 헤더
                        Row(
                          children: [
                            const Text('토큰 값', style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: t.accentColor.withAlpha(
                                  t.brightness == Brightness.dark ? 128 : 80,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '현재: ${s.currentValue ?? '-'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: AppSpacing.sm),

                        // 입력부
                        Row(
                          children: [
                            Expanded(
                              child: NumberBox(
                                value: newValue,
                                min: 0,
                                max: kEdenMax,
                                smallChange: 1,
                                largeChange: 10,
                                mode: SpinButtonPlacementMode.inline,
                                onChanged: (v) => setState(() => newValue = _clamp((v ?? newValue ?? 0))),
                              ),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Button(
                              onPressed: () => setState(() => newValue = kEdenMax),
                              child: const Text('최대(10,000)'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppSpacing.md),

                  if (s.edition == IsaacEdition.rebirth)
                    InfoBar(
                      title: const Text('안내'),
                      content: const Text('이 에디션에서는 값 변경을 지원하지 않아요. 다른 에디션에서 시도해 주세요.'),
                      severity: InfoBarSeverity.info,
                    ),
                ],
              ],
            ),
          ),
          actions: [
            Button(child: const Text('닫기'), onPressed: () => Navigator.of(context).pop()),
            FilledButton(
              onPressed: (s.edition == IsaacEdition.rebirth || s.loading || s.saving || s.selectedSlot == 0)
                  ? null
                  : () async {
                await ref
                    .read(edenEditorControllerProvider(widget.args).notifier)
                    .save(_clamp(newValue!));
                final after = ref.read(edenEditorControllerProvider(widget.args)).value;
                if (after?.error == null && context.mounted) {
                  UiFeedback.success(context, '저장 완료', '변경한 값이 적용되었어요.');
                  setState(() => newValue = after?.currentValue ?? newValue);
                }
              },
              child: s.saving ? const ProgressRing() : const Text('저장'),
            ),
          ],
        );
      },
    );
  }
}

import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/isaac/save/application/eden_editor_controller.dart';
import 'package:cartridge/features/isaac/save/presentation/widgets/show_choose_steam_account_dialog.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kEdenMax = 10000;

Future<void> openEdenTokenEditor(
    BuildContext context,
    WidgetRef ref, {
      IsaacEdition? detectedEdition,
    }) async {
  final loc = AppLocalizations.of(context);

  // 1) 계정 선택 (로딩/에러/빈 상태: 사용자 친화적으로)
  List<SteamAccountProfile> accounts;
  try {
    accounts = await ref.read(steamAccountsProvider.future);
  } catch (_) {
    if (context.mounted) {
      UiFeedback.error(context, loc.eden_err_accounts_title, loc.eden_err_accounts_desc);
    }
    return;
  }
  if (accounts.isEmpty) {
    if (context.mounted) {
      UiFeedback.warn(context, loc.eden_warn_no_accounts_title, loc.eden_warn_no_accounts_desc);
    }
    return;
  }
  if (!context.mounted) return;

  final account = (accounts.length == 1)
      ? accounts.first
      : await showChooseSteamAccountDialog(context, items: accounts);
  if (account == null) return;

  // 2) 에디션/슬롯 조회
  final res = await ref.read(
    editionAndSlotsProvider((acc: account, detected: detectedEdition)).future,
  );
  if (res.slots.isEmpty) {
    if (context.mounted) {
      UiFeedback.warn(context, loc.eden_warn_no_saves_title, loc.eden_warn_no_saves_desc);
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
  static const _slotHeight = 54.0; // 슬롯 버튼 고정 높이
  int? newValue;

  int _clamp(int v) => v < 0 ? 0 : (v > kEdenMax ? kEdenMax : v);

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);
    final asyncState = ref.watch(edenEditorControllerProvider(widget.args));

    Row titleRow(String text) => Row(
      children: [
        Icon(FluentIcons.pro_hockey, size: 18, color: fTheme.accentColor.normal),
        Gaps.w4,
        Text(text),
      ],
    );

    // 공용 Dialog 빌더: loading 여부만 바꿔 동일 레이아웃 유지
    Widget buildDialogContent({
      required IsaacEdition edition,
      required List<int> slots,
      required int selectedSlot,
      required bool isLoading,
      required bool isSaving,
      required int? currentValue,
      String? warningText, // 내부 경고(파일 읽기 실패 등)
    }) {
      // 로딩 중에도 컨트롤은 그대로 보여주되 비활성화
      final controlsEnabled = !isLoading && !isSaving && selectedSlot != 0;

      // 초기 값 고정(로딩에서도 동일한 높이 확보)
      newValue ??= currentValue ?? 0;

      return SingleChildScrollView(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 에디션 라벨
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                IsaacEditionInfo.folderName[edition] ?? '',
                style: TextStyle(
                  color: fTheme.resources.textFillColorSecondary,
                  fontSize: 16,
                ),
              ),
            ),

            // 슬롯 선택 섹션
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(loc.eden_slot_help, style: AppTypography.caption),
            ),
            Row(
              children: List.generate(3, (i) {
                final slot = i + 1;
                final exists = slots.contains(slot);
                final selected = selectedSlot == slot;

                final bgColor = !exists
                    ? fTheme.inactiveColor.withAlpha(16)
                    : (selected
                    ? fTheme.accentColor.normal.withAlpha(
                  fTheme.brightness == Brightness.dark ? 48 : 36,
                )
                    : null);

                return Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(end: i < 2 ? AppSpacing.sm : 0),
                    child: SizedBox(
                      height: _slotHeight, // 고정 높이
                      child: Button(
                        key: ValueKey('slot_btn_$slot'),
                        onPressed: (!exists || isLoading || isSaving)
                            ? null
                            : () async {
                          await ref
                              .read(edenEditorControllerProvider(widget.args).notifier)
                              .selectSlot(slot);
                          setState(() => newValue = null);
                        },
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm, // 세로 패딩 확대
                            ),
                          ),
                          backgroundColor: WidgetStateProperty.all(bgColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected) const Icon(FluentIcons.check_mark, size: 20),
                            if (selected) Gaps.w4,
                            Text(loc.eden_slot_label(slot), style: AppTypography.sectionTitle,),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            Gaps.h16, // 섹션 간 여백 확대

            Container(
              decoration: BoxDecoration(
                color: fTheme.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: fTheme.dividerColor),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더 + 현재값 Chip
                  Row(
                    children: [
                      Text(
                        loc.eden_value_label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Gaps.w8,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: fTheme.accentColor.withAlpha(
                            fTheme.brightness == Brightness.dark ? 128 : 80,
                          ),
                          borderRadius: AppShapes.pill,
                        ),
                        child: Text(
                          loc.eden_current_chip(
                            (currentValue?.toString() ?? '–'),
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 입력부 (로딩/세이빙 중에는 비활성화만)
                  Row(
                    children: [
                      Expanded(
                        child: IgnorePointer(
                          ignoring: !controlsEnabled,
                          child: Opacity(
                            opacity: controlsEnabled ? 1.0 : 0.6,
                            child: NumberBox(
                              value: newValue,
                              min: 0,
                              max: kEdenMax,
                              smallChange: 1,
                              largeChange: 10,
                              mode: SpinButtonPlacementMode.inline,
                              onChanged: (v) {
                                if (!controlsEnabled) return;
                                setState(() {
                                  final next = v ?? newValue ?? 0;
                                  newValue = _clamp(next);
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      Gaps.w8,
                      SizedBox(
                        height: 32,
                        child: Button(
                          onPressed: controlsEnabled
                              ? () => setState(() => newValue = kEdenMax)
                              : null,
                          child: Text(loc.eden_btn_set_max(kEdenMax)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // 에디션 안내
            if (edition == IsaacEdition.rebirth)
              InfoBar(
                key: const ValueKey('rebirth_warning_notice'),
                title: Text(loc.common_notice),
                content: Text(loc.eden_info_rebirth_unsupported),
                severity: InfoBarSeverity.info,
              ),


            // 내부 경고(문구는 사용성 위주로)
            if (warningText != null && warningText.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: InfoBar(
                  key: const ValueKey('warning_notice'),
                  title: Text(loc.common_notice),
                  content: Text(warningText),
                  severity: InfoBarSeverity.warning,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // === 상태별 렌더링 ===
    return asyncState.when(
      // 로딩: 동일한 레이아웃(컨트롤 비활성화) 유지
      loading: () {
        return ContentDialog(
          key: const ValueKey('eden_dialog'),
          title: titleRow(loc.eden_title),
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 580),
          content: buildDialogContent(
            edition: widget.args.edition,
            slots: widget.args.slots,
            selectedSlot: widget.args.initialSlot,
            isLoading: true,
            isSaving: false,
            currentValue: null,
            warningText: null,
          ),
          actions: [
            Button(
              child: Text(loc.common_close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              key: const ValueKey('save_button'),
              onPressed: null, // 로딩 중 비활성화
              child: Text(loc.common_save),
            ),
          ],
        );
      },

      // 에러: 레이아웃은 단순화
      error: (_, __) {
        return ContentDialog(
          key: const ValueKey('eden_dialog'),
          title: titleRow(loc.eden_title),
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 580),
          content: InfoBar(
            key: const ValueKey('error_notice'),
            title: Text(loc.common_error),
            content: Text(loc.eden_err_generic),
            severity: InfoBarSeverity.error,
          ),
          actions: [
            Button(
              child: Text(loc.common_close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },

      // 데이터 로딩 완료
      data: (s) {
        newValue ??= s.currentValue ?? 0;

        final body = buildDialogContent(
          edition: s.edition,
          slots: s.slots,
          selectedSlot: s.selectedSlot == 0 ? widget.args.initialSlot : s.selectedSlot,
          isLoading: s.loading,
          isSaving: s.saving,
          currentValue: s.currentValue,
          warningText: (s.error != null) ? loc.eden_warn_read_failed : null,
        );

        final canSave = s.edition != IsaacEdition.rebirth &&
            !s.loading &&
            !s.saving &&
            s.selectedSlot != 0;

        return ContentDialog(
          key: const ValueKey('eden_dialog'),
          title: titleRow(loc.eden_title),
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 580),
          content: body,
          actions: [
            Button(
              child: Text(loc.common_close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              key: const ValueKey('save_button'),
              onPressed: canSave
                  ? () async {
                await ref
                    .read(edenEditorControllerProvider(widget.args).notifier)
                    .save(_clamp(newValue!));

                final after = ref.read(edenEditorControllerProvider(widget.args)).value;
                if (after?.error == null && context.mounted) {
                  UiFeedback.success(
                    context,
                    loc.eden_saved_title,
                    loc.eden_saved_desc,
                  );
                  setState(() => newValue = after?.currentValue ?? newValue);
                } else if (context.mounted) {
                  UiFeedback.error(context, loc.common_error, loc.eden_err_generic);
                }
              }
                  : null,
              child: s.saving ? const ProgressRing() : Text(loc.common_save),
            ),
          ],
        );
      },
    );
  }
}

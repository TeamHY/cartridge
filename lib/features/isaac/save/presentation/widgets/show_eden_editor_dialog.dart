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

  // 1) 계정 선택
  List<SteamAccountProfile> accounts;
  try {
    accounts = await ref.read(steamAccountsProvider.future);
  } catch (_) {
    if (context.mounted) {
      UiFeedback.error(context, content: loc.eden_err_accounts_desc);
    }
    return;
  }
  if (accounts.isEmpty) {
    if (context.mounted) {
      UiFeedback.warn(
        context,
        title: loc.eden_warn_no_accounts_title,
        content: loc.eden_warn_no_accounts_desc,
      );
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
      UiFeedback.warn(context, content: loc.eden_warn_no_saves_desc);
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
  bool _errorNotified = false; // 에러 토스트/닫기 중복 방지

  int _clamp(int v) => v < 0 ? 0 : (v > kEdenMax ? kEdenMax : v);

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);
    final asyncState = ref.watch(edenEditorControllerProvider(widget.args));

    Row titleRow(String text, bool busy) => Row(
      children: [
        Icon(FluentIcons.pro_hockey, size: 18, color: fTheme.accentColor.normal),
        Gaps.w4,
        Text(text),
        if (busy) ...[
          Gaps.w8,
          const ProgressRing(),
        ]
      ],
    );

    // 공용 Dialog 컨텐츠(레이아웃 고정)
    Widget buildDialogContent({
      required IsaacEdition edition,
      required List<int> slots,
      required int selectedSlot,
      required bool isLoading,
      required bool isSaving,
      required int? currentValue,
      String? warningText, // 내부 경고(파일 읽기 실패 등)
    }) {
      final controlsEnabled = !isLoading && !isSaving && selectedSlot != 0;
      final effectiveValue = newValue ?? currentValue;

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

            // 슬롯 선택
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
                      height: _slotHeight,
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
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          backgroundColor: WidgetStateProperty.all(bgColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected) const Icon(FluentIcons.check_mark, size: 20),
                            if (selected) Gaps.w4,
                            Text(loc.eden_slot_label(slot), style: AppTypography.sectionTitle),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            Gaps.h16,

            // 값 카드
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
                          loc.eden_current_chip((currentValue?.toString() ?? '–')),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 입력부
                  Row(
                    children: [
                      Expanded(
                        child: IgnorePointer(
                          ignoring: !controlsEnabled,
                          child: Stack(
                            children: [
                              NumberBox(
                                value: effectiveValue,
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
                              Positioned.fill(
                                child: IgnorePointer(
                                  ignoring: true,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 90),
                                    curve: Curves.easeOut,
                                    color: FluentTheme.of(context)
                                        .resources
                                        .controlFillColorSecondary
                                        .withAlpha(
                                      controlsEnabled
                                          ? 0
                                          : (FluentTheme.of(context).brightness == Brightness.dark ? 90 : 70),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

            // 에디션 안내 (정보)
            if (edition == IsaacEdition.rebirth)
              _InlineNotice.info(text: loc.eden_info_rebirth_unsupported),

            // 내부 경고(예: 파일 읽기 실패)
            if (warningText != null && warningText.isNotEmpty) ...[
              Gaps.h8,
              _InlineNotice.warning(text: warningText),
            ],
          ],
        ),
      );
    }

    // === 상태별 렌더링 ===
    return asyncState.when(
      // 로딩
      loading: () {
        return ContentDialog(
          key: const ValueKey('eden_dialog'),
          title: titleRow(loc.eden_title, false),
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
              onPressed: null,
              child: Text(loc.common_save),
            ),
          ],
        );
      },

      // 에러: UiFeedback.error + 닫기
      error: (_, __) {
        if (!_errorNotified) {
          _errorNotified = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            UiFeedback.error(context, content: loc.eden_err_generic);
            Navigator.of(context).pop();
          });
        }
        return const SizedBox.shrink();
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
          title: titleRow(loc.eden_title, s.saving),
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
                  UiFeedback.success(context, content: loc.eden_saved_desc);
                  setState(() => newValue = after?.currentValue ?? newValue);
                } else if (context.mounted) {
                  // 저장 실패도 토스트로 알리고 닫기
                  UiFeedback.error(context, content: loc.eden_err_generic);
                  Navigator.of(context).pop();
                }
              }
                  : null,
              child: Text(loc.common_save),
            ),
          ],
        );
      },
    );
  }
}

/// 앱 톤에 맞춘 인라인 안내(Info/Warning만 사용)
class _InlineNotice extends StatelessWidget {
  final String text;
  final _InlineNoticeType type;
  const _InlineNotice._(this.text, this.type);

  factory _InlineNotice.info({required String text}) =>
      _InlineNotice._(text, _InlineNoticeType.info);

  factory _InlineNotice.warning({required String text}) =>
      _InlineNotice._(text, _InlineNoticeType.warning);

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final (icon, color) = switch (type) {
      _InlineNoticeType.info =>
      (FluentIcons.info, t.resources.textFillColorSecondary),
      _InlineNoticeType.warning =>
      (FluentIcons.warning, t.resources.textFillColorSecondary),
    };

    return Container(
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.dividerColor),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          Gaps.w8,
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _InlineNoticeType { info, warning }

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';

class EdenEditorArgs {
  final SteamAccountProfile account;
  final IsaacEdition edition;
  final List<int> slots;
  final int initialSlot; // slots.first 권장
  const EdenEditorArgs({
    required this.account,
    required this.edition,
    required this.slots,
    required this.initialSlot,
  });
}

class EdenEditorState {
  final SteamAccountProfile account;
  final IsaacEdition edition;
  final List<int> slots;
  final int selectedSlot;
  final int? currentValue;
  final bool loading;
  final bool saving;
  final String? error;

  const EdenEditorState({
    required this.account,
    required this.edition,
    required this.slots,
    required this.selectedSlot,
    this.currentValue,
    this.loading = false,
    this.saving = false,
    this.error,
  });

  EdenEditorState copyWith({
    int? selectedSlot,
    int? currentValue,
    bool? loading,
    bool? saving,
    String? error,
  }) {
    return EdenEditorState(
      account: account,
      edition: edition,
      slots: slots,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      currentValue: currentValue ?? this.currentValue,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: error,
    );
  }
}

final edenEditorControllerProvider = AutoDisposeAsyncNotifierProviderFamily<
    EdenEditorController, EdenEditorState, EdenEditorArgs>(EdenEditorController.new);

class EdenEditorController extends AutoDisposeFamilyAsyncNotifier<EdenEditorState, EdenEditorArgs> {
  @override
  Future<EdenEditorState> build(EdenEditorArgs args) async {
    // 첫 로드: 현재 슬롯 값 읽기
    final port = ref.read(edenTokensPortProvider);
    try {
      final v = await port.read(args.account, args.edition, args.initialSlot);
      return EdenEditorState(
        account: args.account,
        edition: args.edition,
        slots: args.slots,
        selectedSlot: args.initialSlot,
        currentValue: v,
        loading: false,
      );
    } catch (e) {
      return EdenEditorState(
        account: args.account,
        edition: args.edition,
        slots: args.slots,
        selectedSlot: args.initialSlot,
        currentValue: null,
        loading: false,
        error: '$e',
      );
    }
  }

  Future<void> selectSlot(int slot) async {
    final s = state.value;
    if (s == null || s.selectedSlot == slot) return;
    state = AsyncData(s.copyWith(loading: true, error: null));
    final port = ref.read(edenTokensPortProvider);
    try {
      final v = await port.read(s.account, s.edition, slot);
      state = AsyncData(s.copyWith(selectedSlot: slot, currentValue: v, loading: false, error: null));
    } catch (e) {
      state = AsyncData(s.copyWith(selectedSlot: slot, currentValue: null, loading: false, error: '$e'));
    }
  }

  Future<void> save(int value) async {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(saving: true, error: null));
    final port = ref.read(edenTokensPortProvider);
    try {
      await port.write(s.account, s.edition, s.selectedSlot, value, makeBackup: true);
      final v = await port.read(s.account, s.edition, s.selectedSlot);
      state = AsyncData(s.copyWith(currentValue: v, saving: false));
    } catch (e) {
      state = AsyncData(s.copyWith(saving: false, error: '$e'));
    }
  }
}

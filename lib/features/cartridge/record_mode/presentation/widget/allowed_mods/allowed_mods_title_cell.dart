import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/core/utils/workshop_util.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';
import 'package:cartridge/features/steam/steam.dart';
import 'package:cartridge/features/web_preview/web_preview.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class AllowedModTitleCell extends ConsumerWidget {
  const AllowedModTitleCell({super.key, required this.row});
  final AllowedModRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    // alwaysOn → 웹 프리뷰/링크 불필요
    if (row.alwaysOn) {
      final stub = _stub(row, displayName: row.name, wid: '');
      return Row(
        children: [
          Expanded(
            child: ModTitleCell(
              row: stub,
              displayName: row.name,
              showVersionUnderTitle: false,
              onTapTitle: null, // 링크 금지
              placeholderFallback: 'M',
              prewarmPreview: false,
            ),
          ),
          Gaps.w6,
          Tooltip(
            message: loc.allowed_always_on_tooltip,
            child: const Icon(FluentIcons.lock_solid, size: 14),
          ),
        ],
      );
    }

    // 일반 모드: 웹 제목/프리뷰 사용 가능
    final wid = row.workshopId ?? '';
    final url = wid.isEmpty ? null : SteamUrls.workshopItem(wid);
    final name = () {
      if (url == null) return row.name;
      final previewAsync = ref.watch(webPreviewProvider(url));
      final title = previewAsync.maybeWhen(data: (p) => p?.title, orElse: () => null);
      final fromWeb = extractWorkshopModName(title);
      return (fromWeb != null && fromWeb.isNotEmpty) ? fromWeb : row.name;
    }();

    final stub = _stub(row, displayName: name, wid: wid);

    Future<void> open() async {
      final links = ref.read(isaacSteamLinksProvider);
      if (wid.isNotEmpty) {
        await links.openIsaacWorkshopItem(wid);
      } else {
        final q = name.isNotEmpty ? name : row.name;
        final searchUrl = SteamUrls.workshopSearch(appId: IsaacSteamIds.appId, searchText: q);
        await links.openWebUrl(searchUrl);
      }
    }

    return ModTitleCell(
      row: stub,
      displayName: name,
      showVersionUnderTitle: false,
      onTapTitle: open,
      placeholderFallback: 'M',
      prewarmPreview: true,
    );
  }

  ModView _stub(AllowedModRow r, {required String displayName, required String wid}) {
    return ModView(
      id: wid.isNotEmpty ? 'allowed_$wid' : 'allowed_${r.name}',
      isInstalled: r.installed == true,
      explicitEnabled: r.enabled == true,
      effectiveEnabled: r.enabled == true,
      favorite: false,
      displayName: displayName,
      installedRef: (r.installed == true)
          ? InstalledMod(
        metadata: ModMetadata(
          id: wid,
          name: r.name,
          directory: '',
          version: '',
          visibility: ModVisibility.unknown,
          tags: const <String>[],
        ),
        disabled: !(r.enabled == true),
        installPath: '',
      )
          : null,
      status: ModRowStatus.ok,
      enabledByPresets: const {},
      updatedAt: DateTime.now(),
    );
  }
}

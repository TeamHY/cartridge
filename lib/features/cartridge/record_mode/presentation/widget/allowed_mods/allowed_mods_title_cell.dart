import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';
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
  const AllowedModTitleCell({
    super.key,
    required this.row,
    this.version = '',
  });

  final AllowedModRow row;
  final String version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    // alwaysOn → 웹 프리뷰/링크 불필요
    if (row.alwaysOn) {
      final stub = _stub(row, displayName: row.name, wid: '', version: version);

      // 버전 컬럼이 숨김이고 타일/컴포트 밀도이면 제목 아래에 버전 표시
      final vis     = UTColumnVisibility.of(context);
      final tTheme  = UTTableTheme.of(context);
      final density = tTheme.density;
      final versionVisible = vis?.isVisible('version') ?? true;
      final showVersionUnderTitle = (density == UTTableDensity.tile || density == UTTableDensity.comfortable) && !versionVisible;

      return Row(
        children: [
          Expanded(
            child: ModTitleCell(
              row: stub,
              displayName: row.name,
              showVersionUnderTitle: showVersionUnderTitle,
              isNarrowVersion: !versionVisible,
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
    // ── 여기서도 캐시 프리워밍/링크를 일관되게 걸어준다 (sourceId=워크샵ID로 통일)
    if (url != null && wid.isNotEmpty) {
      final locale = Localizations.localeOf(context);
      final previewAsync = ref.read(webPreviewProvider(url));
      final preview = previewAsync.maybeWhen(data: (p) => p, orElse: () => null);
      final need = preview == null ||
                   preview.title.trim().isEmpty ||
                   (preview.imagePath == null || preview.imagePath!.isEmpty);

      if (need) {
        // 캐시 프리워밍 + 링크 보장
        // - policy: 적당한 TTL (UI 변동 잦지 않게 72h)
        // - sourceId: wid로 통일
        // - acceptLanguage: 타이틀은 언어 영향 → 분리 캐시/재검증 유도
        unawaited(ref.read(webPreviewCacheProvider).getOrFetch(
          url,
          policy: const RefreshPolicy.ttl(Duration(hours: 72)),
          source: 'workshop_mod',
          sourceId: wid,
          targetMaxWidth: 128,
          targetMaxHeight: 128,
          acceptLanguage: locale.languageCode,
        ));
      } else {
        // 이미 캐시가 충분하다면, 그래도 링크는 보장되도록 한 번 더 걸어준다.
        // (getOrFetch를 호출하지 않고 직접 link만 보장해도 됨)
        unawaited(ref.read(webPreviewRepoProvider).link('workshop_mod', wid, url));
      }
    }

    final name = () {
      if (url == null) return row.name;
      final previewAsync = ref.watch(webPreviewProvider(url));
      final title = previewAsync.maybeWhen(data: (p) => p?.title, orElse: () => null);
      final fromWeb = extractWorkshopModName(title);
      return (fromWeb != null && fromWeb.isNotEmpty) ? fromWeb : row.name;
    }();

    final stub = _stub(row, displayName: name, wid: wid, version: version);

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

    final vis     = UTColumnVisibility.of(context);
    final tTheme  = UTTableTheme.of(context);
    final density = tTheme.density;
    final versionVisible = vis?.isVisible('version') ?? true;
    final showVersionUnderTitle = (density == UTTableDensity.tile || density == UTTableDensity.comfortable) && !versionVisible;

    return ModTitleCell(
      row: stub,
      displayName: name,
      showVersionUnderTitle: showVersionUnderTitle,
      isNarrowVersion: !versionVisible,
      onTapTitle: open,
      placeholderFallback: 'M',
      prewarmPreview: true,
    );
  }

  ModView _stub(AllowedModRow r, {required String displayName, required String wid, required String version}) {
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
          version: version, // ← 설치 버전 주입
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

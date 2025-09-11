import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:cartridge/features/steam/domain/steam_app_urls.dart';
import 'package:cartridge/features/steam/domain/steam_link_builder.dart';

/// 공유용 아이템(최소 정보)
class ShareItem {
  final String name;
  final String? workshopId; // 없을 수 있음
  const ShareItem({required this.name, this.workshopId});
}

/// 공유 클립보드 유틸리티.
class ClipboardShare {
  /// 이름 리스트를 Plain + HTML로 복사한다.
  /// - HTML은 `<ul><li>` 형태, 링크는 Steam 클라이언트 우선 URL 사용
  static Future<void> copyNamesRich(List<ShareItem> items) async {
    final safeItems = items.where((e) => e.name.trim().isNotEmpty).toList(growable: false);
    final plain = safeItems.map((e) => e.name).join('\n');

    String escapeHtml(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');

    final entries = safeItems.map((e) {
      final name = escapeHtml(e.name);
      final id = (e.workshopId ?? '').trim();
      if (id.isNotEmpty) {
        final url = SteamLinkBuilder.preferSteamClientIfPossible(
          SteamUrls.workshopItem(id),
        );
        var buffer = StringBuffer();
        buffer.write('<li><a href="');
        buffer.write(url);
        buffer.write('">');
        buffer.write(name);
        buffer.write('</a></li>');
        return buffer.toString();
      }
      return '<li>$name</li>';
    }).join();

    final html = '<!DOCTYPE html><html><head><meta charset="utf-8"></head>'
        '<body><ul>$entries</ul></body></html>';

    try {
      final cb = SystemClipboard.instance;
      if (cb == null) {
        await Clipboard.setData(ClipboardData(text: plain));
        return;
      }
      final item = DataWriterItem()
        ..add(Formats.htmlText(html))
        ..add(Formats.plainText(plain));
      await cb.write([item]);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: plain));
    }
  }


  static Future<void> copyNamesPlain(List<ShareItem> items) async {
    final text = items
        .where((e) => e.name.trim().isNotEmpty)
        .map((e) => e.name)
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> copyNamesMarkdown(List<ShareItem> items, {bool asList = true}) async {
    String mdEsc(String s) =>
        s.replaceAllMapped(RegExp(r'([\\`*_{}\[\]()+\-!.#|>])'), (m) => '\\${m[1]}');

    final lines = <String>[];
    for (final e in items.where((x) => x.name.trim().isNotEmpty)) {
      final name = mdEsc(e.name);
      final id = (e.workshopId ?? '').trim();
      final bullet = asList ? '- ' : '';
      if (id.isNotEmpty) {
        final url = SteamUrls.workshopItem(id); // markdown에선 https 권장
        lines.add('$bullet[$name]($url)');
      } else {
        lines.add('$bullet$name');
      }
    }
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
  }
}

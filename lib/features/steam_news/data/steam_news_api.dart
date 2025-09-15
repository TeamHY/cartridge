// lib/features/steam_news/data/steam_news_api.dart

import 'dart:convert';
import 'dart:io';

import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';
import 'package:cartridge/features/steam_news/steam_news.dart';

class SteamNewsApi {
  static const _tag = 'SteamNewsApi';

  final Uri Function(int appId, int count, int maxLength) _buildUri;
  final HttpClient Function() _httpClientFactory;

  SteamNewsApi({
    Uri Function(int appId, int count, int maxLength)? buildUri,
    HttpClient Function()? httpClientFactory,
  })  : _buildUri = buildUri ??
      ((appId, count, maxLength) => Uri.parse(
        'https://api.steampowered.com/ISteamNews/GetNewsForApp/v0002/'
            '?appid=$appId&count=$count&maxlength=$maxLength',
      )),
        _httpClientFactory = httpClientFactory ?? (() => HttpClient());

  Future<List<SteamNewsItem>> fetch({
    int appId = IsaacSteamIds.appId,
    int count = SteamNewsDefaults.count,
    int maxLength = SteamNewsDefaults.maxLength,
  }) async {
    final uri = _buildUri(appId, count, maxLength);

    try {
      final client = _httpClientFactory();
      final res = await (await client.getUrl(uri)).close();
      if (res.statusCode != 200) return const [];
      final body = await res.transform(utf8.decoder).join();
      final map = jsonDecode(body) as Map<String, dynamic>;
      final items =
          ((map['appnews'] as Map<String, dynamic>?)?['newsitems'] as List?) ??
              const [];

      return items.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return SteamNewsItem(
          title: (m['title'] as String?) ?? '',
          url: (m['url'] as String?) ?? '',
          contents: (m['contents'] as String?)?.trim() ?? '',
          epochSec: (m['date'] is int) ? (m['date'] as int) : null,
        );
      }).toList(growable: false);
    } catch (e, st) {
      logE(_tag, 'fetch failed', e, st);
      return const [];
    }
  }
}

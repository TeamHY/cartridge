import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:cartridge/core/infra/file_io.dart';
import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/steam_news/steam_news.dart';


class SteamNewsState {
  final DateTime? lastFetch;
  final List<SteamNewsItem> items;
  const SteamNewsState({required this.lastFetch, required this.items});
  Map<String, dynamic> toJson() => {
    'lastFetch': lastFetch?.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
  };
  factory SteamNewsState.fromJson(Map<String, dynamic> m) {
    final last = (m['lastFetch'] as String?) != null
        ? DateTime.tryParse(m['lastFetch'] as String)
        : null;
    final raw = (m['items'] as List?) ?? const [];
    final items = raw
        .map((e) => SteamNewsItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    return SteamNewsState(lastFetch: last, items: items);
  }
  SteamNewsState copyWith({DateTime? lastFetch, List<SteamNewsItem>? items}) =>
      SteamNewsState(lastFetch: lastFetch ?? this.lastFetch, items: items ?? this.items);
}

class SteamNewsRepository {
  static const _tag = 'SteamNewsRepository';
  File? _file;

  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;

  Future<File> _ensureFile() async {
    if (_file != null) return _file!;
    final dir = await ensureAppSupportSubDir('cache');
    _file = File(p.join(dir.path, 'news.json'));
    return _file!;
  }

  Future<SteamNewsState> load() async {
    try {
      final f = await _ensureFile();
      if (!await f.exists()) {
        return const SteamNewsState(lastFetch: null, items: []);
      }
      final map = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return SteamNewsState.fromJson(map);
    } catch (e, st) {
      logE(_tag, 'load failed', e, st);
      return const SteamNewsState(lastFetch: null, items: []);
    }
  }

  Future<void> save(SteamNewsState state) async {
    try {
      final f = await _ensureFile();
      final limited = (state.items.length > SteamNewsDefaults.count)
          ? state.items.take(SteamNewsDefaults.count).toList(growable: false)
          : state.items;
      final jsonStr = const JsonEncoder.withIndent('  ')
          .convert(state.copyWith(items: limited).toJson());

      await writeBytes(f.path, utf8.encode(jsonStr), atomic: true, flush: true);
      _changes.add(null);
    } catch (e, st) {
      logE(_tag, 'save failed', e, st);
    }
  }
}
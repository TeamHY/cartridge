import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/features/web_preview/data/web_preview_repository.dart';
import 'package:cartridge/features/web_preview/application/web_preview_cache.dart';
import 'package:cartridge/features/web_preview/domain/web_preview.dart';

final webPreviewRepoProvider = Provider<WebPreviewRepository>((ref) {
  return WebPreviewRepository();
});

final webPreviewCacheProvider = Provider<WebPreviewCache>((ref) {
  return WebPreviewCache(ref.watch(webPreviewRepoProvider));
});

final webPreviewProvider =
StreamProvider.family<WebPreview?, String>((ref, url) async* {
  final repo = ref.watch(webPreviewRepoProvider);
  yield await repo.find(url);
  await for (final changedUrl in repo.changes.where((u) => u == url)) {
    yield await repo.find(changedUrl);
  }
});

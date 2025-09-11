import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:crypto/crypto.dart' as crypto;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'package:cartridge/core/log.dart';
import 'package:cartridge/core/utils/id.dart';
import 'package:cartridge/core/infra/file_io.dart' as fio;
import 'package:cartridge/features/web_preview/data/web_preview_repository.dart';
import 'package:cartridge/features/web_preview/domain/web_preview.dart';


enum SourcePolicy { immutable, ttl }

class RefreshPolicy {
  final SourcePolicy kind;
  final Duration? ttl;
  const RefreshPolicy._(this.kind, this.ttl);
  const RefreshPolicy.immutable() : this._(SourcePolicy.immutable, null);
  const RefreshPolicy.ttl(Duration ttl) : this._(SourcePolicy.ttl, ttl);
}

class WebPreviewCache {
  final WebPreviewRepository repo;
  final _inflight = <String, Future<WebPreview>>{};

  WebPreviewCache(this.repo);

  Future<Directory> _imagesDir() async {
    return fio.ensureAppSupportSubDir(p.join('cache', 'previews'));
  }
  /// 공통 진입점
  Future<WebPreview> getOrFetch(
      String url, {
        RefreshPolicy policy = const RefreshPolicy.ttl(Duration(hours: 24)),
        String? source,
        String? sourceId,
        bool forceRefresh = false,
        int? targetMaxWidth,
        int? targetMaxHeight,
        int jpegQuality = 85,
        String? acceptLanguage,
      }) {
    final op = IdUtil.genId('wpc');
    logI('WebPreviewCache',
        'op=$op fn=getOrFetch url=$url force=$forceRefresh policy=${policy.kind} ttl=${policy.ttl?.inMinutes}m');
    final inflightKey = acceptLanguage == null ? url : '$url|$acceptLanguage';

    return _inflight.putIfAbsent(inflightKey, () async {
      try {
        final cached = await repo.find(url);
        if (cached != null) {
          logI('WebPreviewCache',
              'op=$op fn=getOrFetch cache-hit url=$url expired=${cached.isExpired} status=${cached.statusCode}');
        }

        // immutable 이고 캐시가 있으면 그대로 반환
        if (!forceRefresh && cached != null && policy.kind == SourcePolicy.immutable) {
          if (source != null && sourceId != null) {
            await repo.link(source, sourceId, url);
          }
          return cached;
        }

        // ttl: 유효하면 그대로, 만료면 재검증
        if (!forceRefresh && cached != null && !cached.isExpired) {
          if (source != null && sourceId != null) {
            await repo.link(source, sourceId, url);
          }
          logI('WebPreviewCache', 'op=$op fn=getOrFetch return=ttl-valid url=$url');
          return cached;
        }

        final fresh = await _fetchAndUpsert(
          url,
          cached,
          policy,
          targetMaxWidth: targetMaxWidth,
          targetMaxHeight: targetMaxHeight,
          jpegQuality: jpegQuality,
          acceptLanguage: acceptLanguage,
          op: op,
        );
        if (source != null && sourceId != null) {
          await repo.link(source, sourceId, url);
        }
        logI('WebPreviewCache', 'op=$op fn=getOrFetch return=fresh url=$url path=${fresh.imagePath}');
        return fresh;
      } finally {
        _inflight.remove(inflightKey);
      }
    });
  }

  Future<WebPreview> _fetchAndUpsert(
      String url, WebPreview? prior, RefreshPolicy policy, {
        int? targetMaxWidth,
        int? targetMaxHeight,
        int jpegQuality = 85,
        String? acceptLanguage,
        required String op,
      }) async {
    final headers = <String, String>{
      'User-Agent': 'Cartridge/1.0 (+windows; flutter)',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    };
    if (acceptLanguage != null && acceptLanguage.isNotEmpty) {
      headers['Accept-Language'] = acceptLanguage;
    }
    if (prior?.etag != null) headers['If-None-Match'] = prior!.etag!;
    if (prior?.lastModified != null) headers['If-Modified-Since'] = prior!.lastModified!;

    logI('WebPreviewCache', 'op=$op fn=_fetchAndUpsert url=$url ifNoneMatch=${prior?.etag != null} ifModifiedSince=${prior?.lastModified != null}');

    final res = await http.get(Uri.parse(url), headers: headers);
    logI('WebPreviewCache', 'op=$op fn=_fetchAndUpsert url=$url status=${res.statusCode} len=${res.bodyBytes.length}');


    if (res.statusCode == 304 && prior != null) {
      // 변경 없음: fetchedAt/만료만 갱신
      final now = DateTime.now();
      final exp = _calcExpiry(res.headers, policy, now);
      final keep = WebPreview(
        url: prior.url,
        title: prior.title,
        imagePath: prior.imagePath,
        imageUrl: prior.imageUrl,
        mime: prior.mime,
        etag: prior.etag,
        lastModified: prior.lastModified,
        statusCode: 304,
        fetchedAt: now,
        expiresAt: exp,
        hash: prior.hash,
      );
      await repo.upsert(keep);
      logI('WebPreviewCache', 'op=$op fn=_fetchAndUpsert url=$url return=304-cache-keep');
      return keep;
    }

    if (res.statusCode >= 400) {
      // 실패: 만료로 간주하고 기존이 있으면 그걸 유지(안전)
      if (prior != null) {
        logW('WebPreviewCache', 'op=$op fn=_fetchAndUpsert url=$url return=prior status=${res.statusCode}');
        return prior;
      }
      // 없으면 최소 스텁 저장
      final now = DateTime.now();
      final stub = WebPreview(
        url: url,
        title: '',
        imagePath: null,
        imageUrl: null,
        mime: res.headers['content-type'],
        etag: res.headers['etag'],
        lastModified: res.headers['last-modified'],
        statusCode: res.statusCode,
        fetchedAt: now,
        expiresAt: now.add(const Duration(hours: 1)),
        hash: null,
      );
      await repo.upsert(stub);
      logW('WebPreviewCache', 'op=$op fn=_fetchAndUpsert url=$url return=stub status=${res.statusCode}');
      return stub;
    }

    // 200 OK: HTML 파싱
    final htmlDoc = html.parse(utf8.decode(res.bodyBytes, allowMalformed: true));
    final title = _extractTitle(htmlDoc) ?? prior?.title ?? '';
    final imgUrl = _extractImageUrl(htmlDoc);
    logI('WebPreviewCache', 'op=$op fn=_fetchAndUpsert url=$url parsed title.len=${title.length} imgUrl=${imgUrl ?? 'null'}');

    String? imagePath;
    String? hash;
    String? mime;

    if (imgUrl != null) {
      try {
        final saved = await _downloadImage(
          imgUrl,
          maxWidth: targetMaxWidth,
          maxHeight: targetMaxHeight,
          jpegQuality: jpegQuality,
          op: op,
          pageUrl: url,
        );
        if (saved.$1.isEmpty) {
          imagePath = prior?.imagePath;
          hash = prior?.hash;
          mime = prior?.mime;
        } else {
          imagePath = saved.$1;
          hash = saved.$2;
          mime = saved.$3;
        }
        logI('WebPreviewCache', 'op=$op fn=_fetchAndUpsert url=$url saved path=$imagePath mime=$mime hash=${hash ?? 'null'}');
      } catch (e, st) {
        logE('WebPreviewCache', 'op=$op fn=_fetchAndUpsert url=$url msg=downloadImage failed', e, st);
        imagePath = prior?.imagePath;
        hash = prior?.hash;
        mime = prior?.mime;
      }
    } else {
      imagePath = prior?.imagePath;
      hash = prior?.hash;
      mime = prior?.mime;
    }

    final now = DateTime.now();
    final fresh = WebPreview(
      url: url,
      title: title,
      imagePath: imagePath,
      imageUrl: imgUrl ?? prior?.imageUrl,
      mime: mime ?? res.headers['content-type'],
      etag: res.headers['etag'],
      lastModified: res.headers['last-modified'],
      statusCode: 200,
      fetchedAt: now,
      expiresAt: _calcExpiry(res.headers, policy, now),
      hash: hash,
    );
    await repo.upsert(fresh);
    return fresh;
  }

  Uri _resolveAsset(String pageUrl, String asset) {
    final u = Uri.parse(asset);
    if (u.hasScheme) return u;
    return Uri.parse(pageUrl).resolve(asset);
  }

  Future<(String path, String? hash, String? mime)> _downloadImage(
      String url, {
        int? maxWidth,
        int? maxHeight,
        int jpegQuality = 85,
        required String op,
        required String pageUrl,
      }) async {
    final resolved = _resolveAsset(pageUrl, url);
    logI('WebPreviewCache', 'op=$op fn=_downloadImage page=$pageUrl imgReq=$resolved (raw=$url)');
    final res = await http.get(resolved, headers: {
      'User-Agent': 'Cartridge/1.0 (+windows; flutter)',
    });
    if (res.statusCode != 200) {
      logW('WebPreviewCache', 'op=$op fn=_downloadImage status=${res.statusCode} url=$url');
      return ('', null, null);
    }

    final srcMime = res.headers['content-type'] ?? 'image/jpeg';
    final decoded = img.decodeImage(res.bodyBytes);
    if (decoded == null) {
      logW('WebPreviewCache', 'op=$op fn=_downloadImage msg=decodeImage null url=$url mime=$srcMime');
      return ('', null, null);
    }


    int ow = decoded.width, oh = decoded.height;
    int tw = ow, th = oh;
    if (maxWidth != null || maxHeight != null) {
      final mw = maxWidth ?? ow;
      final mh = maxHeight ?? oh;
      final scale = math.min(mw / ow, mh / oh);
      if (scale < 1.0) {
        tw = (ow * scale).round();
        th = (oh * scale).round();
      }
    }
    logI('WebPreviewCache', 'op=$op fn=_downloadImage size=${ow}x$oh -> ${tw}x$th target=${maxWidth ?? '-'}x${maxHeight ?? '-'}');

    final resized = (tw != ow || th != oh)
        ? img.copyResize(decoded, width: tw, height: th)
        : decoded;

    // PNG/WebP로 온 건 PNG 유지(투명도 보존), 그 외는 JPG로 용량 절약
    final preferPng = srcMime.contains('png') || srcMime.contains('webp');
    final outBytes = preferPng
        ? img.encodePng(resized)                       // 투명도 보존
        : img.encodeJpg(resized, quality: jpegQuality); // 용량↓
    final outMime = preferPng ? 'image/png' : 'image/jpeg';

    final sha = crypto.sha1.convert(outBytes).toString();

    final dir = await _imagesDir();
    final ext = preferPng ? '.png' : '.jpg';
    final fullPath = p.join(dir.path, '$sha$ext');
    await fio.writeBytes(fullPath, outBytes, atomic: true, flush: true);

    logI('WebPreviewCache', 'op=$op fn=_downloadImage saved=$fullPath bytes=${outBytes.length} outMime=$outMime');
    return (fullPath, sha, outMime);
  }

  String? _extractTitle(dynamic doc) {
    final og = doc.querySelector('meta[property="og:title"]')?.attributes['content'];
    if (og != null && og.trim().isNotEmpty) return og.trim();
    final tw = doc.querySelector('meta[name="twitter:title"]')?.attributes['content'];
    if (tw != null && tw.trim().isNotEmpty) return tw.trim();
    final t = doc.querySelector('title')?.text;
    if (t != null && t.trim().isNotEmpty) return t.trim();
    return null;
  }

  String? _extractImageUrl(dynamic doc) {
    final og = doc.querySelector('meta[property="og:image"]')?.attributes['content'];
    if (og != null && og.trim().isNotEmpty) return og.trim();
    final tw = doc.querySelector('meta[name="twitter:image"]')?.attributes['content'];
    if (tw != null && tw.trim().isNotEmpty) return tw.trim();
    final firstImg = doc.querySelector('img')?.attributes['src'];
    return (firstImg != null && firstImg.trim().isNotEmpty) ? firstImg.trim() : null;
  }

  DateTime? _calcExpiry(Map<String, String> headers, RefreshPolicy policy, DateTime now) {
    switch (policy.kind) {
      case SourcePolicy.immutable:
        return null; // 만료 없음(필요 시 강제 재검증)
      case SourcePolicy.ttl:
        final cc = headers['cache-control'];
        if (cc != null) {
          final m = RegExp(r'max-age=(\d+)').firstMatch(cc);
          if (m != null) {
            final sec = int.tryParse(m.group(1)!);
            if (sec != null) return now.add(Duration(seconds: sec));
          }
        }
        // 간단 처리: 서버 expires 무시하고 고정 TTL 사용
        // `final exp = headers['expires'];`

        return now.add(policy.ttl!);
    }
  }

  // 관리 유틸
  Future<void> evictLink(String source, String sourceId) async {
    await repo.unlink(source, sourceId);
    await repo.sweepOrphans();
  }

  Future<void> sweep() async {
    await repo.deleteExpired();
    await repo.sweepOrphans();

    // 파일 GC
    final keepRaw = await repo.allImagePaths();
    final keep = keepRaw.map((e) => p.normalize(e)).toSet();

    final dir = await _imagesDir();
    if (await dir.exists()) {
      await for (final ent in fio.listFiles(dir)) {
        final path = p.normalize(ent.path);
        if (!keep.contains(path)) {
          try { await fio.deleteFileIfExists(path); } catch (_) {}
        }
      }
    }
  }
}

import 'dart:async';
import 'dart:io';

import 'package:cartridge/core/infra/cache_database.dart' show kCacheDbFile;
import 'package:cartridge/core/infra/file_io.dart' as fio;
import 'package:cartridge/core/infra/sqlite_database.dart';
import 'package:cartridge/features/web_preview/data/web_preview_repository.dart';
import 'package:cartridge/features/web_preview/application/web_preview_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


void main() {
  late Directory tmpDir;
  late HttpServer server;
  late _FakeSite site;
  late WebPreviewRepository repo;
  late WebPreviewCache cache;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // 앱 지원 디렉터리를 테스트용 임시 폴더로 바꾸기
    tmpDir = await Directory.systemTemp.createTemp('wpc_test_');
    fio.setAppSupportDirProvider(() async => tmpDir);

    // 캐시 DB 생성
    repo = WebPreviewRepository();
    cache = WebPreviewCache(repo);

    // 로컬 HTTP 서버 준비
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    site = _FakeSite(server);
    unawaited(site.serve());
  });

  tearDown(() async {
    await server.close(force: true);
    await closeAppDatabase(kCacheDbFile);
    await deleteAppDatabase(kCacheDbFile);
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  String urlOf(String id) => 'http://127.0.0.1:${server.port}/page/$id';

  group('WebPreviewCache', () {
    test('첫 fetch: DB/이미지 저장 & ttl-valid 경로는 네트워크 재호출 없이 반환', () async {
      // 페이지 1: cache-control: max-age=60, og:image=/img/1.png
      site.addPage(
        id: '1',
        title: 'Title-1',
        imagePath: '/img/1.png',
        headers: {'cache-control': 'max-age=60', 'etag': 'W/"etag-1"', 'last-modified': _lm},
      );
      site.addImage(id: '1'); // 1x1 PNG

      final url = urlOf('1');

      // 1) 최초 fetch
      final p1 = await cache.getOrFetch(
        url,
        policy: const RefreshPolicy.ttl(Duration(hours: 24)),
        source: 'workshop_mod',
        sourceId: '1',
        targetMaxWidth: 64,
        targetMaxHeight: 64,
        jpegQuality: 85,
      );
      expect(p1.url, url);
      expect(p1.title, 'Title-1');
      expect(p1.imagePath, isNotNull);
      expect(File(p1.imagePath!).existsSync(), isTrue);

      // 서버 호출 카운터: 페이지+이미지 각 1회
      expect(site.pageHits['1'], 1);
      expect(site.imageHits['1'], 1);

      // 2) 캐시 유효: 같은 호출 → 네트워크 호출 증가 없어야 함
      final p2 = await cache.getOrFetch(
        url,
        policy: const RefreshPolicy.ttl(Duration(hours: 24)),
        source: 'workshop_mod',
        sourceId: '1',
      );
      expect(p2.url, url);
      expect(site.pageHits['1'], 1, reason: 'ttl-valid면 페이지 재요청 안함');
      expect(site.imageHits['1'], 1, reason: '이미지도 재다운 안함');

      // 링크 저장 확인
      final links = await repo.allUrlsFor('workshop_mod');
      expect(links, contains(url));
    });

    test('만료 후 재검증: 304 응답 시 fetchedAt/expiry 갱신 & 이미지 재다운로드 안함', () async {
      // 페이지 2: cache-control 헤더 없음(정책 TTL 사용), ETag/Last-Modified 제공
      site.addPage(
        id: '2',
        title: 'Title-2',
        imagePath: '/img/2.png',
        headers: {'etag': 'W/"etag-2"', 'last-modified': _lm},
      );
      site.addImage(id: '2');

      final url = urlOf('2');

      // 1) 매우 짧은 TTL로 저장
      final p1 = await cache.getOrFetch(
        url,
        policy: const RefreshPolicy.ttl(Duration(milliseconds: 1)),
        source: 'workshop_mod',
        sourceId: '2',
      );
      expect(p1.statusCode, anyOf(200, isNull));

      // 잠깐 대기 → 만료 상태 유도
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 2) 두번째 호출: If-None-Match로 304 유도 + Cache-Control 새로 부여
      site.page304OnEtag['2'] = true;
      site.extra304Headers = {'cache-control': 'max-age=10'};
      final before = p1.fetchedAt;

      final p2 = await cache.getOrFetch(
        url,
        policy: const RefreshPolicy.ttl(Duration(seconds: 1)), // 304의 max-age 적용됨
      );

      expect(p2.statusCode, 304);
      expect(p2.fetchedAt.isAfter(before), isTrue);
      // 이미지 요청 카운터 증가 없어야 함
      expect(site.imageHits['2'], 1);
      expect(site.pageHits['2'], 2);
    });

    test('immutable 정책: 캐시가 있으면 무조건 캐시 반환(네트워크 미호출)', () async {
      site.addPage(
        id: '3',
        title: 'Title-3',
        imagePath: '/img/3.png',
        headers: {'etag': 'W/"etag-3"', 'last-modified': _lm},
      );
      site.addImage(id: '3');

      final url = urlOf('3');

      // 최초 저장
      await cache.getOrFetch(url, policy: const RefreshPolicy.ttl(Duration(minutes: 1)));
      expect(site.pageHits['3'], 1);
      expect(site.imageHits['3'], 1);

      // immutable + forceRefresh=false → 캐시 반환, 카운터 변화 없음
      final p2 = await cache.getOrFetch(url, policy: const RefreshPolicy.immutable());
      expect(p2.url, url);
      expect(site.pageHits['3'], 1);
      expect(site.imageHits['3'], 1);
    });

    test('이미지 404: imagePath는 null 유지', () async {
      // og:image가 404를 반환하게 함
      site.addPage(
        id: 'noimg',
        title: 'Title-NOIMG',
        imagePath: '/img/404.png',
        headers: {'cache-control': 'max-age=60'},
      );
      site.addImage404(path: '/img/404.png');

      final url = urlOf('noimg');
      final p = await cache.getOrFetch(url, policy: const RefreshPolicy.ttl(Duration(minutes: 5)));
      expect(p.title, 'Title-NOIMG');
      expect(p.imagePath, isNull);
      expect(site.pageHits['noimg'], 1);
    });

    test('evictLink(): 링크 제거 + 참조 없는 preview 삭제', () async {
      site.addPage(
        id: '4',
        title: 'Title-4',
        imagePath: '/img/4.png',
      );
      site.addImage(id: '4');

      final url = urlOf('4');

      await cache.getOrFetch(
        url,
        policy: const RefreshPolicy.ttl(Duration(minutes: 5)),
        source: 'workshop_mod',
        sourceId: '4',
      );
      var links = await repo.allUrlsFor('workshop_mod');
      expect(links, contains(url));

      await cache.evictLink('workshop_mod', '4');

      links = await repo.allUrlsFor('workshop_mod');
      expect(links, isNot(contains(url)));

      // 참조가 없으면 web_previews에서도 제거되어야 함
      final remain = await repo.find(url);
      expect(remain, isNull);
    });
  });
}

/// 간단한 가짜 사이트/이미지 서버
class _FakeSite {
  final HttpServer server;
  _FakeSite(this.server);

  // 설정
  final Map<String, Map<String, String>> _pageHeaders = {};
  final Map<String, String> _pageImg = {};
  final Map<String, String> _pageTitle = {};
  final Set<String> _image404 = {};
  Map<String, String> extra304Headers = {};

  // 카운터
  final Map<String, int> pageHits = {};
  final Map<String, int> imageHits = {};

  // 해당 id에 대해 If-None-Match 맞으면 304 반환
  final Map<String, bool> page304OnEtag = {};

  void addPage({
    required String id,
    required String title,
    String? imagePath,
    Map<String, String> headers = const {},
  }) {
    _pageImg[id] = imagePath ?? '/img/$id.png';
    _pageHeaders[id] = Map.of(headers);
    _pageTitle[id] = title;
  }

  void addImage({required String id, int w = 1, int h = 1}) {
    final bytes = img.encodePng(img.Image(width: w, height: h));
    _imageStore['/img/$id.png'] = _Img(bytes, 'image/png');
  }

  void addImage404({required String path}) {
    _image404.add(path);
  }

  final Map<String, _Img> _imageStore = {};

  Future<void> serve() async {
    await for (final req in server) {
      final uri = req.uri.path;

      if (uri.startsWith('/page/')) {
        final id = uri.split('/').last;
        pageHits[id] = (pageHits[id] ?? 0) + 1;

        final headers = _pageHeaders[id] ?? {};
        final etag = headers['etag'];
        final lmod = headers['last-modified'];
        final pageTitle = _pageTitle[id] ?? 'Title-$id';

        // 304 조건
        final inm = req.headers.value(HttpHeaders.ifNoneMatchHeader);
        final ims = req.headers.value(HttpHeaders.ifModifiedSinceHeader);
        final wants304 = page304OnEtag[id] == true &&
            ((etag != null && inm == etag) || (lmod != null && ims == lmod));

        if (wants304) {
          final res = req.response
            ..statusCode = HttpStatus.notModified
            ..headers.set(HttpHeaders.contentTypeHeader, 'text/html; charset=utf-8');
          for (final e in extra304Headers.entries) {
            res.headers.set(e.key, e.value);
          }
          await res.close();
          continue;
        }

        final imgPath = _pageImg[id] ?? '/img/$id.png';
        final html = '''
<!doctype html><html><head>
<meta property="og:title" content="$pageTitle">
<meta property="og:image" content="$imgPath">
<title>$pageTitle</title>
</head><body>ok</body></html>''';

        final res = req.response
          ..statusCode = 200
          ..headers.set(HttpHeaders.contentTypeHeader, 'text/html; charset=utf-8');
        for (final e in headers.entries) {
          res.headers.set(e.key, e.value);
        }
        res.write(html);
        await res.close();
        continue;
      }

      if (uri.startsWith('/img/')) {
        if (_image404.contains(uri)) {
          req.response.statusCode = 404;
          await req.response.close();
          continue;
        }
        final fileName = uri.split('/').last;
        final dot = fileName.indexOf('.');
        final idKey = dot >= 0 ? fileName.substring(0, dot) : fileName;
        imageHits[idKey] = (imageHits[idKey] ?? 0) + 1;
        final v = _imageStore[uri];
        if (v == null) {
          req.response.statusCode = 404;
          await req.response.close();
          continue;
        }
        final res = req.response
          ..statusCode = 200
          ..headers.set(HttpHeaders.contentTypeHeader, v.mime)
          ..add(v.bytes);
        await res.close();
        continue;
      }

      req.response.statusCode = 404;
      await req.response.close();
    }
  }
}

class _Img {
  final List<int> bytes;
  final String mime;
  _Img(this.bytes, this.mime);
}

const _lm = 'Wed, 01 Jan 2030 00:00:00 GMT';

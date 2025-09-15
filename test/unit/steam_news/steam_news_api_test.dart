// test/unit/steam_news/steam_news_api_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/features/steam_news/data/steam_news_api.dart';
import 'package:cartridge/features/steam_news/steam_news.dart';

void main() {
  late HttpServer server;
  late _FakeSteamNewsEndpoint fake;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    fake = _FakeSteamNewsEndpoint(server);
    unawaited(fake.serve());
  });

  tearDown(() async {
    await server.close(force: true);
  });

  // buildUri 를 로컬 서버로 향하게 주입
  Uri localUri(int appId, int count, int maxLength) =>
      Uri.parse('http://127.0.0.1:${server.port}/ISteamNews/GetNewsForApp/v0002/'
          '?appid=$appId&count=$count&maxlength=$maxLength');

  test('200 OK: 아이템 파싱 (title/url/contents trim/epochSec)', () async {
    fake.respondWith(
      status: 200,
      jsonBody: {
        'appnews': {
          'newsitems': [
            {
              'title': 'A',
              'url': 'https://x/1',
              'contents': '  hello  \n',
              'date': 1700000000,
            },
            {
              'title': 'B',
              'url': 'https://x/2',
              'contents': 'bye',
              'date': 0,
            },
          ]
        }
      },
    );

    final api = SteamNewsApi(buildUri: localUri);
    final list = await api.fetch(appId: 250900, count: 3, maxLength: 120);

    expect(list.length, 2);
    expect(list[0].title, 'A');
    expect(list[0].url, 'https://x/1');
    expect(list[0].contents, 'hello'); // trim 확인
    expect(list[0].epochSec, 1700000000);
    expect(
      list[0].date,
      DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000),
    );

    // 쿼리 파라미터 전달 확인
    expect(fake.lastQueryAppId, '250900');
    expect(fake.lastQueryCount, '3');
    expect(fake.lastQueryMaxLength, '120');
  });

  test('200 OK: appnews/newsitems 없음 → 빈 리스트', () async {
    fake.respondWith(status: 200, jsonBody: {'foo': 'bar'});
    final api = SteamNewsApi(buildUri: localUri);
    final list = await api.fetch();
    expect(list, isEmpty);
  });

  test('비정상 상태코드(500) → 빈 리스트', () async {
    fake.respondWith(status: 500, jsonBody: {'error': 'oops'});
    final api = SteamNewsApi(buildUri: localUri);
    final list = await api.fetch();
    expect(list, isEmpty);
  });

  test('JSON 파싱 실패 → 빈 리스트', () async {
    fake.respondRaw(status: 200, body: 'not-json');
    final api = SteamNewsApi(buildUri: localUri);
    final list = await api.fetch();
    expect(list, isEmpty);
  });

  test('네트워크 오류(서버 종료) → 빈 리스트', () async {
    // 서버 닫기 전에 포트 번호를 저장
    final savedPort = server.port;

    await server.close(force: true); // 연결 실패 유도

    Uri buildBadUri(int appId, int count, int maxLength) =>
        Uri.parse('http://127.0.0.1:$savedPort/ISteamNews/GetNewsForApp/v0002/'
            '?appid=$appId&count=$count&maxlength=$maxLength');

    final api = SteamNewsApi(buildUri: buildBadUri);
    final list = await api.fetch();
    expect(list, isEmpty);
  });

}

// ──────────────────────────────
// 로컬 fake endpoint
// ──────────────────────────────
class _FakeSteamNewsEndpoint {
  final HttpServer server;
  _FakeSteamNewsEndpoint(this.server);

  // 마지막 쿼리 파라미터 기록용
  String? lastQueryAppId;
  String? lastQueryCount;
  String? lastQueryMaxLength;

  int _status = 200;
  String _body = jsonEncode({
    'appnews': {'newsitems': []}
  });

  void respondWith({required int status, required Map<String, dynamic> jsonBody}) {
    _status = status;
    _body = jsonEncode(jsonBody);
  }

  void respondRaw({required int status, required String body}) {
    _status = status;
    _body = body;
  }

  Future<void> serve() async {
    await for (final req in server) {
      if (req.uri.path.contains('/ISteamNews/GetNewsForApp/v0002/')) {
        lastQueryAppId = req.uri.queryParameters['appid'];
        lastQueryCount = req.uri.queryParameters['count'];
        lastQueryMaxLength = req.uri.queryParameters['maxlength'];

        req.response.statusCode = _status;
        req.response.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
        req.response.write(_body);
        await req.response.close();
        continue;
      }
      req.response.statusCode = 404;
      await req.response.close();
    }
  }
}

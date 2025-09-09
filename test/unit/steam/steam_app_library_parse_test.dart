import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:cartridge/features/steam/infra/parsing/acf_utils.dart';

void main() {
  group('Steam ACF 파서(Unit)', () {
    test('InstalledDepots 블록에서 숫자 키를 추출한다 (AAA)', () {
      const acf = r'''
"AppState"
{
  "AppID" "250900"
  "InstalledDepots"
  {
    "250901" { "manifest" "x" }
    "250902" { "manifest" "y" }
  }
}''';

      final block = acfExtractBlock(acf, 'InstalledDepots');
      final ids = acfExtractNumericKeys(block);
      expect(ids, containsAll(<int>{250901, 250902}));
    });

    test('WorkshopItemsInstalled에서 워크샵 ID를 추출한다 (AAA)', () {
      const acf = r'''
"AppWorkshop"
{
  "AppID" "250900"
  "WorkshopItemsInstalled"
  {
    "1111" { "size" "1" }
    "2222" { "size" "2" }
  }
}''';
      final block = acfExtractBlock(acf, 'WorkshopItemsInstalled');
      final ids = acfExtractNumericKeys(block);
      expect(ids, containsAll(<int>{1111, 2222}));
    });

    test('실제 ACF 파일이 있으면(옵션) 파싱된다 (AAA)', () async {
      // 프로젝트에 test/fixtures/appworkshop_250900.acf 로 복사해 두면 실제로 검증합니다.
      final f = File('test/fixtures/appworkshop_250900.acf');
      if (!await f.exists()) {
        // 없으면 스킵 성격으로 통과
        expect(true, isTrue);
        return;
      }
      final txt = await f.readAsString();
      final block = acfExtractBlock(txt, 'WorkshopItemsInstalled');
      final ids = acfExtractNumericKeys(block);
      expect(ids, isNotEmpty);
    });
  });
}
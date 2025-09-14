import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/features/isaac/options/domain/isaac_options_decoder.dart';
import 'package:cartridge/features/isaac/options/domain/models/isaac_options_schema.dart';

void main() {
  group('IsaacOptionsDecoder.fromIniMap()', () {
    test('정수/실수/불리언(INI 0/1) 정상 파싱', () {
      final ini = <String, String>{
        IsaacOptionsSchema.keyWindowWidth:  ' 1280 ',
        IsaacOptionsSchema.keyWindowHeight: ' 720',
        IsaacOptionsSchema.keyWindowPosX:   '100 ',
        IsaacOptionsSchema.keyWindowPosY:   ' 200 ',
        IsaacOptionsSchema.keyFullscreen:   '1',
        IsaacOptionsSchema.keyGamma:        ' 1.75 ',
        IsaacOptionsSchema.keyEnableDebugConsole: '0',
        IsaacOptionsSchema.keyPauseOnFocusLost:   '1',
        IsaacOptionsSchema.keyMouseControl:       '0',
      };

      final o = IsaacOptionsDecoder.fromIniMap(ini);

      expect(o.windowWidth,  1280);
      expect(o.windowHeight, 720);
      expect(o.windowPosX,   100);
      expect(o.windowPosY,   200);

      expect(o.fullscreen, isTrue);
      expect(o.gamma, closeTo(1.75, 0.0001));

      expect(o.enableDebugConsole, isFalse);
      expect(o.pauseOnFocusLost,   isTrue);
      expect(o.mouseControl,       isFalse);
    });

    test('비어있거나 누락된 키 → null 처리', () {
      final ini = <String, String>{
        // 일부만 제공, 나머지는 누락
        IsaacOptionsSchema.keyWindowWidth: '',
        IsaacOptionsSchema.keyGamma:       ' ',
      };

      final o = IsaacOptionsDecoder.fromIniMap(ini);

      expect(o.windowWidth, isNull);
      expect(o.windowHeight, isNull);
      expect(o.windowPosX, isNull);
      expect(o.windowPosY, isNull);

      expect(o.fullscreen, isNull);
      expect(o.gamma, isNull);
      expect(o.enableDebugConsole, isNull);
      expect(o.pauseOnFocusLost, isNull);
      expect(o.mouseControl, isNull);
    });

    test('불리언: 숫자가 아니면(null/공백/문자열) → null', () {
      final ini = <String, String>{
        IsaacOptionsSchema.keyFullscreen:         'true', // 숫자 아님
        IsaacOptionsSchema.keyEnableDebugConsole: ' on ', // 숫자 아님
        IsaacOptionsSchema.keyPauseOnFocusLost:   '',
        IsaacOptionsSchema.keyMouseControl:       ' ',
      };

      final o = IsaacOptionsDecoder.fromIniMap(ini);

      expect(o.fullscreen, isNull);
      expect(o.enableDebugConsole, isNull);
      expect(o.pauseOnFocusLost, isNull);
      expect(o.mouseControl, isNull);
    });

    test('공백이 포함된 숫자 문자열도 trim 후 파싱', () {
      final ini = <String, String>{
        IsaacOptionsSchema.keyWindowWidth:  '  1920  ',
        IsaacOptionsSchema.keyWindowHeight: '\t1080 ',
        IsaacOptionsSchema.keyGamma:        ' 2.20\t',
        IsaacOptionsSchema.keyFullscreen:   ' 0 ',
      };

      final o = IsaacOptionsDecoder.fromIniMap(ini);

      expect(o.windowWidth, 1920);
      expect(o.windowHeight, 1080);
      expect(o.gamma, closeTo(2.20, 0.0001));
      expect(o.fullscreen, isFalse); // '0' → false
    });

    test('불리언: 0 → false, 1 → true', () {
      final ini = <String, String>{
        IsaacOptionsSchema.keyFullscreen:         '1',
        IsaacOptionsSchema.keyEnableDebugConsole: '0',
      };

      final o = IsaacOptionsDecoder.fromIniMap(ini);

      expect(o.fullscreen, isTrue);
      expect(o.enableDebugConsole, isFalse);
    });
  });
}

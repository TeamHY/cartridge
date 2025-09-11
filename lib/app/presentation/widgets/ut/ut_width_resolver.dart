import 'ut_table.dart';

class UTWidthResolver {
  /// 최소 필요 폭(가로 스크롤 기준폭)을 계산
  /// - px/override는 그 값(및 min/max clamp) 그대로 합산
  /// - flex는 각 컬럼의 minPx(없으면 인자 minPx)만큼 합산
  static double minRequiredWidth(
      List<UTColumnSpec> columns, {
        Map<String, double>? pxOverrides,
        double minPx = 40,
      }) {
    double sum = 0;
    for (final c in columns) {
      final boundMin = c.minPx ?? minPx;
      final boundMax = c.maxPx ?? double.infinity;
      final w = c.width;

      if (pxOverrides != null && pxOverrides.containsKey(c.id)) {
        final px = pxOverrides[c.id]!.clamp(boundMin, boundMax);
        sum += px;
      } else if (w is UTPx) {
        final px = w.px.clamp(boundMin, boundMax);
        sum += px;
      } else {
        // flex는 최소만 보장
        sum += boundMin;
      }
    }
    return sum;
  }

  /// 남은 폭 안에서 컬럼 px 폭 배열 계산
  /// - px/override 합(pxSum)을 먼저 확보
  /// - 남은 폭은 flex 비율대로 분배(각 flex 컬럼의 minPx는 보장)
  /// - 가용폭이 pxSum보다 작으면 px를 비율 축소(각 컬럼 minPx 이하로는 내려가지 않게)
  static List<double> resolve(
      List<UTColumnSpec> columns,
      double available, {
        Map<String, double>? pxOverrides,
        double minPx = 40,
      }) {
    final count = columns.length;
    final result = List<double>.filled(count, 0, growable: false);

    // 1) px(override 우선) 선결
    double pxSum = 0;
    int totalFlex = 0;
    final flexIdx = <int>[];

    for (var i = 0; i < count; i++) {
      final c = columns[i];
      final boundMin = c.minPx ?? minPx;
      final boundMax = c.maxPx ?? double.infinity;

      if (pxOverrides != null && pxOverrides.containsKey(c.id)) {
        final v = pxOverrides[c.id]!.clamp(boundMin, boundMax);
        result[i] = v.toDouble();
        pxSum += result[i];
      } else if (c.width is UTPx) {
        final v = (c.width as UTPx).px.clamp(boundMin, boundMax);
        result[i] = v.toDouble();
        pxSum += result[i];
      } else {
        // Flex → 나중에 분배
        flexIdx.add(i);
        totalFlex += (c.width as UTFlex).flex;
      }
    }

    // 2) px 합이 가용폭보다 크면 px만 축소(각각 minPx 이하로는 X)
    if (pxSum > available && pxSum > 0) {
      final scale = available / pxSum;
      pxSum = 0;
      for (var i = 0; i < count; i++) {
        final c = columns[i];
        if (result[i] > 0) {
          final boundMin = c.minPx ?? minPx;
          final boundMax = c.maxPx ?? double.infinity;
          var v = (result[i] * scale).clamp(boundMin, boundMax);
          result[i] = v.toDouble();
          pxSum += result[i];
        }
      }
    }

    // 3) 나머지를 flex로 분배(각 flex의 최소 보장)
    final remain = (available - pxSum).clamp(0, double.infinity);
    if (totalFlex == 0 || remain == 0 || flexIdx.isEmpty) {
      // flex 없음 또는 남은 폭 없음 → 끝
      return result;
    }

    // flex 최소 합
    double flexMinSum = 0;
    for (final i in flexIdx) {
      final c = columns[i];
      final m = (c.minPx ?? minPx).toDouble();
      result[i] = m;
      flexMinSum += m;
    }

    if (flexMinSum >= remain) {
      // 최소만 채워도 가득 → 그대로 반환
      return result;
    }

    // 최소 채운 뒤 남은 폭을 비율 분배
    final pool = remain - flexMinSum;
    for (final i in flexIdx) {
      final c = columns[i];
      final f = (c.width as UTFlex).flex;
      final add = pool * (f / totalFlex);
      final maxPx = c.maxPx ?? double.infinity;
      result[i] = (result[i] + add).clamp(result[i], maxPx).toDouble();
    }

    // 마지막 셀에 잔여 픽셀 흡수(반올림 오차 보정)
    double acc = 0;
    for (int i = 0; i < count - 1; i++) {
      acc += result[i];
    }
    result[count - 1] = (available - acc).clamp(0, double.infinity);

    return result;
  }
}

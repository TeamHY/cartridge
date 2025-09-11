import 'package:week_of_year/week_of_year.dart';

class RecordId {
  static const weeklyPrefix = 'W-';
  static const dailyPrefix  = 'D-';        // D-YYYYMMDD

  static bool isWeekly(String id) => id.startsWith(weeklyPrefix);
  static bool isDaily(String id)  => id.startsWith(dailyPrefix);

  static DateTime _isoWeekStart(int year, int week) {
    final jan4 = DateTime(year, 1, 4);
    final mondayOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - DateTime.monday));
    return mondayOfWeek1.add(Duration(days: (week - 1) * 7));
  }

  static int compatYear(DateTime d, int isoWeek) =>
      (d.day > 15 && isoWeek == 1) ? d.year + 1 : d.year;

  static (int year, int week) parseWeekly(String id) {
    final p = id.split('-'); // W-YYYY-W
    return (int.parse(p[1]), int.parse(p[2]));
  }

  static DateTime parseDailyDate(String id) {
    final raw = id.substring(2);
    return DateTime(
      int.parse(raw.substring(0,4)),
      int.parse(raw.substring(4,6)),
      int.parse(raw.substring(6,8)),
    );
  }

  static String weeklyIdFrom(DateTime d) {
    final w = d.weekOfYear;
    final y = compatYear(d, w);
    return 'W-$y-$w'; // 0-padding 없음(현 규칙 고정)
  }

  static String dailyIdFrom(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'D-${d.year}${two(d.month)}${two(d.day)}';
  }

  static ({String? prev, String? next}) neighbors(String id) {
    if (isWeekly(id)) {
      final (y, w) = parseWeekly(id);
      final monday = _isoWeekStart(y, w);
      return (
      prev: weeklyIdFrom(monday.subtract(const Duration(days: 7))),
      next: weeklyIdFrom(monday.add(const Duration(days: 7))),
      );
    }
    if (isDaily(id)) {
      final d = parseDailyDate(id);
      return (
      prev: dailyIdFrom(d.subtract(const Duration(days: 1))),
      next: dailyIdFrom(d.add(const Duration(days: 1))),
      );
    }
    return (prev: null, next: null);
  }

  static ContestTemporal temporalOf(String? id, {DateTime? now}) {
    if (id == null || id.isEmpty) return ContestTemporal.current;
    now ??= DateTime.now();
    if (isWeekly(id)) {
      final (y, w) = parseWeekly(id);
      final start = _isoWeekStart(y, w);
      final end   = start.add(const Duration(days: 7));
      if (now.isBefore(start)) return ContestTemporal.future;
      if (now.isAfter(end))    return ContestTemporal.past;
      return ContestTemporal.current;
    }
    if (isDaily(id)) {
      final d = parseDailyDate(id);
      final start = DateTime(d.year, d.month, d.day);
      final end   = start.add(const Duration(days: 1));
      if (now.isBefore(start)) return ContestTemporal.future;
      if (now.isAfter(end))    return ContestTemporal.past;
      return ContestTemporal.current;
    }
    return ContestTemporal.current;
  }


  static String formatGameLabel(String id) {
    if (isWeekly(id)) {
      final (y, w) = parseWeekly(id);
      return '$y년 ${w.toString().padLeft(2, '0')}주차';
    } else {
      final date = parseDailyDate(id);
      final s = id.substring(2);
      if (s.length == 8) {
        final y = date.year;
        final m = date.month;
        final d = date.day;
        return '$y년 $m월 $d일';
      }
      return id;
    }
  }

  static String? formatWeeklyRange(String id) {
    if (!isWeekly(id)) {
      return null;
    }
    final (y, w) = parseWeekly(id);
    final start = _isoWeekStart(y, w);
    final end = start.add(const Duration(days: 6));
    String fmt(DateTime d) => '${d.month}/${d.day}';
    return '${fmt(start)} – ${fmt(end)}';
  }
}

enum ContestTemporal { past, current, future }
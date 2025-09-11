// test/helpers/pump_golden.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> pumpGolden(
    WidgetTester tester,
    Widget widget, {
      Size surfaceSize = const Size(800, 600),
      Duration pump = const Duration(milliseconds: 1),
    }) async {
  await tester.pumpWidgetBuilder(widget, surfaceSize: surfaceSize);
  await tester.pump(pump);
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/main.dart';

void main() {
  testWidgets('앱이 예외 없이 첫 프레임을 빌드한다 (smoke, AAA)', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(tester.takeException(), isNull);
  });
}

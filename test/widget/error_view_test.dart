import 'package:flutter_test/flutter_test.dart';
import 'package:cartridge/app/presentation/widgets/error_view.dart';
import '../helpers/fluent_host.dart';
import '../helpers/load_test_fonts.dart';

void main() {
  setUpAll(() async { await loadTestFonts(); });

  testWidgets('에러 뷰: 제목/메시지 + 다시 시도/닫기 버튼 (AAA)', (tester) async {
    var retried = 0;
    await tester.pumpWidget(FluentTestHost(
      useNavigationView: true,
      child: ErrorView(
        messageText: 'Something went wrong during startup.',
        retryText: 'Retry',
        closeText: 'Close',
        onRetry: () => retried++,
      ), // InfoBar/Overlay가 필요할 때 권장 세팅
    ));
    await tester.pump();

    expect(find.text('Something went wrong during startup.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump(const Duration(milliseconds: 120));

    expect(retried, 1);
    expect(find.text('Close'), findsOneWidget);
  });
}

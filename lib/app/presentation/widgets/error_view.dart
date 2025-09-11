import 'dart:io' as io;
import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/theme/theme.dart';

class ErrorView extends StatelessWidget {
  final String messageText;
  final String retryText;
  final String closeText;

  final VoidCallback onRetry;
  final Widget? illustration;

  const ErrorView({
    super.key,
    required this.messageText,
    required this.retryText,
    required this.closeText,
    required this.onRetry,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: ScaffoldPage(
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (illustration != null) ...[
                  illustration!,
                  const SizedBox(height: 12),

                  // TM TRAINER 감성 한 줄 (로컬라이즈 문구와 별개로 살짝 재치)
                  Text(
                    '??? TM TRAINER ???',
                    textAlign: TextAlign.center,
                    style: AppTypography.sectionTitle.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: FluentTheme.of(context).resources.textFillColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  messageText,
                  textAlign: TextAlign.center,
                  style: AppTypography.appBarTitle,
                ),
                Gaps.h16,
                Wrap(
                  spacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton(onPressed: onRetry, child: Text(retryText)),
                    Button(
                      onPressed: () => io.exit(0),
                      child: Text(closeText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

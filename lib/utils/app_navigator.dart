import 'package:cartridge/components/dialogs/error_dialog.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Navigator of the app, for code that has no BuildContext (providers).
final appNavigatorKey = GlobalKey<NavigatorState>();

/// Show an error dialog on top of the app.
void showGlobalErrorDialog(String Function(AppLocalizations loc) message) {
  final context = appNavigatorKey.currentContext;
  if (context == null || !context.mounted) return;

  showErrorDialog(context, message(AppLocalizations.of(context)));
}

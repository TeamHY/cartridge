import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/theme/theme.dart';

class BadgeSpec {
  final String text;
  final StatusColor statusColor;
  final IconData? icon;
  const BadgeSpec(this.text, this.statusColor, {this.icon});
}
import 'package:flutter/foundation.dart';

@immutable
class Violation {
  final String code; // ex: 'opt.name.empty', 'opt.window.width.range'
  final Map<String, Object?> ctx;
  const Violation(this.code, [this.ctx = const {}]);
}

@immutable
class ValidationResult {
  final List<Violation> violations;
  const ValidationResult(this.violations);
  bool get isOk => violations.isEmpty;
}

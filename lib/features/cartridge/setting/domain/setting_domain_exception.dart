import 'package:cartridge/core/validation.dart';

class SettingDomainException implements Exception {
  final String code;
  final List<Violation> violations;
  const SettingDomainException({required this.code, this.violations = const []});

  @override
  String toString() => 'SettingDomainException($code, $violations)';
}

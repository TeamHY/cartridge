/// State of the Isaac and REPENTOGON installations as reported by
/// `rgon-cli status`.
class RepentogonStatus {
  const RepentogonStatus({
    required this.isaacValid,
    required this.isaacCompatible,
    this.isaacVersion,
    this.isaacReason,
    required this.installed,
    required this.launchable,
    required this.state,
    this.version,
  });

  final bool isaacValid;
  final bool isaacCompatible;
  final String? isaacVersion;
  final String? isaacReason;

  /// REPENTOGON files and the game copy used by REPENTOGON are valid.
  final bool installed;

  /// REPENTOGON can be launched (same rule as the official launcher).
  final bool launchable;

  /// One of none, broken, legacy, modern.
  final String state;
  final String? version;

  factory RepentogonStatus.fromJson(Map<String, dynamic> json) {
    final isaac = json['isaac'] as Map<String, dynamic>? ?? const {};
    final repentogon = json['repentogon'] as Map<String, dynamic>? ?? const {};

    String? nonEmpty(Object? value) {
      final text = value as String?;
      return text == null || text.isEmpty ? null : text;
    }

    return RepentogonStatus(
      isaacValid: isaac['valid'] as bool? ?? false,
      isaacCompatible: isaac['compatible'] as bool? ?? false,
      isaacVersion: nonEmpty(isaac['version']),
      isaacReason: nonEmpty(isaac['reason']),
      installed: repentogon['installed'] as bool? ?? false,
      launchable: repentogon['launchable'] as bool? ?? false,
      state: repentogon['state'] as String? ?? 'none',
      version: nonEmpty(repentogon['version']),
    );
  }
}

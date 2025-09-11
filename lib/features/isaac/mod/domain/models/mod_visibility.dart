/// lib/features/isaac/mod/domain/models/mod_visibility.dart
enum ModVisibility { public, friendsOnly, private, unlisted, unknown }

ModVisibility parseModVisibility(String? raw) {
  final s = (raw ?? '').trim().toLowerCase();
  switch (s) {
    case 'public': return ModVisibility.public;
    case 'private': return ModVisibility.private;
    case 'unlisted': return ModVisibility.unlisted;
    case 'friends-only':
    case 'friendsonly':
    case 'friends': return ModVisibility.friendsOnly;
    default: return ModVisibility.unknown;
  }
}

String modVisibilityToString(ModVisibility v) {
  switch (v) {
    case ModVisibility.public: return 'Public';
    case ModVisibility.private: return 'Private';
    case ModVisibility.unlisted: return 'Unlisted';
    case ModVisibility.friendsOnly: return 'Friends-only';
    case ModVisibility.unknown: return 'Unknown';
  }
}

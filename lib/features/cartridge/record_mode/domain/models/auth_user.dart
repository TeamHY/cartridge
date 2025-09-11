class AuthUser {
  final String uid;
  final String nickname;
  final bool isAdmin;
  const AuthUser({
    required this.uid,
    required this.nickname,
    required this.isAdmin,
  });
}
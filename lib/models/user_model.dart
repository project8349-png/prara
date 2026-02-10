class AppUser {
  final String id;
  final String name;
  final String username;
  final String? photoUrl;
  final bool online;

  AppUser({required this.id, required this.name, required this.username, this.photoUrl, this.online = false});

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      photoUrl: map['photoUrl'],
      online: map['online'] ?? false,
    );
  }
}

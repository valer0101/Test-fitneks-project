class FriendUser {
  final int id;
  final String username;
  final String displayName;
  final String? imageUrl;
  final int points;

  FriendUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.imageUrl,
    required this.points,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      imageUrl: json['imageUrl'] as String?,
      points: json['points'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'imageUrl': imageUrl,
      'points': points,
    };
  }
}
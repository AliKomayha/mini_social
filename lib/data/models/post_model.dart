class Post {
  final int id;
  final int userId;
  final String username;
  final String displayName;
  final String? avatar;
  final String text;
  final String? imagePath;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByCurrentUser;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatar,
    required this.text,
    this.imagePath,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByCurrentUser,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      displayName: json['displayName'],
      avatar: json['avatar'],
      text: json['text'],
      imagePath: json['imagePath'],
      likesCount: json['likesCount'],
      commentsCount: json['commentsCount'],
      isLikedByCurrentUser: json['isLikedByCurrentUser'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

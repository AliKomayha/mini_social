class FeedPost {
  final int id;
  final int userId;
  final String userName;
  final String displayName;
  final String? avatar;
  final String text;
  final String? imagePath;
  final bool isPrivate;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  FeedPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.displayName,
    this.avatar,
    required this.text,
    this.imagePath,
    required this.isPrivate,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      displayName: json['displayName'],
      avatar: json['avatar'],
      text: json['text'] ?? '',
      imagePath: json['imagePath'],
      isPrivate: json['isPrivate'] ?? false,
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}


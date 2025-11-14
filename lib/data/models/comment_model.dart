class Comment{

  final int id;
  final int userId;
  final int postId;
  final int? parentId;
  final String text;
  final String username;
  final String displayName;
  final String? avatar;
  List<Comment>? replies;

  Comment({
    required this.id,
    required this.userId,
    required this.postId,
    this.parentId,
    required this.text,
    required this.username,
    required this.displayName,
    this.avatar,
    this.replies
  });

  factory Comment.fromJson(Map<String, dynamic> json){
    return Comment(
      id: json['id'],
      userId: json['userId'],
      postId: json['postId'],
      parentId: json['parentCommentId'] ?? json['parentId'],
      text: json['text'] ?? '',
      username: json['userName'] ?? json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      avatar: json['avatar'],
      replies: (json['replies'] as List?)
          ?.map((r) => Comment.fromJson(r))
          .toList(),
    );
  }
}
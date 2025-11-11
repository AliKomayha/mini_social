class ProfileResponse{
  final Profile profile;
  final Counts counts;
  final List<Post> posts;
  final bool isPrivate;
  final bool isApprovedFollower;
  final String followStatus;
  final String? message; // optional for limited profile

  ProfileResponse({
    required this.profile,
    required this.counts,
    required this.posts,
    required this.isPrivate,
    required this.isApprovedFollower,
    required this.followStatus,
    this.message,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json){
    return ProfileResponse(
      profile: Profile.fromJson(json['profile']),
      counts: Counts.fromJson(json['counts']),
      posts: (json['posts'] as List<dynamic>?)
          ?.map((p) => Post.fromJson(p))
          .toList() ??
          [],
      isPrivate: json['isPrivate'] ?? false,
      isApprovedFollower: json['isApprovedFollower'] ?? false,
      followStatus: json['followStatus'] ?? '',
      message: json['message'],
    );
  }

}

class Profile{
  final int id;
  final int userId;
  final String displayName;
  final String avatar;
  final String? bio;
  final bool isPrivate;
  final String username;


  Profile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.avatar,
    required this.isPrivate,
    required this.username,
    this.bio,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      userId: json['userId'],
      displayName: json['displayName'] ?? '',
      avatar: json['avatar'] ?? '',
      bio: json['bio'],
      isPrivate: json['isPrivate'] ?? false,
      username: json['user']?['username'] ?? json['username'] ?? '',
    );
  }
}

class Counts{
  final int followersCount;
  final int followingCount;
  final int postsCount;

  Counts({
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
  });

  factory Counts.fromJson(Map<String, dynamic> json) {
    return Counts(
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postsCount: json['postsCount'] ?? 0,
    );
  }
}

class Post{
  final int id;
  final String text;
  final String? imagePath;

  Post({
    required this.id,
    required this.text,
    this.imagePath,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      text: json['text'] ?? '',
      imagePath: json['imagePath'],
    );
  }
}

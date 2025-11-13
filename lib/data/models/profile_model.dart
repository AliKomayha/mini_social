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
    // Check if this is a limited profile response (has message and no nested profile)
    final isLimitedProfile = json['message'] != null && json['profile'] == null;
    
    if (isLimitedProfile) {
      // Limited profile: flat structure from backend
      // Backend sends: Id, DisplayName, Avatar, Bio, IsPrivate, FollowStatus, message
      // Need to construct Profile from flat structure
      return ProfileResponse(
        profile: Profile(
          id: json['Id'] ?? json['id'] ?? 0,
          userId: json['Id'] ?? json['id'] ?? 0, // Limited profile doesn't have userId, use Id
          displayName: json['DisplayName'] ?? json['displayName'] ?? '',
          avatar: json['Avatar'] ?? json['avatar'] ?? '',
          bio: json['Bio'] ?? json['bio'],
          isPrivate: json['IsPrivate'] ?? json['isPrivate'] ?? false,
          username: '', // Limited profile doesn't include username
        ),
        counts: Counts(followersCount: 0, followingCount: 0, postsCount: 0),
        posts: [],
        isPrivate: json['IsPrivate'] ?? json['isPrivate'] ?? false,
        isApprovedFollower: false,
        followStatus: json['FollowStatus'] ?? json['followStatus'] ?? '',
        message: json['message'],
      );
    } else {
      // Full profile: nested structure
      return ProfileResponse(
        profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
        counts: json['counts'] != null 
            ? Counts.fromJson(json['counts'] as Map<String, dynamic>)
            : Counts(followersCount: 0, followingCount: 0, postsCount: 0),
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
  final int? likeCount;
  final int? commentCount;

  Post({
    required this.id,
    required this.text,
    this.imagePath,
    this.likeCount,
    this.commentCount,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      text: json['text'] ?? '',
      imagePath: json['imagePath'],
      likeCount: json['likeCount'],
      commentCount: json['commentCount'],
    );
  }
}

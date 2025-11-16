import 'package:flutter/material.dart';
import 'package:mini_social/config.dart';
import 'package:mini_social/data/models/profile_model.dart';
import 'package:mini_social/data/services/profile_service.dart';
import 'package:mini_social/followers_screen.dart';
import 'package:mini_social/following_screen.dart';
import 'package:mini_social/edit_profile.dart';
import 'package:mini_social/post_card.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Profile extends StatefulWidget {
  final int userId;
  final String token;
  final String baseUrl;



  const Profile({super.key,
    required this.userId,
    required this.token,
    required this.baseUrl,});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late Future<ProfileResponse> _futureProfile;
  String? _token;

  @override
  void initState(){
    super.initState();
    _loadToken();
    _futureProfile = ProfileService(
        baseUrl: widget.baseUrl,
        token: widget.token,
    ).getProfile(widget.userId);
  }
  
  Future<void> _loadToken() async{
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

  void _refreshProfile() {
    setState(() {
      _futureProfile = ProfileService(
        baseUrl: widget.baseUrl,
        token: widget.token,
      ).getProfile(widget.userId);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:  FutureBuilder<ProfileResponse>(
            future: _futureProfile,
            builder: (context, snapshot){

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData) {
                return const Center(child: Text("No profile found"));
              }

              final profile = snapshot.data!;

              if (profile.message == "This account is private") {
                return LimitedProfileView(
                  profile: profile,
                  token: _token,
                  baseUrl: widget.baseUrl,
                  onProfileUpdated: _refreshProfile,
                );
              } else {
                return FullProfileView(
                  profile: profile,
                  token: _token,
                  baseUrl: widget.baseUrl,
                  onPostDeleted: _refreshProfile,
                  onPostUpdated: _refreshProfile,
                  onProfileUpdated: _refreshProfile,
                );
              }
            },
        ),
    );
  }
}

class LimitedProfileView extends StatefulWidget {
  final ProfileResponse profile;
  final String? token;
  final String baseUrl;
  final VoidCallback? onProfileUpdated;

  const LimitedProfileView({
    super.key,
    required this.profile,
    required this.token,
    required this.baseUrl,
    this.onProfileUpdated,
  });

  @override
  State<LimitedProfileView> createState() => _LimitedProfileViewState();
}

class _LimitedProfileViewState extends State<LimitedProfileView> {
  bool _isFollowing = false;
  bool _requestSent = false;
  bool _loading = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Check follow status from the profile response
    _requestSent = widget.profile.followStatus == 'Pending' || 
                   widget.profile.followStatus == 'Requested';
    _isFollowing = widget.profile.followStatus == 'Following';
    
    // Load current user ID
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('userId');
    });
  }

  Future<void> _toggleFollow() async {
    setState(() => _loading = true);

    final service = ProfileService(
      baseUrl: widget.baseUrl,
      token: widget.token!,
    );

    try {
      if (_isFollowing || _requestSent) {
        await service.unFollowUser(widget.profile.profile.userId);
        setState(() {
          _isFollowing = false;
          _requestSent = false;
        });
      } else {
        await service.followUser(widget.profile.profile.userId);
        // For private profiles, show "Request Sent" after following
        setState(() {
          _requestSent = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    
    // Remove file:// prefix if present
    String cleanPath = path.replaceFirst(RegExp(r'^file://'), '');
    
    // If already a full URL, return as is
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }
    
    // Otherwise, prepend baseUrl
    return '${widget.baseUrl}$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isOwnProfile = _currentUserId != null && 
                         _currentUserId == profile.profile.userId;

    return ListView(
      children: [
        // Banner/Header Section
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade400,
                Colors.purple.shade400,
              ],
            ),
          ),
        ),
        
        // Profile Picture and Action Button Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Profile Picture (overlapping banner)
              Transform.translate(
                offset: const Offset(0, -60),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(
                      _getImageUrl(profile.profile.avatar),
                    ),
                    backgroundColor: Colors.grey[300],
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
              ),
              const Spacer(),
              // Action Button
              Transform.translate(
                offset: const Offset(0, -20),
                child: isOwnProfile
                    ? OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfile(
                                profile: profile.profile,
                                token: widget.token!,
                                baseUrl: widget.baseUrl,
                                onProfileUpdated: widget.onProfileUpdated,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Edit Profile",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: _loading ? null : _toggleFollow,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(
                          _requestSent
                              ? "Request Sent"
                              : _isFollowing ? "Following" : "Follow",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ],
          ),
        ),
        
        // Profile Info Section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Display Name
              Text(
                profile.profile.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              // Username
              if (profile.profile.username.isNotEmpty)
                Text(
                  '@${profile.profile.username}',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 16),
              // Bio
              if (profile.profile.bio != null && profile.profile.bio!.isNotEmpty)
                Text(
                  profile.profile.bio!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 16),
              // Stats Row
              Row(
                children: [
                  _buildStatItem(
                    'Posts',
                    profile.counts.postsCount,
                    null,
                  ),
                  const SizedBox(width: 20),
                  _buildStatItem(
                    'Following',
                    profile.counts.followingCount,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FollowingScreen(
                            userId: profile.profile.userId,
                            token: widget.token!,
                            baseUrl: widget.baseUrl,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildStatItem(
                    'Followers',
                    profile.counts.followersCount,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FollowersScreen(
                            userId: profile.profile.userId,
                            token: widget.token!,
                            baseUrl: widget.baseUrl,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Private Account Message
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "This account is private",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int count, VoidCallback? onTap) {
    final widget = GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatCount(count),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: onTap != null ? Colors.black87 : Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
    
    return onTap != null
        ? widget
        : DefaultTextStyle(
            style: TextStyle(color: Colors.grey[600]),
            child: widget,
          );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
////////////////////////////////////////////////////////////////////////////////////////
/*
Full Profile
 */


class FullProfileView extends StatefulWidget {
  final ProfileResponse profile;
  final String? token;
  final String baseUrl;
  final VoidCallback? onPostDeleted;
  final VoidCallback? onPostUpdated;
  final VoidCallback? onProfileUpdated;

  const FullProfileView({
    super.key,
    required this.profile,
    required this.token,
    required this.baseUrl,
    this.onPostDeleted,
    this.onPostUpdated,
    this.onProfileUpdated,
  });

  @override
  State<FullProfileView> createState() => FullProfileViewState();
}

class FullProfileViewState extends State<FullProfileView> {
  bool _isFollowing = false;
  bool _loading = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Load current user ID and only check following status if viewing someone else's profile
    _loadCurrentUserId().then((_) {
      if (_currentUserId != null && 
          _currentUserId != widget.profile.profile.userId) {
        _checkFollowingStatus();
      }
    });
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('userId');
    });
  }

  Future<void> _checkFollowingStatus() async {
    try {
      final service = ProfileService(
        baseUrl: AppConfig.baseUrl,
        token: widget.token!,
      );

      final isFollowing =
      await service.isFollowing(widget.profile.profile.userId);

      setState(() {
        _isFollowing = isFollowing;
      });
    } catch (e) {
      debugPrint('Error checking following status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _loading = true);

    final service = ProfileService(
      baseUrl: widget.baseUrl,
      token: widget.token!,
    );

    try {
      if (_isFollowing) {
        await service.unFollowUser(widget.profile.profile.userId);
      } else {
        await service.followUser(widget.profile.profile.userId);
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    String cleanPath = path.replaceFirst(RegExp(r'^file://'), '');
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }
    return '${widget.baseUrl}$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isOwnProfile = _currentUserId != null && 
                         _currentUserId == profile.profile.userId;

    return ListView(
      children: [
        // Banner/Header Section
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade400,
                Colors.purple.shade400,
              ],
            ),
          ),
        ),
        
        // Profile Picture and Action Button Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Profile Picture (overlapping banner)
              Transform.translate(
                offset: const Offset(0, -60),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(
                      _getImageUrl(profile.profile.avatar),
                    ),
                    backgroundColor: Colors.grey[300],
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
              ),
              const Spacer(),
              // Action Button
              Transform.translate(
                offset: const Offset(0, -20),
                child: isOwnProfile
                    ? OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfile(
                                profile: profile.profile,
                                token: widget.token!,
                                baseUrl: widget.baseUrl,
                                onProfileUpdated: widget.onProfileUpdated,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Edit Profile",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: _loading ? null : _toggleFollow,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(
                          _isFollowing ? "Following" : "Follow",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ],
          ),
        ),
        
        // Profile Info Section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Display Name
              Text(
                profile.profile.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              // Username
              Text(
                '@${profile.profile.username}',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              // Bio
              if (profile.profile.bio != null && profile.profile.bio!.isNotEmpty)
                Text(
                  profile.profile.bio!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 16),
              // Stats Row
              Row(
                children: [
                  _buildStatItem(
                    'Posts',
                    profile.counts.postsCount,
                    null,
                  ),
                  const SizedBox(width: 20),
                  _buildStatItem(
                    'Following',
                    profile.counts.followingCount,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FollowingScreen(
                            userId: profile.profile.userId,
                            token: widget.token!,
                            baseUrl: widget.baseUrl,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildStatItem(
                    'Followers',
                    profile.counts.followersCount,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FollowersScreen(
                            userId: profile.profile.userId,
                            token: widget.token!,
                            baseUrl: widget.baseUrl,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Divider
              const Divider(height: 1),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Posts List
        ...profile.posts.map((p) => PostCard(
          post: p,
          displayName: profile.profile.displayName,
          username: profile.profile.username,
          avatar: profile.profile.avatar,
          currentUserId: _currentUserId,
          postUserId: profile.profile.userId,
          baseUrl: widget.baseUrl,
          token: widget.token!,
          initialLikesCount: p.likeCount,
          initialCommentsCount: p.commentCount,
          onPostDeleted: widget.onPostDeleted,
          onPostUpdated: widget.onPostUpdated,
        )),
      ],
    );
  }

  Widget _buildStatItem(String label, int count, VoidCallback? onTap) {
    final widget = GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatCount(count),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: onTap != null ? Colors.black87 : Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
    
    return onTap != null
        ? widget
        : DefaultTextStyle(
            style: TextStyle(color: Colors.grey[600]),
            child: widget,
          );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}





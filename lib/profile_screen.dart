import 'package:flutter/material.dart';
import 'package:mini_social/config.dart';
import 'package:mini_social/data/models/profile_model.dart';
import 'package:mini_social/data/services/profile_service.dart';
import 'package:mini_social/followers_screen.dart';
import 'package:mini_social/following_screen.dart';
import 'package:mini_social/edit_profile.dart';
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),

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
                return LimitedProfileView(profile: profile, token: _token);
              } else {
                return FullProfileView(profile: profile,
                token: _token,
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

  const LimitedProfileView({
    super.key,
    required this.profile,
    required this.token,
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
      baseUrl: AppConfig.baseUrl,
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
    return '${AppConfig.baseUrl}$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isOwnProfile = _currentUserId != null && 
                         _currentUserId == profile.profile.userId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                _getImageUrl(profile.profile.avatar),
              ),
              radius: 40,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.profile.displayName,
                      style: const TextStyle(fontSize: 20)),
                  if (profile.profile.username.isNotEmpty)
                    Text('@${profile.profile.username}'),
                  if (profile.profile.bio != null && profile.profile.bio!.isNotEmpty)
                    Text(profile.profile.bio ?? ""),
                  const SizedBox(height: 10),

                  // Show Edit Profile button for own profile, Follow/Request Sent for others
                  if (isOwnProfile)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfile(),
                          ),
                        );
                      },
                      child: const Text("Edit Profile"),
                    )
                  else
                    ElevatedButton(
                      onPressed: _loading ? null : _toggleFollow,
                      child: _loading
                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : _requestSent
                              ? const Text("Request Sent")
                              : Text(_isFollowing ? "Unfollow" : "Follow"),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text("Posts: ${profile.counts.postsCount}"),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowersScreen(
                      userId: profile.profile.userId,
                      token: widget.token!,
                      baseUrl: AppConfig.baseUrl,
                    ),
                  ),
                );
              },
              child: Text(
                "Followers: ${profile.counts.followersCount}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowingScreen(
                      userId: profile.profile.userId,
                      token: widget.token!,
                      baseUrl: AppConfig.baseUrl,
                    ),
                  ),
                );
              },
              child: Text(
                "Following: ${profile.counts.followingCount}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),

        const Divider(),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            "This account is private",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
////////////////////////////////////////////////////////////////////////////////////////
/*
Full Profile
 */


class FullProfileView extends StatefulWidget {
  final ProfileResponse profile;
  final String? token;

  const FullProfileView({
    super.key,
    required this.profile,
    required this.token,
  });

  @override
  State<FullProfileView> createState() => _FullProfileViewState();
}

class _FullProfileViewState extends State<FullProfileView> {
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
      baseUrl: AppConfig.baseUrl,
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
    return '${AppConfig.baseUrl}$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isOwnProfile = _currentUserId != null && 
                         _currentUserId == profile.profile.userId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                _getImageUrl(profile.profile.avatar),
              ),
              radius: 40,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.profile.displayName,
                      style: const TextStyle(fontSize: 20)),
                  Text('@${profile.profile.username}'),
                  Text(profile.profile.bio ?? ""),
                  const SizedBox(height: 10),

                  // Show Edit Profile button for own profile, Follow/Unfollow for others
                  if (isOwnProfile)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfile(),
                          ),
                        );
                      },
                      child: const Text("Edit Profile"),
                    )
                  else
                    ElevatedButton(
                      onPressed: _loading ? null : _toggleFollow,
                      child: _loading
                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(_isFollowing ? "Unfollow" : "Follow"),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text("Posts: ${profile.counts.postsCount}"),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowersScreen(
                      userId: profile.profile.userId,
                      token: widget.token!,
                      baseUrl: AppConfig.baseUrl,
                    ),
                  ),
                );
              },
              child: Text(
                "Followers: ${profile.counts.followersCount}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowingScreen(
                      userId: profile.profile.userId,
                      token: widget.token!,
                      baseUrl: AppConfig.baseUrl,
                    ),
                  ),
                );
              },
              child: Text(
                "Following: ${profile.counts.followingCount}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),

        const Divider(),
        const SizedBox(height: 10),

        ...profile.posts.map((p) => ListTile(
          title: Text(p.text),
          leading: p.imagePath != null
              ? SizedBox(
            width: 60,
            height: 60,
            child: Image.network(
              _getImageUrl(p.imagePath),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image);
              },
            ),
          )
              : null,
        )),
      ],
    );
  }
}





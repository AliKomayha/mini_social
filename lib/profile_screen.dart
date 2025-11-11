import 'package:flutter/material.dart';
import 'package:mini_social/config.dart';
import 'package:mini_social/data/models/profile_model.dart';
import 'package:mini_social/data/services/profile_service.dart';
import 'package:mini_social/followers_screen.dart';
import 'package:mini_social/following_screen.dart';
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
                return LimitedProfileView(profile: profile);
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

class LimitedProfileView extends StatelessWidget {
  final ProfileResponse profile;
  const LimitedProfileView({super.key, required this.profile});

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
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(
          backgroundImage: NetworkImage(
            _getImageUrl(profile.profile.avatar),
          ),
          radius: 50,
        ),
        const SizedBox(height: 12,),
        Text(profile.profile.displayName, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        const Text("This account is private"),
      ]),
    );
  }
}



class FullProfileView extends StatelessWidget {
  final ProfileResponse profile;
  final String? token;
  const FullProfileView({super.key, required this.profile, required this.token});

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                _getImageUrl(profile.profile.avatar),
              ),
              radius: 40,
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.profile.displayName,
                    style: const TextStyle(fontSize: 20)),
                Text('@${profile.profile.username}'),
                Text(profile.profile.bio ?? ""),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text("Posts: ${profile.counts.postsCount}"),
            GestureDetector(
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_)=> FollowersScreen(

                          userId: profile.profile.userId,
                          token:  token!,
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
            //Text("Followers: ${profile.counts.followersCount}"),


            GestureDetector(
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_)=> FollowingScreen(

                      userId: profile.profile.userId,
                      token:  token!,
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





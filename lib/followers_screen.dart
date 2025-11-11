import 'package:flutter/material.dart';
import 'package:mini_social/data/services/profile_service.dart';
import 'package:mini_social/config.dart';
import 'profile_screen.dart';


class FollowersScreen extends StatefulWidget {
  final int userId;
  final String token;
  final String baseUrl;

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  late Future<List<dynamic>> _futureFollowers;

  @override
  void initState() {
    super.initState();
    _futureFollowers = ProfileService(
      baseUrl: widget.baseUrl,
      token: widget.token,
    ).getFollowers(widget.userId);
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    String cleanPath = path.replaceFirst(RegExp(r'^file://'), '');
    if (cleanPath.startsWith('http')) return cleanPath;
    return '${AppConfig.baseUrl}$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Followers")),
      body: FutureBuilder<List<dynamic>>(
        future: _futureFollowers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No followers"));
          }

          final followers = snapshot.data!;

          return ListView.builder(
            itemCount: followers.length,
            itemBuilder: (context, index) {
              final follower = followers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(_getImageUrl(follower['avatar'])),
                ),
                title: Text(follower['displayName']),
                subtitle: Text('@${follower['username']}'),
                onTap: () {
                  // Navigate to profile
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Profile(
                        userId: follower['userId'],
                        token: widget.token,
                        baseUrl: widget.baseUrl,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

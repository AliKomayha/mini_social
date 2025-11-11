import 'package:flutter/material.dart';
import 'package:mini_social/data/services/profile_service.dart';
import 'package:mini_social/config.dart';
import 'profile_screen.dart';

class FollowingScreen extends StatefulWidget {
  final int userId;
  final String token;
  final String baseUrl;

  const FollowingScreen({
    super.key,
    required this.userId,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  late Future<List<dynamic>> _futureFollowing;

  @override
  void initState() {
    super.initState();
    _futureFollowing = ProfileService(
      baseUrl: widget.baseUrl,
      token: widget.token,
    ).getFollowing(widget.userId);
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
      appBar: AppBar(title: const Text("Following")),
      body: FutureBuilder<List<dynamic>>(
        future: _futureFollowing,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No following users"));
          }

          final following = snapshot.data!;

          return ListView.builder(
            itemCount: following.length,
            itemBuilder: (context, index) {
              final user = following[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(_getImageUrl(user['avatar'])),
                ),
                title: Text(user['displayName']),
                subtitle: Text('@${user['username']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Profile(
                        userId: user['userId'],
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

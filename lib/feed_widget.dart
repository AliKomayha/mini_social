import 'package:flutter/material.dart';
import 'package:mini_social/config.dart';
import 'package:mini_social/data/models/feed_post_model.dart';
import 'package:mini_social/data/models/profile_model.dart';
import 'package:mini_social/data/services/feed_service.dart';
import 'package:mini_social/post_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedWidget extends StatefulWidget {
  final String token;
  final String baseUrl;

  const FeedWidget({
    super.key,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<FeedWidget> createState() => _FeedWidgetState();
}

class _FeedWidgetState extends State<FeedWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<FeedPost> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 10;
  int? _currentUserId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _scrollController.addListener(_onScroll);
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('userId');
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadPosts();
      }
    }
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = FeedService(
        baseUrl: widget.baseUrl,
        token: widget.token,
      );

      final newPosts = await service.getFollowingFeed(
        offset: _offset,
        limit: _limit,
      );

      setState(() {
        if (newPosts.isEmpty) {
          _hasMore = false;
        } else {
          _posts.addAll(newPosts);
          _offset += newPosts.length;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load feed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _offset = 0;
                  _posts.clear();
                  _hasMore = true;
                });
                _loadPosts();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Text(
          'No posts to show',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _offset = 0;
          _posts.clear();
          _hasMore = true;
        });
        await _loadPosts();
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final feedPost = _posts[index];
          // Convert FeedPost to Post (from profile_model) for PostCard
          final post = Post(
            id: feedPost.id,
            text: feedPost.text,
            imagePath: feedPost.imagePath,
          );

          return PostCard(
            post: post,
            displayName: feedPost.displayName,
            username: feedPost.userName,
            avatar: feedPost.avatar,
            currentUserId: _currentUserId,
            postUserId: feedPost.userId,
            baseUrl: widget.baseUrl,
            initialLikesCount: feedPost.likeCount,
            initialCommentsCount: feedPost.commentCount,
            initialIsLiked: false, // API doesn't provide this, default to false
          );
        },
      ),
    );
  }
}


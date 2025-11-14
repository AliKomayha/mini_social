import 'package:flutter/material.dart';
import 'package:mini_social/data/models/profile_model.dart' as models;
import 'package:mini_social/data/services/post_service.dart';
import 'package:mini_social/profile_screen.dart';
import 'package:mini_social/comments_screen.dart';
import 'package:mini_social/edit_post_screen.dart';

class PostCard extends StatefulWidget {
  final models.Post post;
  final String? displayName;
  final String? username;
  final String? avatar;
  final int? currentUserId;
  final int? postUserId;
  final String baseUrl;
  final String token;
  final int? initialLikesCount;
  final int? initialCommentsCount;
  final bool? initialIsLiked;
  final VoidCallback? onPostDeleted;
  final VoidCallback? onPostUpdated;

  const PostCard({
    super.key,
    required this.post,
    this.displayName,
    this.username,
    this.avatar,
    this.currentUserId,
    this.postUserId,
    required this.baseUrl,
    required this.token,
    this.initialLikesCount,
    this.initialCommentsCount,
    this.initialIsLiked,
    this.onPostDeleted,
    this.onPostUpdated,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  int _likesCount = 0;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with post data if available
    _likesCount = widget.initialLikesCount ?? 0;
    _commentsCount = widget.initialCommentsCount ?? 0;
    _isLiked = widget.initialIsLiked ?? false;
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    String cleanPath = path.replaceFirst(RegExp(r'^file://'), '');
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }
    return '${widget.baseUrl}$cleanPath';
  }

  void _toggleLike() async {
    // Optimistic update
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    final postService = PostService(baseUrl: widget.baseUrl, token: widget.token);

    final result = await postService.toggleLike(widget.post.id,);

    if (!result['success']) {
      // Revert UI because backend failed
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
    } else {
      // Ensure count stays synced with server
      setState(() {
        _likesCount = result['likeCount'];
      });
    }
  }


  void _navigateToComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommentsScreen(
          postId: widget.post.id,
          token: widget.token,
          baseUrl: widget.baseUrl,
        ),
      ),
    );
  }

  void _navigateToProfile() {
    if (widget.postUserId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Profile(
            userId: widget.postUserId!,
            token: widget.token,
            baseUrl: widget.baseUrl,
          ),
        ),
      );
    }
  }

  void _showEditDeleteMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editPost();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deletePost();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _editPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPostScreen(
          postId: widget.post.id,
          initialText: widget.post.text,
          initialImagePath: widget.post.imagePath,
          token: widget.token,
          baseUrl: widget.baseUrl,
          onPostUpdated: widget.onPostUpdated,
        ),
      ),
    );
  }

  Future<void> _deletePost() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final service = PostService(
      baseUrl: widget.baseUrl,
      token: widget.token,
    );

    try {
      final result = await service.deletePost(widget.post.id);

      if (result['success'] == true) {
        // Call the callback to refresh the feed/profile
        widget.onPostDeleted?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to delete post'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwnPost = widget.currentUserId != null &&
        widget.postUserId != null &&
        widget.currentUserId == widget.postUserId;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE1E8ED), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            GestureDetector(
              onTap: _navigateToProfile,
              child: CircleAvatar(
                radius: 24,
                backgroundImage: widget.avatar != null && widget.avatar!.isNotEmpty
                    ? NetworkImage(_getImageUrl(widget.avatar))
                    : null,
                child: widget.avatar == null || widget.avatar!.isEmpty
                    ? const Icon(Icons.person, size: 24)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Post Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Display Name, Username, More Button
                  Row(
                    children: [
                      if (widget.displayName != null && widget.displayName!.isNotEmpty)
                        Text(
                          widget.displayName!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      if (widget.username != null && widget.username!.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '@${widget.username}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (isOwnPost)
                        IconButton(
                          icon: const Icon(Icons.more_horiz, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _showEditDeleteMenu,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Post Text
                  if (widget.post.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        widget.post.text,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  // Post Image
                  if (widget.post.imagePath != null && widget.post.imagePath!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _getImageUrl(widget.post.imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Comment Button
                      InkWell(
                        onTap: _navigateToComments,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              if (_commentsCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  _formatCount(_commentsCount),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Like Button
                      InkWell(
                        onTap: _toggleLike,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: _isLiked ? Colors.red : Colors.grey[600],
                              ),
                              if (_likesCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  _formatCount(_likesCount),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _isLiked ? Colors.red : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

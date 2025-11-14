import 'package:flutter/material.dart';
import 'package:mini_social/comment_card.dart';
import 'package:mini_social/config.dart';
import 'package:mini_social/data/models/comment_model.dart';
import 'package:mini_social/data/services/comment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentsScreen extends StatefulWidget {
  final int postId;
  final String token;
  final String baseUrl;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _error;
  int? _replyingToId;
  String? _replyingToUsername;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadComments();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('userId');
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = CommentService(
        baseUrl: widget.baseUrl,
        token: widget.token,
      );
      final comments = await service.getComments(widget.postId);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load comments: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final service = CommentService(
      baseUrl: widget.baseUrl,
      token: widget.token,
    );

    try {
      final updatedComments = await service.addComment(
        postId: widget.postId,
        text: text,
        parentCommentId: _replyingToId,
      );

      setState(() {
        _comments = updatedComments;
        _commentController.clear();
        _replyingToId = null;
        _replyingToUsername = null;
      });

      // Scroll to top to show new comment
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    }
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingToId = comment.id;
      _replyingToUsername = comment.username;
    });
    _commentController.clear();
    FocusScope.of(context).requestFocus(FocusNode());
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus();
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToUsername = null;
    });
    _commentController.clear();
  }

  Future<void> _deleteComment(int commentId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
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

    final service = CommentService(
      baseUrl: widget.baseUrl,
      token: widget.token,
    );

    try {
      final updatedComments = await service.deleteComment(
        commentId: commentId,
        postId: widget.postId,
      );

      setState(() {
        _comments = updatedComments;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete comment: $e')),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadComments,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _comments.isEmpty
                        ? const Center(
                            child: Text(
                              'No comments yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadComments,
                            child: ListView.builder(
                              controller: _scrollController,
                              reverse: false,
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                return CommentCard(
                                  comment: _comments[index],
                                  baseUrl: widget.baseUrl,
                                  onReply: _startReply,
                                  currentUserId: _currentUserId,
                                  onDelete: _deleteComment,
                                );
                              },
                            ),
                          ),
          ),
          // Reply indicator
          if (_replyingToUsername != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to @$_replyingToUsername',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // Input Field
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: _replyingToUsername != null
                          ? 'Reply to @$_replyingToUsername...'
                          : 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'data/models/comment_model.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;
  final String baseUrl;
  final void Function(Comment reply)? onReply;
  final int? currentUserId;
  final void Function(int commentId)? onDelete;

  const CommentCard({
    super.key,
    required this.comment,
    required this.baseUrl,
    this.onReply,
    this.currentUserId,
    this.onDelete,
  });

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    String cleanPath = path.replaceFirst(RegExp(r'^file://'), '');
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }
    return '${baseUrl}$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final isReply = comment.parentId != null;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: isReply
              ? BorderSide(color: Colors.grey[300]!, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: isReply ? 16 : 0,
          top: 8,
          bottom: 8,
          right: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundImage: comment.avatar != null &&
                          comment.avatar!.isNotEmpty
                      ? NetworkImage(_getImageUrl(comment.avatar))
                      : null,
                  child: comment.avatar == null || comment.avatar!.isEmpty
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username and display name
                      Row(
                        children: [
                          Text(
                            comment.displayName.isNotEmpty
                                ? comment.displayName
                                : comment.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (comment.displayName.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              '@${comment.username}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Comment text
                      Text(
                        comment.text,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      // Action buttons (Reply and Delete)
                      Row(
                        children: [
                          if (onReply != null)
                            InkWell(
                              onTap: () => onReply!(comment),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                child: Text(
                                  'Reply',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          if (currentUserId != null &&
                              comment.userId == currentUserId &&
                              onDelete != null) ...[
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () => onDelete!(comment.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Nested replies
            if (comment.replies != null && comment.replies!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 30),
                child: Column(
                  children: comment.replies!
                      .map((reply) => CommentCard(
                            comment: reply,
                            baseUrl: baseUrl,
                            onReply: onReply,
                            currentUserId: currentUserId,
                            onDelete: onDelete,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mini_social/data/models/comment_model.dart';

class CommentService {
  final String baseUrl;
  final String token;

  CommentService({required this.baseUrl, required this.token});

  Future<List<Comment>> getComments(int postId) async {
    final url = Uri.parse('$baseUrl/api/PostsApi/GetComments?postId=$postId');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load comments: ${response.statusCode}');
    }
  }

  Future<List<Comment>> addComment({
    required int postId,
    required String text,
    int? parentCommentId,
  }) async {
    final url = Uri.parse('$baseUrl/api/PostsApi/AddComment');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['postId'] = postId.toString();
    request.fields['text'] = text;
    if (parentCommentId != null) {
      request.fields['parentCommentId'] = parentCommentId.toString();
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding comment: $e');
    }
  }

  Future<List<Comment>> deleteComment({
    required int commentId,
    required int postId,
  }) async {
    final url = Uri.parse('$baseUrl/api/PostsApi/DeleteComment');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['commentId'] = commentId.toString();
    request.fields['postId'] = postId.toString();

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting comment: $e');
    }
  }
}


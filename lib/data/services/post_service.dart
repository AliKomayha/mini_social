import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_social/config.dart';

class PostService {
  final String baseUrl;
  final String token;

  PostService({required this.baseUrl, required this.token});

  Future<Map<String, dynamic>> createPost({
    required String text,
    File? image,
  }) async {
    final url = Uri.parse('$baseUrl/api/PostsApi/Create');

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['text'] = text;

    if (image != null) {
      var fileStream = http.ByteStream(image.openRead());
      var fileLength = await image.length();
      var multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: image.path.split('/').last,
      );
      request.files.add(multipartFile);
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'post': data['post'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create post: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating post: $e',
      };
    }
  }

  Future<Map<String, dynamic>> toggleLike(int postId) async {
    final url = Uri.parse('$baseUrl/api/PostsApi/ToggleLike');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['postId'] = postId.toString();

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'likeCount': data['likeCount'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to toggle like',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error toggling like: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deletePost(int postId) async {
    final url = Uri.parse('$baseUrl/api/PostsApi/Delete');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['postId'] = postId.toString();

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': 'Failed to delete post',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting post: $e',
      };
    }
  }

  Future<Map<String, dynamic>> editPost({
    required int id,
    required String text,
    File? image,
  }) async {
    final url = Uri.parse('$baseUrl/api/PostsApi/Edit');

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['id'] = id.toString();
    request.fields['text'] = text;

    if (image != null) {
      var fileStream = http.ByteStream(image.openRead());
      var fileLength = await image.length();
      var multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: image.path.split('/').last,
      );
      request.files.add(multipartFile);
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'post': data['post'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to edit post: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error editing post: $e',
      };
    }
  }
}


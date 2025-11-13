import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mini_social/data/models/feed_post_model.dart';

class FeedService {
  final String baseUrl;
  final String token;

  FeedService({required this.baseUrl, required this.token});

  Future<List<FeedPost>> getFollowingFeed({
    required int offset,
    required int limit,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/FeedApi/GetFollowingFeed?offset=$offset&limit=$limit',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FeedPost.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load feed: ${response.statusCode}');
    }
  }
}


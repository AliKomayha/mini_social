import 'dart:convert';
import 'package:mini_social/data/models/profile_model.dart';
import 'package:http/http.dart' as http;

class ProfileService{
  final String baseUrl;
  final String token;

  ProfileService({required this.baseUrl, required this.token});

  Future<ProfileResponse> getProfile(int id) async{
      final res = await http.get(
        Uri.parse('$baseUrl/api/ProfilesApi/GetProfile/$id'),
        headers: {
          'Authorization' : 'Bearer $token',
        }
      );

      if (res.statusCode == 200){
        return ProfileResponse.fromJson(jsonDecode(res.body));
      } else{
        throw Exception('Failed to load profile');
      }


  }

  Future<List<dynamic>> getFollowers(int userId) async {
    final url = Uri.parse('$baseUrl/api/ProfilesApi/followers/$userId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['followers'] as List<dynamic>;
    } else {
      throw Exception('Failed to load followers');
    }
  }

  Future<List<dynamic>> getFollowing(int userId) async {
    final url = Uri.parse('$baseUrl/api/ProfilesApi/following/$userId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['following'] as List<dynamic>;
    } else {
      throw Exception('Failed to load following');
    }
  }

  Future<bool> isFollowing(int targetUserId) async{
    final url = Uri.parse('$baseUrl/api/ProfilesApi/IsFollowing/$targetUserId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if(response.statusCode == 200){
      return  jsonDecode(response.body) == true;
    }
    else{
      throw Exception('Failed to check following status');
    }
  }

  Future<void> followUser(int followingId) async{
    final url = Uri.parse('$baseUrl/api/ProfilesApi/Follow/$followingId');
    final response = await http.post(url, headers: {
        'Authorization': 'Bearer $token',
      });

    if (response.statusCode != 200) {
      throw Exception('Failed to follow user');
    }
  }

  Future<void> unFollowUser(int followingId) async{
    final url = Uri.parse('$baseUrl/api/ProfilesApi/UnFollow/$followingId');
    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $token',
    });


    if (response.statusCode != 200) {
      throw Exception('Failed to unfollow user');
    }
  }



}
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

}
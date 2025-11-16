import 'dart:convert';
import 'dart:io';
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

  Future<List<dynamic>> searchProfiles(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse('$baseUrl/api/ProfilesApi/Search?query=$encodedQuery');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data as List<dynamic>;
    } else {
      throw Exception('Search failed: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> editProfile({
    required String displayName,
    String? bio,
    DateTime? birthDate,
    required bool isPrivate,
    File? avatarFile,
  }) async {
    final url = Uri.parse('$baseUrl/api/ProfilesApi/EditProfile');

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['DisplayName'] = displayName;
    request.fields['IsPrivate'] = isPrivate.toString();
    
    if (bio != null && bio.isNotEmpty) {
      request.fields['Bio'] = bio;
    }
    
    if (birthDate != null) {
      request.fields['BirthDate'] = birthDate.toIso8601String();
    }

    if (avatarFile != null) {
      var fileStream = http.ByteStream(avatarFile.openRead());
      var fileLength = await avatarFile.length();
      var multipartFile = http.MultipartFile(
        'AvatarFile',
        fileStream,
        fileLength,
        filename: avatarFile.path.split('/').last,
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
          'message': data['message'],
          'profile': data['profile'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating profile: $e',
      };
    }
  }
}


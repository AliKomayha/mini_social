import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiService {
  static const String baseUrl = "${AppConfig.baseUrl}/api/AuthApi";

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'token': data['token'],
        'userId': data['userId'],
        'userName': data['userName'],
        'message': data['message'],
      };
    } else {
      final error = jsonDecode(response.body);
      return {
        'success': false,
        'message': error['message'] ?? 'Login failed',
      };
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    final url = Uri.parse('$baseUrl/signup');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'displayName': displayName,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'],
        'userId': data['userId'],
        'username': data['username'],
      };
    } else {
      final error = jsonDecode(response.body);
      return {
        'success': false,
        'message': error['message'] ?? 'Signup failed',
      };
    }
  }
}

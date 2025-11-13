import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'LoginScreen.dart';
import 'config.dart';

void main() {
  runApp(const MyApp());
}
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, dynamic>?> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('userId');
    
    if (token != null && userId != null) {
      return {
        'token': token,
        'userId': userId,
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final userData = snapshot.data;
          if (userData != null) {
            return Home(
              currentUserId: userData['userId'],
              token: userData['token'],
              baseUrl: AppConfig.baseUrl,
            );
          }
          return const LoginScreen();
        },
      ),

    );
  }
}

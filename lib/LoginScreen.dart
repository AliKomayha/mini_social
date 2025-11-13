import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'home.dart';
import 'config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);

    final username = usernameController.text;
    final password = passwordController.text;

    //call api
    final result = await ApiService.login(username, password);

    setState(() => isLoading = false);

    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      final token = result['token'];
      final userId = result['userId'];
      await prefs.setString('token', token);
      await prefs.setInt('userId', userId);
      await prefs.setString('userName', result['userName']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Home(
            currentUserId: userId,
            token: token,
            baseUrl: AppConfig.baseUrl,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'])));
    }



  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: usernameController,decoration:  InputDecoration(labelText: 'Username'),),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: Text('Login'))

          ],
        ),

      ),
    );
  }
}

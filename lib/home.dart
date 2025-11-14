import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'profile_screen.dart';
import 'Search.dart';
import 'LoginScreen.dart';
import 'main.dart';
import 'config.dart';
import 'follow_requests.dart';
import 'feed_widget.dart';
import 'create_post_screen.dart';

class Home extends StatefulWidget {
  final int currentUserId;
  final String token;
  final String baseUrl;
  const Home({
    super.key,
    required this.currentUserId,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  String? token;
  int? userId;
  final String baseUrl = AppConfig.baseUrl;
  final GlobalKey<FeedWidgetState> _feedWidgetKey = GlobalKey<FeedWidgetState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
      userId = prefs.getInt('userId');
    });
  }

  void _refreshFeed() {
    _feedWidgetKey.currentState?.refresh();
  }

  // All pages go here
  List<Widget> get _pages => [
    FeedWidget(key: _feedWidgetKey, token: token!, baseUrl: baseUrl), // Home screen content
    Profile(userId: userId!, token: token!, baseUrl: baseUrl ),
    const Search(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  //log out
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/AuthApi/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await prefs.clear();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      } else {
        print('Logout failed: ${response.body}');
      }
    } catch (e) {
      print('Logout error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {

    if (token == null || userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniSocial'),
        centerTitle: true,
        backgroundColor: Colors.grey,

      ),

      body:  _pages[_selectedIndex],

      floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatePostScreen(
                  onPostCreated: _refreshFeed,
                ),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(child: Text('Menu')),
              ListTile(title: Text('Profile')),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Follow Requests'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FollowRequestsScreen(token: token!),
                    ),
                  );
                },
              ),
              ListTile(title: Text('Settings')),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout'),
                onTap: () =>  logout(context),
              ),
            ],
          ),
        ),

      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),


      ]),

    );
  }
}

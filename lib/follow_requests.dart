import 'package:flutter/material.dart';
import 'package:mini_social/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FollowRequestsScreen extends StatefulWidget {
  final String token;

  const FollowRequestsScreen({super.key, required this.token});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  List<dynamic> requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/ProfilesApi/FollowRequests'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      setState(() {
        requests = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load follow requests')),
      );
    }
  }

  Future<void> _handleRequest(int followId, bool accept) async {
    final endpoint = accept ? 'AcceptRequest' : 'DeclineRequest';
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/ProfilesApi/$endpoint/$followId'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      setState(() {
        requests.removeWhere((r) => r['id'] == followId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Follow Requests')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(child: Text('No pending requests'))
          : ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final r = requests[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: r['avatar'] != null && r['avatar'] != ''
                    ? NetworkImage('${AppConfig.baseUrl}${r['avatar']}')
                    : null,
                child: r['avatar'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(r['displayName'] ?? r['username']),
              subtitle: Text('@${r['username']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _handleRequest(r['id'], true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _handleRequest(r['id'], false),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

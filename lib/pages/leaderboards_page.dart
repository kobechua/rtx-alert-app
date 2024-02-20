import 'package:flutter/material.dart';

class LeaderboardsPage extends StatelessWidget {
  LeaderboardsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for the leaderboard
    final List<Map<String, dynamic>> leaderboardData = [
      {"name": "User 1", "score": 100},
      {"name": "User 2", "score": 90},
      {"name": "User 3", "score": 80},
      // Add more data as needed
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.black87,
      ),
      body: ListView.builder(
        itemCount: leaderboardData.length,
        itemBuilder: (context, index) {
          final item = leaderboardData[index];
          return ListTile(
            leading: Text("#${index + 1}"),
            title: Text(item['name']),
            trailing: Text("${item['score']} points"),
          );
        },
      ),
    );
  }
}

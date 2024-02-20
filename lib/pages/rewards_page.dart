import 'package:flutter/material.dart';

class RewardsPage extends StatelessWidget {
  RewardsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for rewards
    final List<Map<String, dynamic>> rewardsData = [
      {"title": "Reward 1", "description": "This is reward 1 description."},
      {"title": "Reward 2", "description": "This is reward 2 description."},
      {"title": "Reward 3", "description": "This is reward 3 description."},
      // Add more data as needed
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rewards',
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
        itemCount: rewardsData.length,
        itemBuilder: (context, index) {
          final reward = rewardsData[index];
          return Card(
            child: ListTile(
              title: Text(reward['title']),
              subtitle: Text(reward['description']),
              onTap: () {
                // Handle the tap action
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Reward Details"),
                    content: Text(reward['description']),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

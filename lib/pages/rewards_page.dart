import 'package:flutter/material.dart';

class RewardsPage extends StatelessWidget {
  RewardsPage({Key? key}) : super(key: key);

  // Updated dummy data for rewards with "points" field
  final List<Map<String, dynamic>> rewardsData = [
    {
      "title": "RTX Bronze Badge",
      "description": "A commendable achievement for dedicated newcomers.",
      "image": "lib/images/bronzebadge.png",
      "points": "5000 Points",
    },
    {
      "title": "RTX Silver Badge",
      "description": "A mark of consistency and progress.",
      "image": "lib/images/silverbadge.png",
      "points": "10000 Points",
    },
    {
      "title": "RTX Gold Badge",
      "description": "A symbol of exceptional dedication and skill.",
      "image": "lib/images/goldbadge.png",
      "points": "15000 Points",
    },
    {
      "title": "Jay's Badge",
      "description": "The pinnacle of achievement, reserved for true visionaries.",
      "image": "lib/images/diamondbadge.png",
      "points": "20000 Points",
    },
  ];

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: Colors.grey[900], // Dark grey background
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "- BADGES -",
              style: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rewardsData.length,
              itemBuilder: (context, index) {
                final reward = rewardsData[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Image.asset(
                          reward['image'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reward['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(reward['description']),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              reward['points'], // Display points required for each badge
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Handle claim reward action
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87, // Button color
                              ),
                              child: const Text(
                                'Claim',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

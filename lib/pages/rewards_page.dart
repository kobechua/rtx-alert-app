import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  _RewardsPageState createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  Future<int>? _userPointsFuture;

  @override
  void initState () {
    super.initState();
    _userPointsFuture = getUserPoints();
  }
  
  // Function to fetch the user's points from Firebase
  Future<int> getUserPoints() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseDatabase.instance.ref('UserData/$uid/points').get();
    if (snapshot.exists) {
      return int.parse(snapshot.value.toString());
    } else {
      return 0; // Default to 0 if points are not found
    }
  }
  // Updated dummy data for rewards with "points" field
  final List<Map<String, dynamic>> badges = [
    {
      "title": "RTX Bronze Badge",
      "description": "A commendable achievement for dedicated newcomers.",
      "image": "lib/images/bronzebadge.png",
      "points": 5000,
    },
    {
      "title": "RTX Silver Badge",
      "description": "A mark of consistency and progress.",
      "image": "lib/images/silverbadge.png",
      "points": 10000,
    },
    {
      "title": "RTX Gold Badge",
      "description": "A symbol of exceptional dedication and skill.",
      "image": "lib/images/goldbadge.png",
      "points": 15000,
    },
    {
      "title": "Jay's Badge",
      "description": "The pinnacle of achievement, reserved for true visionaries.",
      "image": "lib/images/diamondbadge.png",
      "points": 20000,
    },
  ];

  final List<Map<String, dynamic>> otherRewards = [
    {
      "title": "RTX Gift Card",
      "description": "Redeemable gift card for RTX goodies.",
      "image": "lib/images/cargiftcard.png",
      "points": 25000,
    },
    {
      "title": "Raytheon T-Shirt",
      "description": "Show off your style!",
      "image": "lib/images/carshirt.png",
      "points": 30000,
    },
    
  ];

  void updateUserPoints() {
    setState(() {
      _userPointsFuture = getUserPoints();
    });
  }

  void showConfirmationDialog(int requiredPoints, String rewardTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Redeem Reward"),
          content: Text("Are you sure you want to redeem $rewardTitle for $requiredPoints points?"),
          actions: <Widget>[
            TextButton(
              child: const Text("No"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Yes"),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the confirmation dialog immediately.
                final userPoints = await getUserPoints();
                if (userPoints >= requiredPoints) {
                  final String? uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    // Subtract the required points for the reward and update in Firebase.
                    int newPoints = userPoints - requiredPoints;
                    try {
                      await FirebaseDatabase.instance.ref('UserData/$uid/points').set(newPoints);
                      updateUserPoints();
                      if (!mounted) return;
                      // Show success dialog only after successful update.
                      
                      showSuccessDialog(rewardTitle);
                    } catch (e) {
                      // Handle any errors that occur during the update
                      print("Error updating points: $e");
                      // Optionally, show an error dialog to the user
                    }
                  }
                } else {
                  if (!mounted) return;
                  // Show not enough points dialog.
                  showNotEnoughPointsDialog();
                }
              },
            ),
          ],
        );
      },
    );
  }



void attemptClaimReward(int requiredPoints, String rewardTitle) {
  getUserPoints().then((userPoints) {
    if (!mounted) return;

    if (userPoints >= requiredPoints) {
      // User has enough points; ask for confirmation to claim the reward.
      showConfirmationDialog(requiredPoints, rewardTitle);
    } else {
      // User does not have enough points; show a dialog informing them.
      showNotEnoughPointsDialog();
    }
  });
}



void showSuccessDialog(String rewardTitle) {
  if (!mounted) return;
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Reward Claimed!"),
        content: Text("You have successfully claimed the $rewardTitle."),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop(); // Close the success dialog.
            },
          ),
        ],
      );
    },
  );
}

void showNotEnoughPointsDialog() {
  if (!mounted) return;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Not Enough Points"),
        content: const Text("You do not have enough points to claim this reward."),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}






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
        actions: <Widget>[
          FutureBuilder<int>(
            future: _userPointsFuture,
            builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      "${snapshot.data} Points",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              } else {
                // Show loading indicator or placeholder while data is loading
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }
            },
          ),
        ],
      ),
      
      backgroundColor: Colors.grey[900], // Dark grey background
      body: SingleChildScrollView(
        child: Column(
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
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55, // Adjust the height as needed
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true, 
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final reward = badges[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0).copyWith(
                      bottom: index == badges.length - 1 ? 0 : 8.0, //remove bottom padding of the last item
                    ),
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
                                "${reward['points']} Points", // Convert points to string for display
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),

                              ElevatedButton(
                                onPressed: () => attemptClaimReward(reward['points'], reward['title']),
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
             const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "- OTHER -",
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3, // Adjust the height as needed
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true, 
                itemCount: otherRewards.length,
                itemBuilder: (context, index) {
                  final reward = otherRewards[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0).copyWith(
                      bottom: index == otherRewards.length - 1 ? 0 : 8.0, //remove bottom padding of the last item
                    ),
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
                                "${reward['points']} Points", // Convert points to string for display
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),

                              ElevatedButton(
                                onPressed: () => attemptClaimReward(reward['points'], reward['title']),
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
      ),
    );
  }
}

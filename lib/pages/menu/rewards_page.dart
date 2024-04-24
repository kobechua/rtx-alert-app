import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  _RewardsPageState createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  List<String> _claimedBadges = [];
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final data = await getUserData();
    setState(() {
      _userPoints = data['points'];
      _claimedBadges = [];
      if (data['badges'] != null) {
        for (var item in data['badges']) {
          if (item is String) {
            _claimedBadges.add(item);
          } else {
            // Optionally handle unexpected data types, log them, or ignore
            debugPrint('Unexpected data type in badges list: ${item.runtimeType}');
          }
        }
      }
    });
  }

  Future<Map<String, dynamic>> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseDatabase.instance.ref('UserData/$uid').get();
    if (snapshot.exists) {
      var points = snapshot.child('points').value;
      var badgesSnapshot = snapshot.child('badges').value;
    
      // Initialize points
      int parsedPoints = 0;
      if (points != null) {
        parsedPoints = int.tryParse(points.toString()) ?? 0;
      }

      // Prepare the badges list
      List<String> badgesList = [];
      if (badgesSnapshot != null && badgesSnapshot is List<dynamic>) {
        badgesList = badgesSnapshot.cast<String>();
      }

      return {
        'points': parsedPoints,
        'badges': badgesList,
      };
    } else {
      return {'points': 0, 'badges': []}; // Default values if user data not found
    }
  }

  void attemptClaimReward(int requiredPoints, String rewardTitle, bool isBadge) {
    if (_userPoints >= requiredPoints) {
      showConfirmationDialog(requiredPoints, rewardTitle, isBadge);
    } else {
      showNotEnoughPointsDialog();
    }
  }

  void showConfirmationDialog(int requiredPoints, String rewardTitle, bool isBadge) {
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
                Navigator.of(context).pop();
                bool result = await claimBadge(rewardTitle, requiredPoints, isBadge);
                if (result) {
                  showSuccessDialog(rewardTitle);
                } else {
                  showNotEnoughPointsDialog();
                }
              },
            ),
          ],
        );
      },
    );
  }


  // Method to claim a badge
// Method to claim a reward. It now takes an additional boolean parameter isBadge
Future<bool> claimBadge(String badgeTitle, int points, bool isBadge) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;

  final ref = FirebaseDatabase.instance.ref('UserData/$uid');

  // Deduct points
  await ref.child('points').set(_userPoints - points);
  
  // If it's a badge, add it to the list and update Firebase
  if (isBadge) {
    final snapshot = await ref.child('badges').get();
    List<String> currentBadges = snapshot.exists && snapshot.value != null
        ? List<String>.from(snapshot.value as List<dynamic>)
        : [];

    if (currentBadges.contains(badgeTitle)) return false; // Badge already claimed

    currentBadges.add(badgeTitle);
    await ref.child('badges').set(currentBadges); // Update Firebase with the new list of badges
  }
  
  // Refresh local user data
  _fetchUserData();
  
  return true; // Indicates success
}

  

  void showSuccessDialog(String rewardTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reward Claimed!"),
          content: Text("You have successfully claimed the $rewardTitle."),
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

  void showNotEnoughPointsDialog() {
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

Widget _buildBadgeRow(Map<String, dynamic> reward, bool isBadge) {
  bool isClaimed = _claimedBadges.contains(reward['title']);
  bool isClaimable = false;

  if (isBadge) {
    int lastClaimedIndex = _claimedBadges.isNotEmpty
        ? badges.indexWhere((b) => b['title'] == _claimedBadges.last)
        : -1;
    int currentBadgeIndex = badges.indexWhere((b) => b['title'] == reward['title']);
    isClaimable = (lastClaimedIndex != -1 && currentBadgeIndex == lastClaimedIndex + 1) ||
                  (lastClaimedIndex == -1 && currentBadgeIndex == 0);
  } else {
    isClaimable = true;  // Other rewards are always claimable
  }

  return Card(
    child: ListTile(
      leading: Image.asset(reward['image'], fit: BoxFit.cover, width: 40),
      title: Text(reward['title'], style: const TextStyle(fontSize: 14)),
      subtitle: Text(reward['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Container(
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${reward['points']} Points', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (isClaimed)
              const Text('Claimed', style: TextStyle(fontSize: 12))
            else if (isClaimable)
              Flexible(
                child: ElevatedButton(
                  onPressed: () => attemptClaimReward(reward['points'], reward['title'], isBadge),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    textStyle: const TextStyle(fontSize: 10),  // Adjust font size if necessary
                    minimumSize: const Size(60, 30),  // Check if reducing size helps
                  ),
                  child: const Text('Claim'),
                ),
              )
            else
              const Text('Locked', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), // Consider reducing horizontal padding
            child: Center(
              child: Text(
                "$_userPoints Points",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView( // Ensure this is here
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0), // Check padding here, reduce if necessary
              child: Text(
                "- BADGES -",
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // To handle scrolling within a scrollable view
              itemCount: badges.length,
              itemBuilder: (context, index) => _buildBadgeRow(badges[index], true),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0), // Check padding here, reduce if necessary
              child: Text(
                "- OTHER REWARDS -",
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // To handle scrolling within a scrollable view
              itemCount: otherRewards.length,
              itemBuilder: (context, index) => _buildBadgeRow(otherRewards[index], false),
            ),
          ],
        ),
      ),
    );
  }

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
}
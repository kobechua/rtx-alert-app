import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  Future<List<LeaderboardUser>> fetchLeaderboardUsers() async {
    DataSnapshot snapshot = await FirebaseDatabase.instance.ref('UserData').orderByChild('points').get();
    List<LeaderboardUser> users = [];
    for (var element in snapshot.children) {
      users.add(LeaderboardUser(
        uid: element.key!,
        email: element.child('email').value?.toString() ?? 'Anonymous', // Fallback to 'Anonymous' if name is null
        points: int.parse(element.child('points').value?.toString() ?? '0'), // Fallback to 0 if points is null
      ));
    }
    // Sort users based on points in descending order
    users.sort((a, b) => b.points.compareTo(a.points));
    return users;
  }

@override
Widget build(BuildContext context) {
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
    backgroundColor: Colors.grey[900],
    body: FutureBuilder<List<LeaderboardUser>>(
      future: fetchLeaderboardUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final users = snapshot.data!;
          final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
          final currentUserIndex = users.indexWhere((user) => user.uid == currentUserUid);
          final currentUser = currentUserIndex != -1 ? users[currentUserIndex] : null;

          List<Widget> listItems = [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Top 3",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ];

          // Add top 3 users
          listItems.addAll(users.take(3).map((user) => buildUserTile(user, users.indexOf(user) + 1, user.uid == currentUserUid)));

          // Always show the current user at the end if they are not in the top 3 or for quick access
          if (currentUser != null) {
            listItems.add(const Divider());
            listItems.add(
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Your Ranking",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
            listItems.add(buildUserTile(currentUser, currentUserIndex + 1, true));
          }

          return ListView(children: listItems);
        } else if (snapshot.hasError) {
          return Text("Error fetching leaderboard: ${snapshot.error}");
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    ),
  );
}

Widget buildUserTile(LeaderboardUser user, int rank, bool isCurrentUser) {
  return ListTile(
    leading: Text("#$rank", style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 15, fontWeight: FontWeight.bold)),
    title: Text(user.email, style: const TextStyle(color: Colors.white)),
    trailing: Text("${user.points} pts", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    tileColor: isCurrentUser ? Colors.yellow[700] : null, // Highlight if current user
  );
}



}

class LeaderboardUser {
  final String uid;
  final String email;
  final int points;

  LeaderboardUser({required this.uid, required this.email, required this.points});
}

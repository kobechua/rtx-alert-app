import 'package:flutter/material.dart';
import 'package:rtx_alert_app/pages/camera.dart';
import 'package:rtx_alert_app/pages/login_or_signup.dart';
import 'package:rtx_alert_app/services/auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final FirebaseAuthService auth = FirebaseAuthService();

  void signOut(){
    auth.signOut();
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPageOrSignUp()));

  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Home Page"),
            GestureDetector(
              onTap: () => signOut(),
              child: const Text("Sign Out"),
            ),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CameraPage())),
              child: const Text("Camera"),
            )
          ],
        )
      )
    );
  }
}
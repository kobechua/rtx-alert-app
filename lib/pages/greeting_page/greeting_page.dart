import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rtx_alert_app/pages/home_page.dart';
import 'login.dart';
import 'signup.dart';

class GreetingPage extends StatefulWidget {
  const GreetingPage({super.key});

  @override
  State<GreetingPage> createState() => _GreetingPageState();
}

class _GreetingPageState extends State<GreetingPage> {
  
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      
      showLoginPage = !showLoginPage;
    });
  }
  
  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        if (snapshot.hasData){
          return const HomePage();
        } else {
          if (showLoginPage) {
            return LoginPage(
              onTap: togglePages,
            );
          } else {
            return SignUpPage(
              onTap: togglePages,
            );
          }
        }
      }
    );
  }
}
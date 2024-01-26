import 'package:flutter/material.dart';
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
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'sign_up_page.dart';

class LoginPageOrSignUp extends StatefulWidget {
  const LoginPageOrSignUp({super.key});

  @override
  State<LoginPageOrSignUp> createState() => _LoginPageOrSignUpState();
}

class _LoginPageOrSignUpState extends State<LoginPageOrSignUp> {
  
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
// import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:rtx_alert_app/components/my_button.dart';
// import 'package:rtx_alert_app/pages/home.dart';
// import 'package:rtx_alert_app/pages/home_page.dart';
import 'package:rtx_alert_app/services/auth.dart';


class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}



class _LoginPageState extends State<LoginPage> {

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void dispose(){
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final FirebaseAuthService auth = FirebaseAuthService();

    void signIn() async {
      String email = emailController.text;
      String password = passwordController.text;

      await auth.signInWithEmailAndPassword(email, password);


      // if (!context.mounted) return;
      // if (user != null){
      //   Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
      // }
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
      
      
            const Text("RTX Alert App", style: TextStyle(
              color: Colors.black, 
              fontSize:28.0, 
              fontWeight: FontWeight.bold,
              )
            ),
      
      
            const Text(
              "Login Page",
              style: TextStyle(
                color: Colors.black,
                fontSize: 44.0,
                fontWeight: FontWeight.bold
              ),
            ),
      
            //Email Field
            const SizedBox(        
              height: 44.0
            ),
      
      
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: emailController,
                keyboardType:  TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "Email",
                  prefixIcon: Icon(Icons.mail, color: Colors.black)
                )
              ),
            ),
      
            //Password Field
            const SizedBox(
              height: 28.0
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Password",
                  prefixIcon: Icon(Icons.password, color: Colors.black)
                )
              )
            ),


            const SizedBox(
              height: 25.0,
            ),

            // log in button
            MyButton(
              onTap: signIn,
              text: 'Sign In',
            ),
      
            const SizedBox(
              height: 25.0,
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Not a member?'),
                const SizedBox(width: 4),
                
                GestureDetector(
                  onTap: widget.onTap,
                  child: const Text(
                    'Create an account',
                    style: TextStyle(
                      color: Colors.blue, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


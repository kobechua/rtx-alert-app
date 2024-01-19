import 'package:flutter/material.dart';
import 'package:rtx_alert_app/components/my_button.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

void signUserIn() {
  // TODO: implement signUserIn
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
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
      
      
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                keyboardType:  TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email",
                  prefixIcon: Icon(Icons.mail, color: Colors.black)
                )
              ),
            ),
      
            //Password Field
            const SizedBox(
              height: 28.0
            ),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
                prefixIcon: Icon(Icons.password, color: Colors.black)
              )
            ),

            const SizedBox(
              height: 25.0,
            ),

            // log in button
            const MyButton(
              onTap: signUserIn,
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

import 'package:flutter/material.dart';
import 'package:rtx_alert_app/components/my_button.dart';
import 'package:rtx_alert_app/services/auth.dart';
import 'package:rtx_alert_app/pages/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';

class SignUpPage extends StatefulWidget {
  final Function()? onTap;
  const SignUpPage({super.key, this.onTap});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose(){
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    final FirebaseAuthService auth = FirebaseAuthService();

    void signUp() async {
      String email = emailController.text;
      String password = passwordController.text;
      String confirmPassword = confirmPasswordController.text;

      if (password.isEmpty){
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password cannot be empty.")));
      }
      else if (password != confirmPassword){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match.")));
      }
      else{
        User? user = await auth.signUpWithEmailAndPassword(email, password);

        if (!context.mounted) return;
        if (user != null){
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Success.")));
          Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
        }
      }
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
              "Sign Up Page",
              style: TextStyle(
                color: Colors.black,
                fontSize: 44.0,
                fontWeight: FontWeight.bold
              ),
            ),
                
            //Email Field
            const SizedBox(        
              height: 34.0
            ),
                
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
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
              height: 10.0
            ),
          
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(

                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Password",
                  prefixIcon: Icon(Icons.password, color: Colors.black)
                )
              )
            ),
            //Confirm Password Field
            const SizedBox(
              height: 10.0
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Confirm Password",
                  prefixIcon: Icon(Icons.password, color: Colors.black)
                )
              )
            ),
          
          
            const SizedBox(
              height: 17.0,
            ),
          
            // log in button
            MyButton(
              onTap: signUp,
              text: 'Create Account',
            ),
                
            const SizedBox(
              height: 17.0,
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?'),
                const SizedBox(width: 4),
                
                GestureDetector(
                  onTap: widget.onTap,
                  child: const Text(
                    'Login',
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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:rtx_alert_app/components/my_button.dart';

class SubmissionPage extends StatefulWidget {
  const SubmissionPage({super.key});
  

  @override
  State<SubmissionPage> createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {

  late List<Map<String, dynamic>> submissions;
  final FirebaseAuth auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;

  void getSubmissions() async {
    final storageRef = FirebaseStorage.instance.ref().child("/submissions/${user!.uid}/");
    final listResult = await storageRef.listAll();
    debugPrint("here ${storageRef.name}");
    debugPrint("here ${listResult.items}");
    for (var i in listResult.items){
      debugPrint(i.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    getSubmissions();
    return Scaffold(


      body: MyButton(
        text: "Back",
        onTap: () {Navigator.pop(context);}
      ),
    );
  }
}
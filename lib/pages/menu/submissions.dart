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

  late Map<String, List<Reference>> submissions;
  final FirebaseAuth auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;

  void getSubmissions() async {
    final storage = FirebaseStorage.instance;
    Map<String, List<Reference>> list = {};
    final dir =  storage.ref().root.child("/submissions/${user!.uid}/");
    // final listResult = await dir.root.child("/submissions/${user!.uid}/").listAll();
    final listResult = await dir.listAll();
    for (var i in listResult.prefixes){
      final contents = await i.list();
      debugPrint(i.name);
      list[i.name] = contents.items;
    }
    
    //print the list
    debugPrint("User Submissions\n-----------------\n");
    for (var key in list.keys){
      debugPrint("\n$key");
      if (list[key]!.isNotEmpty){
        for (var ent in list[key]!){
          debugPrint(ent.fullPath);
        }
      }
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
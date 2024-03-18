import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubmissionPage extends StatefulWidget {
  const SubmissionPage({super.key});
  

  @override
  State<SubmissionPage> createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {

  late List<Map<String, dynamic>> badges;
    final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(

    );
  }
}
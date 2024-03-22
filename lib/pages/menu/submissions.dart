// import 'dart:convert';
// import 'package:flutter/foundation.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';
// import 'package:rtx_alert_app/components/my_button.dart';

class SubmissionPage extends StatefulWidget {
  const SubmissionPage({super.key});


  @override
  State<SubmissionPage> createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {

  final FirebaseAuth auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> submission = [];
  String imageUrl = '';

  @override
  void initState() {
    super.initState();
    getSubmissions();
  }

  Future<List<Map<String, dynamic>>> getSubmissions() async {
    final storage = FirebaseStorage.instance;
    List<Map<String, dynamic>> list = [];
    final dir =  storage.ref().root.child("/submissions/${user!.uid}/");

    final listResult = await dir.listAll();
    for (var i in listResult.prefixes){
        await dir.child("${i.name}/photo.jpg").getDownloadURL().then((url) {
          // debugPrint("URL HERE $url");
          setState(() {
            imageUrl = url;
          });
          list.add({
          'name' : i.name,
          'photo' : url, 
          'metadata' : i.child("metadata.jpg")});
      }
      );
      // final contents = await i.list();


      // debugPrint(i.name);
      // list.add({
      //   'name' : i.name,
      //   'photo' : imageUrl, 
      //   'metadata' : contents.items.last});
    }
    
    setState(() {
      submission = [...list];
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(submission.length.toString());

    debugPrint("Start here");
    for (var listIndex in submission){
      debugPrint(listIndex['photo']);
    }
    debugPrint("End here");
    return Scaffold(

// HERE
      appBar: AppBar(
        title: const Text(
          'Submissions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.black87,
      ),
      backgroundColor: Colors.grey[900], // Dark grey background
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Submissions",
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8, // Adjust the height as needed
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true, 
                itemCount: submission.length,
                itemBuilder: (context, index) {
                  
                  final data = submission[index];

                  return Card(
                    margin: const EdgeInsets.all(8.0).copyWith(
                      bottom: index == submission.length - 1 ? 0 : 8.0, //remove bottom padding of the last item
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // Image.asset(
                          //   data['photo'],
                          //   width: 60,
                          //   height: 60,
                          //   fit: BoxFit.cover,
                          // ),
                          // if (data['photo'].toString() == "") 
                            Image.network(
                              data['photo'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,  
                            )
                          ,
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Text(reward['description']),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Text(
                              //   reward['points'], // Display points required for each badge
                              //   style: const TextStyle(
                              //     fontWeight: FontWeight.bold,
                              //     color: Colors.black54,
                              //   ),
                              // ),
                              ElevatedButton(
                                onPressed: () {
                                  // Handle claim reward action
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87, // Button color
                                ),
                                child: const Text(
                                  'View',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ]
       )
      )
    );
  }
}
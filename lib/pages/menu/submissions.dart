// import 'dart:convert';
// import 'package:flutter/foundation.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';

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
    getSubmissionsDB();
  }

  // Future<List<Map<String, dynamic>>> getSubmissions() async {
  //   final storage = FirebaseStorage.instance;
  //   List<Map<String, dynamic>> list = [];
  //   final dir =  storage.ref().root.child("/submissions/${user!.uid}/");

  //   final listResult = await dir.listAll();
  //   int listidx = 0;
  //   for (var i in listResult.items){
      
  //     debugPrint(i.name);
  //     if (i.name.endsWith('photo.jpg')) {
  //       listidx++;
  //         await dir.child(i.name).getDownloadURL().then((url) {
  //         setState(() {
  //           imageUrl = url;
  //         });
  //         list.add({
  //         'name' : listidx.toString(),
  //         'photo' : url, 
  //         'metadata' : i.child("metadata.json")});
  //     }
  //     );
  //   }

  //   }
    
  //   setState(() {
  //     submission = [...list];
  //   });

  //   return list;
  // }

  Future<List<Map<String, dynamic>>> getSubmissionsDB() async {
    final database = FirebaseDatabase.instance;
    List<Map<String, dynamic>> list = [];
    final dir = database.ref('UserData/${user!.uid}/submissions');
    final DataSnapshot snapshot = await dir.get();

    if (snapshot.exists) {
            Map<dynamic, dynamic> submissions = snapshot.value as Map<dynamic, dynamic>;
      submissions.forEach((key, value) {
        // Assuming 'photo' is the URL to the photo and there's a 'metadata' object
        // debugPrint('submissions: $key');
        final entry = {
          'name': key, // Or any other identifier you use for submissions
          'photo': value['photo'],
          'data': value['data'], // This will be a Map if your metadata is structured
        };
        list.add(entry);
      });
    } else {
      debugPrint("No submissions found.");
    }
    setState(() {
      submission = [...list];
    });
    return list;
  }

  

  @override
  Widget build(BuildContext context) {
    // debugPrint(submission.length.toString());

    // debugPrint("Start here");
    // for (var listIndex in submission){
    //   debugPrint(listIndex['photo']);
    // }
    // debugPrint("End here");
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
            // const Padding(
            //   padding: EdgeInsets.all(8.0),
            //   child: Text(
            //     "Submissions",
            //     style: TextStyle(
            //       fontSize: 28.0,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.white,
            //     ),
            //   ),
            // ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8, // Adjust the height as needed
              child: ListView.builder(
                // physics: const NeverScrollableScrollPhysics(),
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
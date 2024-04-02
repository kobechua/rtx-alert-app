// import 'dart:convert';
// import 'package:flutter/foundation.dart';

import 'dart:convert';

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
 
  // Future<List<Map<String, dynamic>>> getSubmissionsDB() async {
  //   final database = FirebaseDatabase.instance;
  //   List<Map<String, dynamic>> list = [];
  //   final dir = database.ref('UserData/${user!.uid}/submissions');
  //   final DataSnapshot snapshot = await dir.get();

  //   if (snapshot.exists) {
  //           Map<dynamic, dynamic> submissions = snapshot.value as Map<dynamic, dynamic>;
  //     submissions.forEach((key, value) {
  //       // Assuming 'photo' is the URL to the photo and there's a 'metadata' object
  //       debugPrint('submissions- ${value['data']}');
  //       Map<String, dynamic> decodedData = json.decode(value['data']);
  //       debugPrint('decode: ${decodedData['alt']}');
  //       final entry = {
  //         'name': key, // Or any other identifier you use for submissions
  //         'photo': value['photo'],
  //         'data': jsonDecode(value['data']), // This will be a Map if your metadata is structured
  //       };
  //       list.add(entry);
  //     });
  //   } else {
  //     debugPrint("No submissions found.");
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
      debugPrint('submissions- ${value['data']}');
      
      // Ensure key is a String and value is properly casted
      String submissionKey = key as String;
      Map<String, dynamic> submissionValue;
      if (value['data'] is String) {
        submissionValue = json.decode(value['data']);
      } else if (value is Map) {
        // Explicitly cast the keys and values to String and dynamic, respectively
        submissionValue = value.map<String, dynamic>((k, v) => MapEntry(k as String, v));
      } else {
        debugPrint('Unexpected data type for submission data');
        return; // Skip this iteration
      }

      debugPrint('decode: ${submissionValue}');
      final entry = {
        'name': submissionKey,
        'photo': submissionValue['photo'],
        'data': submissionValue, // Now directly usable
      };
      list.add(entry);
    });
  } else {
    debugPrint("No submissions found.");
  }

  // Assuming you have a way to call setState outside of this context, otherwise this line needs adjustment
  setState(() {
    submission = [...list];
  });

  return list;
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(

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
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8, // Adjust the height as needed
              child: ListView.builder(
                // physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true, 
                itemCount: submission.length,
                itemBuilder: (context, index) {
                  
                  final Map<String, dynamic> data = submission[index];
                  final Map<String, dynamic> metadata = submission[index]['data'];

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
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog.fullscreen(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget> [
                                          SizedBox(
                                            width: 500,
                                            height: 500,
                                            child: Image.network(data['photo'], fit: BoxFit.contain),
                                          ),
                                          
                                          Text(metadata['date'].toString()),
                                          Text('Location \nLongitude: ${metadata['data']['long']}, Latitude: ${metadata['data']['lat']}'),
                                          const SizedBox(height: 15),

                                          TextButton(
                                            onPressed: () {
                                            Navigator.pop(context);
                                          },

                                          child: const Text('Close'))
                                        ]
                                      )
                                    )
                                    );
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
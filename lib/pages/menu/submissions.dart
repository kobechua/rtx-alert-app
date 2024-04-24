// import 'dart:convert';
// import 'package:flutter/foundation.dart';

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

List<Map<String, dynamic>> sortListOfMapsByDateKey(List<Map<String, dynamic>> list, String dateKey) {
  list.sort((a, b) {
    // Converting string to DateTime objects
    DateTime firstDate = DateFormat('yyyy-MM-dd').parse(a[dateKey] ?? '0001-01-01');
    DateTime secondDate = DateFormat('yyyy-MM-dd').parse(b[dateKey] ?? '0001-01-01');
    return firstDate.compareTo(secondDate);
  });

  return list;
}

Future<List<Map<String, dynamic>>> getSubmissionsDB() async {
  final database = FirebaseDatabase.instance;
  List<Map<String, dynamic>> list = [];
  final dir = database.ref('UserData/${user!.uid}/submissions');
  final DataSnapshot snapshot = await dir.get();

  if (snapshot.exists) {
    Map<dynamic, dynamic> submissions = snapshot.value as Map<dynamic, dynamic>;
    submissions.forEach((key, value) {
      debugPrint('submissions- ${value['status']}');

      String submissionKey = key as String;
      Map<String, dynamic> submissionValue;
      if (value['data'] is String) {
        submissionValue = json.decode(value['data']);
      } else if (value is Map) {

        submissionValue = value.map<String, dynamic>((k, v) => MapEntry(k as String, v));
      } else {
        debugPrint('Unexpected data type for submission data');
        return; 
      }
      debugPrint(submissionValue.toString());
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
    submission = sortListOfMapsByDateKey(submission, 'name');
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
                                  metadata['status'] != 'Processing' ? 
                                  Text(
                                    '${data['name']}\nStatus: ${metadata['status']['Success'] ? "Car Detected"  : 'No Car Detected'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ) : 
                                  const Text('Processing',
                                      style:  TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    )
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
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget> [
                                          SizedBox(
                                            width: 500,
                                            height: 500,
                                            child: Image.network(data['photo'], fit: BoxFit.contain),
                                          ),

                                         
                                          metadata['status'] != 'Processing' ? 
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text('Date: ${metadata['date'].toString()}'),
                                              const Text('Location',
                                                style :   TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                              ),
                                              Text('Longitude: ${metadata['data']['long']}, Latitude: ${metadata['data']['lat']}'),
                                              metadata['status']['Success'] == true
                                                  ? Column(
                                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                    children : [
                                                    const Text('Car Details',
                                                      style :  TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ), 
                                                    Text('Color: ${ metadata['status']['Color'] ?? 'NONE'}, ${(metadata['status']['C_prob']*100).toStringAsFixed(2) ?? 'NONE'}%\nMake, Model: ${ metadata['status']['Make'] ?? 'NONE'} ${metadata['status']['Model'] ?? 'NONE'}, ${(metadata['status']['MM_prob']*100).toStringAsFixed(2) ?? 'NONE'}%',)
                                                  ])
                                                  : const Text('No car detected in this picture'),
                                          ]
                                          )
                                          : const Text("Image is still processing"),
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
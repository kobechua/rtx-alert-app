import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class Storage {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  late User? user = auth.currentUser;

  Future<void> uploadPhoto(String filePath, String fileName) async {
    File file = File(filePath);

    if (user == null || user!.email == null) return;


    try {
      DateTime datetime = DateTime.now();


      final Directory directory = await getApplicationDocumentsDirectory();
      final File fileText = File('${directory.path}/myTextFile.json');
      await fileText.writeAsString('{"month" : ${datetime.month}}, "day" : ${datetime.day}}, "year" : ${datetime.year}}');

      await storage.ref('submissions/${user!.uid}/$datetime/photo.jpg').putFile(file);
      await storage.ref('submissions/${user!.uid}/$datetime/metadata.json').putFile(fileText);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  

}
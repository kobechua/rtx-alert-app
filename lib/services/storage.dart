import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:rtx_alert_app/services/location.dart';

class Storage {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseDatabase database = FirebaseDatabase.instance;
  LocationHandler location = LocationHandler();
  late User? user = auth.currentUser;

  

  Future<void> uploadPhoto(String filePath, String fileName, double azimuth) async {
    File file = File(filePath);
    Position pos = await location.getCurrentLocation();

    if (user == null || user!.email == null) return;


    try {
      DateTime datetime = DateTime.now();


      final Directory directory = await getApplicationDocumentsDirectory();
      final File fileText = File('${directory.path}/myTextFile.json');
      await fileText.writeAsString('{"month" : ${datetime.month}}, "day" : ${datetime.day}}, "year" : ${datetime.year}}');

      await storage.ref('submissions/${user!.uid}/${datetime}photo.jpg').putFile(file);
      await storage.ref('submissions/${user!.uid}/${datetime}metadata.json').putFile(fileText);

      String url = await storage.ref('submissions/${user!.uid}/${datetime}photo.jpg').getDownloadURL();
      debugPrint(url);
      database.ref().child('UserData/${user!.uid}').update({'latest_sub': url});
      database.ref().child('UserData/${user!.uid}/submissions').update(
        {

            '${datetime.month}-${datetime.day}-${datetime.year} ${datetime.hour}:${datetime.minute}:${datetime.second}' : {
                  'photo': url,
                  'date': datetime.toString(),
                  'data' : {'long' : pos.longitude, 'lat' : pos.latitude, 'alt' : pos.altitude, 'azimuth' : azimuth},
                  'status' : 'TBR'
              
              }
            
          }
      ).then((_) => debugPrint("Update successful"))
  .catchError((error) => debugPrint("Update failed: $error"));
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  

}
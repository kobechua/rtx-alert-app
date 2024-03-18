// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:rtx_alert_app/firebase_options.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:rtx_alert_app/pages/greeting_page/greeting_page.dart';

import 'package:provider/provider.dart';
import 'package:rtx_alert_app/pages/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';



void pingUser() async {
  DateTime datetime = DateTime.now();
  debugPrint("Pinged User: $datetime");
  FirebaseDatabase database = FirebaseDatabase.instance;
  
  
  final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
  final fcmToken = await FirebaseMessaging.instance.getToken();
  database.ref().child('Locations/$fcmToken').set({'last_location' : {'latitude': position.latitude, 'longitude': position.longitude, 'timestamp': datetime}});
}

void callbackDispatcher() {
 Workmanager().executeTask((task, inputData) {
 switch (task) {
  case pingUser:
    pingUser();
    break;
 }
 return Future.value(true);
 });
}

void schedulePeriodicTask() {
 Workmanager().registerPeriodicTask(
 'myPeriodicTask',
 'pingUser',
 frequency: const Duration(minutes: 15),
 inputData: <String, dynamic>{'key': 'value'},
 );
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    schedulePeriodicTask();
    return ChangeNotifierProvider(
        
        create: (context) => AppSettings()..loadSettings(),
        child: const MaterialApp(
          home: GreetingPage(),
        ),
      ); 
  }
}



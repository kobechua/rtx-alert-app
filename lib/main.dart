// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:rtx_alert_app/firebase_options.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rtx_alert_app/pages/greeting_page/greeting_page.dart';

import 'package:provider/provider.dart';
import 'package:rtx_alert_app/pages/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';

void pingUser() async {
  FirebaseDatabase database = FirebaseDatabase.instance;
  final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  final fcmToken = await FirebaseMessaging.instance.getToken();
  
  database.ref().child('Locations/$fcmToken').set({'last_location' : {'latitude': position.latitude, 'longitude': position.longitude}});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  pingUser();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppSettings()..loadSettings(),
      child: const MaterialApp(
        home: GreetingPage(),
      ),
    );

  }
}



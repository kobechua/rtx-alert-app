

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rtx_alert_app/firebase_options.dart';
import 'package:rtx_alert_app/services/location.dart';

void pingUser() async {
  DateTime datetime = DateTime.now();
  debugPrint("Pinged User: $datetime");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  FirebaseDatabase database = FirebaseDatabase.instance;
  
  await FirebaseMessaging.instance.requestPermission();

  final position = LocationHandler();
  Position pos = await position.getCurrentLocation();
  final fcmToken = await FirebaseMessaging.instance.getToken();
  database.ref().child('Locations/$fcmToken').set({'last_location' : {'latitude': pos.latitude, 'longitude': pos.longitude}, 'timestamp': datetime.toString()});
}


Future<void> handleBackgroundMessage(RemoteMessage message) async {
  pingUser();
  debugPrint("Title: ${message.notification?.title}");
  debugPrint("Body: ${message.notification?.body}");
  debugPrint("Data: ${message.data}");
}

class FirebaseMessagingAPI{

  final navigatorKey = GlobalKey<NavigatorState>();
  final firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initPushNotificatons() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true
    );
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen ((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      handleMessage(message);

    });
  }

  void handleMessage (RemoteMessage? message) {
    if (message == null) return;
    debugPrint("Title: ${message.notification?.title}");
    debugPrint("Body: ${message.notification?.body}");
    debugPrint("Data: ${message.data}");
  }



  Future<void> initNotifications() async {

    await firebaseMessaging.requestPermission();
    await initPushNotificatons();
    //store to user data in database

  }
}
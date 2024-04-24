

import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
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
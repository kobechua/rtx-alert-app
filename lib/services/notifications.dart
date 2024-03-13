import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseMessagingAPI{
  final firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await firebaseMessaging.requestPermission();
    final messagingToken = await firebaseMessaging.getToken();
    debugPrint(messagingToken);
    //store to user data in database
  }
}
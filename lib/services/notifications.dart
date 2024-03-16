import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseMessagingAPI{
  final firebaseMessaging = FirebaseMessaging.instance;
  final database = FirebaseDatabase.instance;

  // Future<void> initNotifications() async {
  //   database.ref().child('ActiveUsers/${auth.currentUser!.uid}').set({'sessionID' : convertedSessionID.toString()});
  //   await firebaseMessaging.requestPermission();
  //   final messagingToken = await firebaseMessaging.getToken();
  //   debugPrint(messagingToken);
  //   //store to user data in database
  // }
}
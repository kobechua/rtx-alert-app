import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingAPI{
  final firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await firebaseMessaging.requestPermission();
    final FCMToken = await firebaseMessaging.getToken();
    
  }
}
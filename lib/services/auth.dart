import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_core/firebase_core.dart' as firebase;
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:crypto/crypto.dart';
// import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';


class FirebaseAuthService {
  FirebaseAuth auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;
  FirebaseDatabase database = FirebaseDatabase.instance;
  // late Digest convertedSessionID;

  // Future<void> createToken() async {
  //   debugPrint("Token created");
  //   DateTime now = DateTime.now();
  //   String sessionID =  auth.currentUser!.uid + now.month.toString() + now.day.toString() + now.year.toString() + now.hour.toString() + now.minute.toString() + now.second.toString();
  //   var encodedSessionID = utf8.encode(sessionID);
  //   convertedSessionID = sha256.convert(encodedSessionID);
  //   await database.ref().child('Sessions/${auth.currentUser!.uid}').set({'sessionID' : convertedSessionID.toString()});
  // }

  void updateTokens() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    await database.ref().child('UserData/${auth.currentUser!.uid}').update({'tokens/$fcmToken' : ''});
  }

  void initializeUser() async {
    await database.ref().child('UserData/${auth.currentUser!.uid}').update({'email' : auth.currentUser!.email, 'points' : 0});
    updateTokens();
  }

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await auth.createUserWithEmailAndPassword(email: email, password: password);
      // await createToken();
      initializeUser();
      await auth.setPersistence(Persistence.SESSION);
      
      return credential.user;
    }
    catch (e) {
      debugPrint(e.toString());
      //show incorrect info
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await auth.signInWithEmailAndPassword(email: email, password: password);
      // createToken();
      updateTokens();
      await auth.setPersistence(Persistence.SESSION);
      
      return credential.user;
    }
    catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  signOut() async {
    database.ref().child('Sessions/${auth.currentUser!.uid}').remove();
    debugPrint("Removed session from DB");
    await auth.signOut();
  }
}


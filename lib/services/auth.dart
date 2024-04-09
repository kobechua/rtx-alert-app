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


  Future<void> updateTokens() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    await database.ref().child('UserData/${auth.currentUser!.uid}').update({'tokens/$fcmToken' : ''});
  }

  Future<void> initializeUser() async {
    await database.ref().child('UserData/${auth.currentUser!.uid}').update({'email' : auth.currentUser!.email, 'points' : 0});
    updateTokens();

  }

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await auth.createUserWithEmailAndPassword(email: email, password: password);

      await initializeUser();

      
      return credential.user;
    }
    catch (e) {
      debugPrint(e.toString());
      throw Exception('Failed to sign up');
      //show incorrect info
    }

  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await auth.signInWithEmailAndPassword(email: email, password: password);

      await updateTokens();
      
      return credential.user;
    }
    catch (e) {
      debugPrint(e.toString());
      throw Exception('Failed to sign in');
    }

  }

  signOut() async {
    await database.ref().child('Sessions/${auth.currentUser!.uid}').remove();
    debugPrint("Removed session from DB");
    await auth.signOut();
  }
}


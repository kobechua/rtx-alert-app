// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rtx_alert_app/firebase_options.dart';

import 'package:rtx_alert_app/pages/greeting_page/greeting_page.dart';

import 'package:provider/provider.dart';
import 'package:rtx_alert_app/pages/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:rtx_alert_app/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return ChangeNotifierProvider(
      create: (context) => AppSettings()..loadSettings(),
      child: const MaterialApp(
        home: GreetingPage(),
      ),
    );
  }
}



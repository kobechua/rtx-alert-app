import 'package:flutter/material.dart';
// import 'package:rtx_alert_app/pages/home.dart';
import 'package:rtx_alert_app/pages/home_page.dart';
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Camera Page"),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage())),
              child: const Text("Home Page"),
            ),
          ],
        )
      )
    );
  }
}
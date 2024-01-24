import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<CameraDescription> cameras;
  late CameraController cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    startCamera();
  }
  

  Future<void> startCamera() async {
    try {
      cameras = await availableCameras();
      
      cameraController = CameraController(
        cameras[0], 
        ResolutionPreset.high,
        enableAudio: false,
        );

      await cameraController.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });  
    } catch (e) {
      print(e);
    }      
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(_isCameraInitialized) {
      return Scaffold(
        body: Stack(
          children: [
            CameraPreview(cameraController),
            GestureDetector(
              onTap: () {

              },
              child: button(Icons.flip_camera_android_outlined, Alignment.bottomLeft),
            ),
            GestureDetector(
              onTap: () {

              },
              child: button(Icons.camera_alt_outlined, Alignment.bottomCenter),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox();
    }

    
  }

  Widget button(IconData icon, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(
          left: 20,
          bottom: 20,
        ),
        height: 50,
        width: 50,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(2, 2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.black54,
          ),)
      )
    );
  }


}
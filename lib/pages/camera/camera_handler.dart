import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraHandler extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraHandler({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraHandler> createState() => _CameraHandlerState();
}

class _CameraHandlerState extends State<CameraHandler> {
  late CameraController cameraController;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    startCamera();
  }

  Future<void> startCamera() async {
    try {
      cameraController = CameraController(
        widget.cameras[0], 
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController.initialize();
      if (!mounted) return;

      setState(() {
        isCameraInitialized = true;
      });

    } catch (e) {
      debugPrint("An error has occured.");
    }      
  }



  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(cameraController);
  }
}

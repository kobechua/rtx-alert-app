import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:async';
// import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CameraHandler extends StatefulWidget {

  final List<CameraDescription> cameras;
  final Function(CameraController) onControllerCreated;

  const CameraHandler({super.key, required this.cameras, required this.onControllerCreated});

  @override
  State<CameraHandler> createState() => _CameraHandlerState();
}

class _CameraHandlerState extends State<CameraHandler> {
  late CameraController cameraController;
  bool isCameraInitialized = false;

  File ? displayedImage;

  @override
  void initState() {
    super.initState();
    startCamera();
    widget.onControllerCreated(cameraController);
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
        widget.onControllerCreated(cameraController);
      });

    } catch (e) {
      debugPrint("An error has occured.");
    }      
  }

  Future<void> capturePhoto() async {
    try {
      // Ensure camera is initialized and ready for picture taking
      // final XFile image = await cameraController.takePicture();
      // File imageFile = File(image.path);

      // Use the callback to pass the image file
      // widget.onPhotoCaptured(imageFile);
    } catch (e) {
      debugPrint("Error capturing photo: $e");
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


class CameraActionController {
  Function()? takePhoto;
  Future<void> Function()? pickExistingPhoto;
  Future<void> Function(CameraController)? takePhotoWithCamera;
  CameraController? ccontroller;

  void capturePhoto() {
    takePhoto?.call();
  }

  Future<void> selectExistingPhoto() async {
    if (pickExistingPhoto != null) {
      await pickExistingPhoto!();
    }
  }

  Future<void> capturePhotoWithCamera(CameraController controller) async {
    if (takePhotoWithCamera != null) {
      await takePhotoWithCamera!(controller);
    }
  }

  void setCameraController(CameraController controller){
    ccontroller = controller;
  }
}
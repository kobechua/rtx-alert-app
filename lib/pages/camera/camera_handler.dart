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
  bool _isDisposed = false;

  File ? displayedImage;

  @override
  void initState() {
    super.initState();
    startCamera(widget.cameras.first);
    widget.onControllerCreated(cameraController);
  }

  Future<void> startCamera(CameraDescription cameraDescription) async {
    try {
        cameraController = CameraController(
            cameraDescription,
            ResolutionPreset.high,
            enableAudio: false,
        );

        await cameraController.initialize();
        setState(() {
            isCameraInitialized = true;
        });
    } catch (e) {
        debugPrint("Error initializing camera: $e");
        setState(() {
            isCameraInitialized = false;
        });
        if (cameraController.value.isInitialized) {
            cameraController.dispose();
        }
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
    // Check if the controller is initialized before attempting to dispose it
    if (cameraController.value.isInitialized) {
        cameraController.dispose();
        _isDisposed = true;  // Mark as disposed if you need to track this state
    }
    super.dispose();  // It's sufficient to call super.dispose() once at the end
  }


  

@override
  Widget build(BuildContext context) {
    if (!isCameraInitialized || _isDisposed) {
      return const Center(child: CircularProgressIndicator());
    }

    // Ensure controller is still initialized when building the preview
    if (!cameraController.value.isInitialized) {
      return const Text("Camera initialization failed");
    }

    return CameraPreview(cameraController);
  }
}

class CameraActionController {
  Function()? takePhoto;
  Future<void> Function()? pickExistingPhoto;
  Future<void> Function(CameraController)? takePhotoWithCamera;
  CameraController? controller;

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

  void setCameraController(CameraController newController){
    controller = newController;
  }

  // Method to switch the camera
  Future<void> switchCamera(CameraDescription newCamera) async {
    if (controller != null) {
      await controller!.dispose(); // Dispose the current controller
    }
    controller = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller!.initialize(); // Initialize the new controller
      // If there is a specific function or callback in your UI that needs to be called after switching, call it here
    } catch (e) {
      print("Failed to switch cameras: $e");
    }
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:rtx_alert_app/pages/camera/camera_handler.dart';
// import 'package:rtx_alert_app/pages/greeting_page/greeting_page.dart';
import 'package:rtx_alert_app/services/location.dart';
// import 'package:rtx_alert_app/services/auth.dart';

import 'package:camera/camera.dart';
import 'package:rtx_alert_app/pages/camera/preview.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';


class HomePage extends StatefulWidget {
  HomePage({super.key});

  final auth = FirebaseAuth.instance.currentUser!;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? selectedImage;
  LocationHandler location = LocationHandler();
  String locationError = '';
  late final CameraActionController cameraActionController = CameraActionController();
  CameraController? homePageCameraController;
  

  @override
  void initState() {
    super.initState();
    loadCameras();
    initializeLocation();  //get current location
    cameraActionController.pickExistingPhoto = pickExistingPhoto;
    cameraActionController.takePhotoWithCamera = (camController) => takePhoto(camController);
  }

  List<CameraDescription>? cameras;
  
  Future<void> loadCameras() async {
  try {
    List<CameraDescription> loadedCameras = await availableCameras();
    setState(() {
      cameras = loadedCameras;
    });
  } catch (e) {
    debugPrint(e.toString());
  }
}

  Future<void> pickExistingPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File selectedImageFile = File(image.path);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(previewImage: selectedImageFile),
        ),
      );
    }
  }

  Future<void> takePhoto(CameraController camController) async {
    final XFile image = await camController.takePicture();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PreviewPage(previewImage: File(image.path)),
      ),
    );
  }


  Future<void> initializeLocation() async {
    try {
      await location.getCurrentLocation();
      setState(() {
        
      });
    }
    catch (e){
      setState(() {
        locationError = e.toString();
      });
    }
  }
  

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 500, // Set height
          color: Colors.black87, // Set background color
          child: Column(
            children: [
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Menu Item 1',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 28,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  // Handle tap
                  Navigator.pop(context);
                },
              ),
              const Divider(color: Colors.white10), // Divider between ListTiles
              ListTile(
                title: const Text('Sign Out',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 28,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  Navigator.pop(context);
                  FirebaseAuth.instance.signOut();
                  
                  // if (!context.mounted) return;
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => const GreetingPage()));
                },
              ),
              const Divider(color: Colors.white10), // Divider between ListTiles

              // Add more items if needed
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    CameraHandler camera = CameraHandler(
      cameras: cameras!,
      onControllerCreated: (controller) {
        homePageCameraController = controller;
        cameraActionController.setCameraController(controller);
      }, 
    );

    return Scaffold(
      body: Stack(
        children: [
          if (cameras != null)
            camera,
          Positioned(
            top: 10,
            right: 10,
            child: location.latitude != null && location.longitude != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54, // Background color
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                    child: Text(
                      'LAT: ${location.latitude}, \nLON: ${location.longitude}, \nALT: ${location.altitude}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
          
          Positioned(
            top: 10,
            left: 10,
            child: ClipOval(
              child: Container(
                width: 100,  // Diameter of the circle
                height: 100, // Diameter of the circle
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(location.latitude ?? 0, location.longitude ?? 0),
                    initialZoom: 8.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                  ],  
                ),
              ),
            ),
          ),
          
          GestureDetector(
            onTap: () {
              cameraActionController.takePhotoWithCamera!(homePageCameraController!);

            },
            child: button(Icons.camera_alt_outlined, Alignment.bottomCenter),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () => _showBottomSheet(context),
              backgroundColor: Colors.white,
              child:  const Icon(Icons.menu),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () => cameraActionController.selectExistingPhoto(),
              backgroundColor: Colors.white,
              child:  const Icon(Icons.photo_album),
            ),
          ),
        ],
      ),
    );
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
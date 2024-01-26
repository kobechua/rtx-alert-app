import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<CameraDescription> cameras;
  late CameraController cameraController;
  bool _isCameraInitialized = false;

  //variables for latitude and longitude
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    startCamera();
    _getCurrentLocation();  //get current location
  }
  
  //function to start camera
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

  //function to obtain current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
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
            Positioned(
              top: 10,
              right: 10,
              child: latitude != null && longitude != null
                  ? Text('Lat: $latitude, Lon: $longitude',
                      style: const TextStyle(color: Colors.white))
                  : const CircularProgressIndicator(),
            ),
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
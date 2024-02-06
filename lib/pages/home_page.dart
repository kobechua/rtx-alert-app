import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rtx_alert_app/pages/camera/camera_handler.dart';
import 'package:rtx_alert_app/services/location.dart';
import 'package:camera/camera.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  LocationHandler location = LocationHandler();
  String locationError = '';

  // late List<CameraDescription> cameras;
  // late CameraController cameraController;
  // bool _isCameraInitialized = false;

  // //variables for latitude and longitude
  // double? latitude;
  // double? longitude;

  @override
  void initState() {
    super.initState();
    loadCameras();
    initializeLocation();  //get current location
  }
  
  // //function to start camera
  // Future<void> startCamera() async {
  //   try {
  //     cameras = await availableCameras();
      
  //     cameraController = CameraController(
  //       cameras[0], 
  //       ResolutionPreset.high,
  //       enableAudio: false,
  //       );

  //     await cameraController.initialize();
  //     if (!mounted) return;

  //     setState(() {
  //       _isCameraInitialized = true;
  //     });  
  //   } catch (e) {
  //     print(e);
  //   }      
  // }

  //function to obtain current location
  // Future<void> _getCurrentLocation() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   // Test if location services are enabled.
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     return Future.error('Location services are disabled.');
  //   }

  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       return Future.error('Location permissions are denied');
  //     }
  //   }

  //   if (permission == LocationPermission.deniedForever) {
  //     return Future.error(
  //         'Location permissions are permanently denied, we cannot request permissions.');
  //   }

  //   try {
  //     Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  //     setState(() {
  //       latitude = position.latitude;
  //       longitude = position.longitude;
  //     });
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  List<CameraDescription>? cameras;

  
  Future<void> loadCameras() async {
  try {
    List<CameraDescription> loadedCameras = await availableCameras();
    setState(() {
      cameras = loadedCameras;
    });
  } catch (e) {
    print(e);
  }
}


  Future<void> initializeLocation() async {
    try {
      await location.getCurrentLocation();

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
                title: const Text('Menu Item 2',
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

              // Add more items if needed
            ],
          ),
        );
      },
    );
  }


  


@override
Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (cameras != null)
            CameraHandler(cameras: cameras!),
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
              // CameraHandler.takePicture();
              
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
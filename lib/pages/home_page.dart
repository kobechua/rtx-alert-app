// import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert'; 

import 'package:flutter_compass/flutter_compass.dart';
import 'package:rtx_alert_app/pages/app_settings.dart';
import 'package:rtx_alert_app/pages/camera/camera_handler.dart';
import 'package:rtx_alert_app/pages/leaderboards_page.dart';
import 'package:rtx_alert_app/pages/menu/submissions.dart';
import 'package:rtx_alert_app/pages/rewards_page.dart';

import 'package:rtx_alert_app/services/auth.dart';
import 'package:rtx_alert_app/services/location.dart';

import 'package:camera/camera.dart';
import 'package:rtx_alert_app/pages/camera/preview.dart';
import 'package:rtx_alert_app/pages/settings_page.dart';
// import 'package:rtx_alert_app/services/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:rtx_alert_app/services/session_listener.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  FirebaseAuthService auth =  FirebaseAuthService();
  FirebaseDatabase database = FirebaseDatabase.instance;
  StreamSubscription<DatabaseEvent>? sessionSubscription;
  late String convertedSessionID;
  User? user;

  File? selectedImage;

  LocationHandler location = LocationHandler();
  String locationError = '';

  int currentCameraIndex = 0;
  List<CameraDescription>? cameras;
  late final CameraActionController cameraActionController = CameraActionController();
  CameraController? homePageCameraController;
  bool isCameraInitialized = false;
  bool _isControllerDisposed = false;

  bool isSwitchingCameras = false;


  StreamSubscription<CompassEvent>? compassListener;
  // final FirebaseAuthService auth = FirebaseAuthService();
  Future<Position>? _locationFuture;
  static bool _locationInitialized = false;
  bool _isMapFullScreen = false;

  double? _azimuth;
  double normalizeAzimuth(double azimuth) {
    while (azimuth < 0) {
      azimuth += 360;
    }
    return azimuth;
  }

  @override
  void initState()  {
    super.initState();
    createToken(); //Token should be made before reachinng this page. could try making token in greeting then pulling it here
    // convertedSessionID = auth.convertedSessionID;
    loadCameras();
    user = auth.auth.currentUser;
    
    _locationFuture = location.getCurrentLocation();

    compassListener = FlutterCompass.events!.listen((CompassEvent event) { 
      setState(() {
        _azimuth = normalizeAzimuth(event.heading ?? 0);  //Normalize azimuth value
      });
    });

    if (!_locationInitialized) {
      initializeLocation();                     //get current location once per session
    }
      //get current location
    cameraActionController.pickExistingPhoto = pickExistingPhoto;
    cameraActionController.takePhotoWithCamera = (camController) => takePhoto(camController);
  }
  

  @override
  void dispose() {
    compassListener?.cancel();
    sessionSubscription?.cancel();

    
    convertedSessionID = '';
    super.dispose();
  }


  Future<void> createToken() async {
    debugPrint("Token created");
    DateTime now = DateTime.now();
    String sessionID =  auth.user!.uid + now.month.toString() + now.day.toString() + now.year.toString() + now.hour.toString() + now.minute.toString() + now.second.toString();
    var encodedSessionID = utf8.encode(sessionID);
    convertedSessionID = sha256.convert(encodedSessionID).toString();
    await database.ref().child('Sessions/${auth.user!.uid}').set({'sessionID' : convertedSessionID.toString()});
  }

void flipCamera() async {
  debugPrint("Attempting to flip camera...");
  
  if (cameras == null || cameras!.isEmpty || isSwitchingCameras) {
    debugPrint("Either no cameras are available or a switch is already in progress.");
    return;
  }

  debugPrint("Available cameras ${cameras.toString()}.");

  isSwitchingCameras = true;
  setState(() {
    _isControllerDisposed = true;
  });

  if (homePageCameraController != null && homePageCameraController!.value.isInitialized) {
    debugPrint("Disposing current camera controller...");
    await homePageCameraController!.dispose();
    setState(() {
        _isControllerDisposed = true; // Set to true immediately after dispose
    });
    debugPrint("Current camera controller disposed.");
  }

  // Update the camera index
  currentCameraIndex = (currentCameraIndex + 1) % cameras!.length;
  
  // Attempt to initialize the new camera
  CameraController newController = CameraController(
    cameras![currentCameraIndex],
    ResolutionPreset.high,
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.jpeg
  );

  debugPrint("Initializing new camera controller...");

  try {
    await newController.initialize();
    debugPrint("New camera controller initialized.");

    if (!mounted) return;
    setState(() {
      homePageCameraController = newController;
      _isControllerDisposed = false;
      isSwitchingCameras = false;
    });

  } catch (e) {
    debugPrint("Failed to initialize the camera controller: $e");
    setState(() {
      _isControllerDisposed = true;
      isSwitchingCameras = false;
    });
  }
}


  Future<void> loadCameras() async {
  try {
    List<CameraDescription> loadedCameras = await availableCameras();
    setState(() {
      cameras = loadedCameras;
      isCameraInitialized = true;
      debugPrint("Cameras loaded: ${cameras!.length}");
    });
  } catch (e) {
    debugPrint("Failed to load cameras :$e");
    setState(() {
      isCameraInitialized = false;
    });
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
    if (_locationInitialized) {
      // If location services have already been initialized, do nothing
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // If permissions are denied, request them
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show a message or handle accordingly
        setState(() {
          locationError = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, show a message or handle accordingly
      setState(() {
        locationError = 'Location permissions are permanently denied, we cannot request permissions.';
      });
      return;
    }


    // Permissions are granted, proceed with initializing location services
    try {
      setState(() {
        // Update state with current location if necessary
      });
    } catch (e) {
      setState(() {
        locationError = e.toString();
      });
    } finally {
      _locationInitialized = true; // Mark location services as initialized
    }
  }
  

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 500, // Set height
          color: Colors.transparent, // Set background color
          child: Column(
            children: [
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Submissions',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  // Handle tap
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SubmissionPage()));
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Rewards',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  // Handle tap
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RewardsPage()));
                },
              ),
              const Divider(color: Colors.black26), // Divider between ListTiles
              ListTile(

                title: const Text('Leaderboard',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  // Handle tap
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardPage()));

                },
              ),
              const Divider(color: Colors.black26), // Divider between ListTiles
              ListTile(
                title: const Text('Settings',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  // Handle tap
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                },
              ),
              const Divider(color: Colors.black26), // Divider between ListTiles
              ListTile(
                title: const Text('Sign Out',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  Navigator.pop(context);
                  auth.signOut();
                },
              ),
              const Divider(color: Colors.black26), // Divider between ListTiles

              // Add more items if needed
            ],
          ),
        );
      },
    );
  }



@override
Widget build(BuildContext context) {
  final appSettings = Provider.of<AppSettings>(context, listen: true);
  
  // Avoid building CameraPreview if the controller has been disposed or not initialized
    if (!isCameraInitialized || cameras == null || _isControllerDisposed) {
      debugPrint("Initialization status: Camera initialized = $isCameraInitialized, Cameras available = ${cameras != null}, Controller disposed = $_isControllerDisposed");
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
    );
  }

  if (cameras == null) {
    debugPrint("Waiting for camera availability");
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  CameraHandler camera = CameraHandler(
    cameras: cameras!,
    onControllerCreated: (controller) {
      homePageCameraController = controller;
      cameraActionController.setCameraController(controller);
      
    },
  );
  if (user != null){

    sessionSubscription = database.ref().child('Sessions/${user!.uid}').onValue.listen((event) {
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value is Map){
      Map<dynamic, dynamic> valueMap = snapshot.value as Map<dynamic, dynamic>;
      String storedSessionID = valueMap['sessionID'];

      if (storedSessionID != convertedSessionID && convertedSessionID != ''){

        debugPrint("SIGNOUTTOKEN");
        // convertedSessionID = '';
        auth.signOut();
      }
    }
    
  });
}

    return SessionTimeOutListener(
      duration: const Duration(minutes: 5),
      onTimeOut: () async {
        debugPrint("SIGNOUTTIMER");
        await auth.signOut();
      },
      onWarning: () {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inactivity Alert: You will be logged out in 1 minute")));
      },
      child: Scaffold(
    body: Stack(
      children: [
        if (cameras != null)
          camera,

/// WIDGETS FOR THE LOCATION DATA ON THE TOP RIGHT OF THE SCREEN
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black54, // Background color
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),

            child: FutureBuilder<Position>(
              future: _locationFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  Position position = snapshot.data!;

                  final altitude = appSettings.convertAltitude(snapshot.data!.altitude);
                  final altitudeUnit = appSettings.useEnglishUnits ? "feet" : "meters";

                  String coordinatesDisplay; // This will hold the string to be displayed
                  bool showLabels = appSettings.shouldShowLatLonLabels();

                  if (appSettings.representationType == AppSettings.utm || appSettings.representationType == AppSettings.mgrs) {
                    // For UTM or MGRS, we only display once
                    coordinatesDisplay = appSettings.formatCoordinate(position.latitude, position.longitude, true);
                  } else {
                    // For other settings, show both with labels conditionally
                    String formattedLatitude = appSettings.formatCoordinate(position.latitude, position.longitude, true);
                    String formattedLongitude = appSettings.formatCoordinate(position.latitude, position.longitude, false);
                    coordinatesDisplay = (showLabels ? 'LAT: $formattedLatitude\n' : '$formattedLatitude\n') +
                                        (showLabels ? 'LON: $formattedLongitude' : formattedLongitude);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coordinatesDisplay, // Display the coordinates appropriately
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Azimuth: ${_azimuth?.toStringAsFixed(3)}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ALT: ${altitude.toStringAsFixed(2)} $altitudeUnit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Text(
                    'Fetching location...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
              },
            ),
          ),
        ),

/// WIDGETS FOR THE MINI-MAP ON THE TOP LEFT OF THE SCREEN
        FutureBuilder<Position>(
          future: _locationFuture, // Fetch the current location
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // Show loading indicator
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}'); // Show error message
            } else if (snapshot.hasData) {
              // Once data is fetched, update the location display along with the map

              final position = snapshot.data!;
              final center = LatLng(position.latitude, position.longitude);
                
                return StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, compassSnapshot) {
                    if (!compassSnapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    // Compass heading
                    final double heading = compassSnapshot.data!.heading ?? 0;
                    final double headingRadians = heading * (pi/180);

                    return Stack(
                      children: [ 
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _isMapFullScreen ? MediaQuery.of(context).size.width : 100,
                          height: _isMapFullScreen ? MediaQuery.of(context).size.width : 100,
                          child: ClipOval(
                            child: Stack(
                              children: [
                                FlutterMap(
                                  options: MapOptions(
                                    initialCenter: center,
                                    initialZoom: _isMapFullScreen ? 5.0 : 13.0,
                                    interactionOptions: const InteractionOptions(
                                      flags: InteractiveFlag.none,
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      subdomains: const ['a', 'b', 'c'],
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          width: 60.0,
                                          height: 60.0,
                                          point: center,
                                          child: Transform.rotate(
                                            angle: headingRadians,
                                            child: const Icon(Icons.navigation, size: 30, color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ClipOval(
                                  child: Material(
                                    color: Colors.transparent, // Keep the overlay transparent
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isMapFullScreen = !_isMapFullScreen;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                      ],
                    );
                  }
                );
                
              
            } else {
              return const Text('No location data');
            }
          },
        ),
        // Correctly positioned container on the top right for location info
        
        
/// WIDGETS FOR THE BUTTONS ON THE BOTTOM OF THE SCREEN
        GestureDetector(
          onTap: () {
            cameraActionController.takePhotoWithCamera!(homePageCameraController!);
          },
          child: button(Icons.camera_alt_outlined, Alignment.bottomCenter),
        ),

        // Camera flip button
        Positioned(
          right: 20, // Adjust the position as needed to place it next to the photo capture button
          bottom: 100,
          child: FloatingActionButton(
            onPressed: flipCamera, // Call the flipCamera method
            backgroundColor: Colors.white,
            child: const Icon(Icons.flip_camera_ios, color: Colors.black),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: () => _showBottomSheet(context),
            backgroundColor: Colors.white,
            child: const Icon(Icons.menu, color: Colors.black),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: () => cameraActionController.selectExistingPhoto(),
            backgroundColor: Colors.white,
            child: const Icon(Icons.photo_album, color: Colors.black),
          ),
        ),
      ],
    ),
  )
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
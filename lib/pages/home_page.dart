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
import 'package:shared_preferences/shared_preferences.dart';


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
  StreamSubscription<Position>? positionStreamSubscription;
  // final FirebaseAuthService auth = FirebaseAuthService();
  double? latitude;
  double? longitude;
  double? altitude;
  LatLng? currentPosition;

  MapController mapController = MapController();

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
    checkLocationPermissionAndInitialize();
    createToken(); //Token should be made before reachinng this page. could try making token in greeting then pulling it here
    // convertedSessionID = auth.convertedSessionID;
    loadCameras();
    user = auth.auth.currentUser;
    flipCamera();
    
    compassListener = FlutterCompass.events!.listen((CompassEvent event) { 
      setState(() {
        _azimuth = normalizeAzimuth(event.heading ?? 0);  //Normalize azimuth value
      });
    });

    cameraActionController.pickExistingPhoto = pickExistingPhoto;
    cameraActionController.takePhotoWithCamera = (camController) => takePhoto(camController);
  }

  bool _locationInitialized = false;

  void checkLocationPermissionAndInitialize() async {
    if (!_locationInitialized) {
      _locationInitialized = true;
      final prefs = await SharedPreferences.getInstance();
      bool hasAskedForPermission = prefs.getBool('hasAskedForPermission') ?? false;

      if (!hasAskedForPermission) {
          await manageLocationPermission();
          await prefs.setBool('hasAskedForPermission', true);
      } else {
          initializeLocation();
      }
    }
  }
  

  @override
  void dispose() {
    positionStreamSubscription?.cancel();
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
      homePageCameraController = CameraController(cameras![0], ResolutionPreset.high, enableAudio: false);
      homePageCameraController?.initialize();
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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationError = 'Location services are disabled. Please enable them in your device settings.';
      });
      return; // Exit if location services are disabled.
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationError = 'Location permissions are permanently denied. Please enable them in your device settings.';
      });
      return;
    }

    if (permission == LocationPermission.denied) {
      await manageLocationPermission();
    } else {
      // Permissions are granted, start location updates
      startLocationUpdates();
    }
  }

  Future<void> manageLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() {
        locationError = 'Location permissions denied. Please enable them in your device settings.';
      });
    } else {
      // Permissions granted, start location updates
      startLocationUpdates();
    }
  }

  void startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Choose the accuracy level needed for your app.
      distanceFilter: 10, // Only receive updates every 10 meters.
    );

    // Cancel any existing subscriptions to avoid multiple listeners
    positionStreamSubscription?.cancel();

    // Subscribe to the position stream
    positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        debugPrint('Updated location: $latitude, $longitude, $altitude');
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
          currentPosition = LatLng(position.latitude, position.longitude);
          altitude = position.altitude;
          mapController.move(currentPosition!, 13);
        });
      },
      onError: (e) {
        debugPrint('Failed to get location: $e');
      }
    );
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
        if (homePageCameraController != null && homePageCameraController!.value.isInitialized)
          CameraPreview(homePageCameraController!),

/// WIDGETS FOR THE LOCATION DATA ON THE TOP RIGHT OF THE SCREEN
    Positioned(
      top: 10,
      right: 10,
      child: currentPosition != null ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black54, // Background color
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coordinate Display
          Text(
            appSettings.representationType == AppSettings.utm || appSettings.representationType == AppSettings.mgrs ?
              appSettings.formatCoordinate(currentPosition!.latitude, currentPosition!.longitude, true) : // For UTM/MGRS, format as single line
              "${appSettings.shouldShowLatLonLabels() ? 'LAT: ' : ''}${appSettings.formatCoordinate(currentPosition!.latitude, currentPosition!.longitude, true)}\n" +
              "${appSettings.shouldShowLatLonLabels() ? 'LON: ' : ''}${appSettings.formatCoordinate(currentPosition!.latitude, currentPosition!.longitude, false)}", // For lat/lon with labels
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
            // Azimuth Display
            Text(
              'Azimuth: ${_azimuth?.toStringAsFixed(3)}°',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Altitude Display
            Text(
              'ALT: ${altitude?.toStringAsFixed(2)} ${appSettings.useEnglishUnits ? "feet" : "meters"}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ) : const Text(
        'Fetching location...',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

/// WIDGETS FOR THE MINI-MAP ON THE TOP LEFT OF THE SCREEN
  Positioned(
    top: 10,
    left: 10,
    child: currentPosition != null ? StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, compassSnapshot) {
        double headingRadians = 0;
        if (compassSnapshot.hasData) {
          headingRadians = (compassSnapshot.data!.heading ?? 0) * (pi/180);
        }
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isMapFullScreen ? MediaQuery.of(context).size.width : 100,
          height: _isMapFullScreen ? MediaQuery.of(context).size.width : 100,
          child: ClipOval(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                    initialZoom: _isMapFullScreen ? 5.0 : 13.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none
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
                          point: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                          child: Transform.rotate(
                            angle: headingRadians,
                            child: const Icon(Icons.navigation, size: 30, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent, // Keep the overlay transparent
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isMapFullScreen = !_isMapFullScreen;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ) : const CircularProgressIndicator(),
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert'; 
import 'package:flutter_compass/flutter_compass.dart';

import 'package:rtx_alert_app/pages/menu/app_settings.dart';
import 'package:rtx_alert_app/pages/camera/camera_handler.dart';
import 'package:rtx_alert_app/pages/menu/leaderboards_page.dart';
import 'package:rtx_alert_app/pages/menu/submissions.dart';
import 'package:rtx_alert_app/pages/menu/rewards_page.dart';
import 'package:rtx_alert_app/services/auth.dart';
import 'package:rtx_alert_app/services/location.dart';

import 'package:camera/camera.dart';
import 'package:rtx_alert_app/pages/camera/preview.dart';
import 'package:rtx_alert_app/pages/menu/settings_page.dart';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:rtx_alert_app/services/session_listener.dart';

import 'package:tflite/tflite.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  FirebaseAuthService auth =  FirebaseAuthService();
  FirebaseDatabase database = FirebaseDatabase.instance;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  StreamSubscription<DatabaseEvent>? sessionSubscription;
  late String convertedSessionID;
  User? user;

  File? selectedImage;

  LocationHandler location = LocationHandler();
  String locationError = '';

  late final CameraActionController cameraActionController = CameraActionController();
  CameraController? homePageCameraController;

  StreamSubscription<CompassEvent>? compassListener;

  Future<Position>? _locationFuture;
  static bool _locationInitialized = false;
  bool _isMapFullScreen = false;
  
  int imageCount = 0;

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
    createToken();
    loadCameras();
    // loadModel();
    user = auth.auth.currentUser;
    initializeFirebaseMessaging();
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
  void dispose() async {
    compassListener?.cancel();
    sessionSubscription?.cancel();
    convertedSessionID = '';
    
    super.dispose();
    await Tflite.close();
  }

    void initializeFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Assuming 'notification' exists and contains a title and body.
      String title = message.notification?.title ?? "No Title";
      String body = message.notification?.body ?? "No Body";

      _showNotificationAlert(title, body);
    });

    // Request permission for iOS devices
    firebaseMessaging.requestPermission();
  }

  void _showNotificationAlert(String title, String body) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> createToken() async {
    debugPrint("Token created");
    DateTime now = DateTime.now();
    String sessionID =  auth.user!.uid + now.month.toString() + now.day.toString() + now.year.toString() + now.hour.toString() + now.minute.toString() + now.second.toString();
    var encodedSessionID = utf8.encode(sessionID);
    convertedSessionID = sha256.convert(encodedSessionID).toString();
    await database.ref().child('Sessions/${auth.user!.uid}').set({'sessionID' : convertedSessionID.toString()});
  }

  Future<void> loadModel() async {

    await Tflite.loadModel(
      model: "assets/ssd_mobilenet.tflite",
      labels: "assets/ssd_mobilenet.txt",
      numThreads: 1, // defaults to 1
      isAsset: true, // defaults to true, set to false to load resources outside assets
      useGpuDelegate: false // defaults to false, set to true to use GPU delegate
    );
  }

  Future<List?> detectObjects(CameraImage img) async {
    var recognitions = await Tflite.detectObjectOnFrame(
      bytesList: img.planes.map((plane) => plane.bytes).toList(), // CameraImage bytes
      model: "SSDMobileNet",
      imageHeight: img.height,
      imageWidth: img.width,
      imageMean: 127.5, // values depend on the model
      imageStd: 127.5,
      numResultsPerClass: 1,
    );

    if (recognitions![0]['confidenceInClass'] > 0.5){
      debugPrint(recognitions[0].toString());
    }
    
    return recognitions;
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
          builder: (context) => PreviewPage(previewImage: selectedImageFile, azimuth: _azimuth ?? 0),
        ),
      );
    }
  }

  Future<void> takePhoto(CameraController camController) async {
    final XFile image = await camController.takePicture();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PreviewPage(previewImage: File(image.path),  azimuth: _azimuth ?? 0),
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
              const Divider(color: Colors.black26),
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
  
  if (cameras == null) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),

    );
  }

  CameraHandler camera = CameraHandler(
  cameras: cameras!,
  onControllerCreated: (controller) {
    homePageCameraController = controller;
    cameraActionController.setCameraController(controller);
    // controller.startImageStream((image) {
    //   imageCount++;
    //   if (imageCount % 30 == 0) {
    //     imageCount = 0;
    //     detectObjects(image);
    //   }
    //  });
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
      duration: const Duration(minutes: 10),
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
                  final altitude = appSettings.convertAltitude(snapshot.data!.altitude);
                  final altitudeUnit = appSettings.useEnglishUnits ? "feet" : "meters";

                  return Text(
                    'LAT: ${snapshot.data!.latitude.toStringAsFixed(2)}°, \n'
                    'LON: ${snapshot.data!.longitude.toStringAsFixed(2)}°, \n'
                    'Azimuth: ${_azimuth?.toStringAsFixed(3)}°, \n'
                    'ALT: ${altitude.toStringAsFixed(2)} $altitudeUnit',
                    
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
                                      width: 50.0,
                                      height: 50.0,
                                      point: center,
                                      child: const Icon(Icons.location_on, size: 35.0, color: Colors.red,),
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
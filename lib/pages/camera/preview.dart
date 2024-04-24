import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite/tflite.dart';

import '../../services/storage.dart';

class PreviewPage extends StatefulWidget {
  final File previewImage;
  final double azimuth;

  const PreviewPage({super.key, required this.previewImage, required this.azimuth});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  List _recognitions = [];
  img.Image? image;
  List<Map<String, dynamic>> alerts = [];
  List<DropdownMenuItem<String>> dropdownEntries = [];

  String? dropdownText;

  FirebaseAuth user = FirebaseAuth.instance;
  FirebaseMessaging msg = FirebaseMessaging.instance;

  late double scaleFactorX;
  late double scaleFactorY;
  late double imageHeight;
  late double imageWidth;

  @override
  void initState() {
    super.initState();
    loadModel();
    detectObjects();
    setState(() {

    });
    loadImage();
    getAlerts();

    // if (image != null) {

    // }

  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/ssd_mobilenet.tflite",
      labels: "assets/ssd_mobilenet.txt",
      numThreads: 1,
      isAsset: true,
      useGpuDelegate: false,
    );
  }

  void loadImage() async {
    image = img.decodeImage(await widget.previewImage.readAsBytes());
  }

  Future<void> detectObjects() async {
    final image = widget.previewImage;
    var recognitions = await Tflite.detectObjectOnImage(
      path: image.path,
      numResultsPerClass: 1,
    );
    debugPrint(recognitions.toString());
    var filteredRecognitions = recognitions!
    .where((recognition) => recognition['confidenceInClass'] * 100 > 65)
    .toList();
    
    setState(() {
      _recognitions = filteredRecognitions;
      scaleFactorX = MediaQuery.of(context).size.width / (Image.file(image).width ?? 1);
      scaleFactorY = MediaQuery.of(context).size.height / (Image.file(image).height ?? 1);
      imageHeight = Image.file(image).height ?? 1;
      imageWidth = Image.file(image).width ?? 1;
    });
  }

  void cropAndUploadImage(Map recognition) {
    final cropX = (recognition['rect']['x'] * image!.width).toInt();
    final cropY = (recognition['rect']['y'] * image!.height).toInt();
    final cropW = (recognition['rect']['w'] * image!.width).toInt();
    final cropH = (recognition['rect']['h'] * image!.height).toInt();

    img.Image croppedImg = img.copyCrop(image!, x: cropX, y: cropY, width: cropW, height: cropH);
    var croppedFile = File('${widget.previewImage.path}_cropped.png')
      ..writeAsBytesSync(img.encodePng(croppedImg));

    Storage().uploadPhoto(croppedFile.path, widget.previewImage.path, widget.azimuth, (dropdownText ?? '0') );
    Navigator.of(context).pop();
  }

  Future<void> getAlerts() async {
    final database = FirebaseDatabase.instance;
    final token = await msg.getToken();
    final dir = database.ref("Alerts/$token/");

    dropdownEntries.add(
      const DropdownMenuItem(
        value: '0',
        child: Text('For fun!'),
      )
    );

    DataSnapshot snapshot = await dir.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> entries = snapshot.value as Map<dynamic, dynamic>;
      entries.forEach((key, value) {
        String submissionKey = key as String;
        Map<String, dynamic> submissionValue;

        if (value['data'] is String) {
          submissionValue = json.decode(value['data']);
        } else if (value is Map) {
          submissionValue = value.map<String, dynamic>((k, v) => MapEntry(k as String, v));
        } else {
          debugPrint('Unexpected data type for submission data');
          return; 
        }
        
        final entry = {
          'entry': submissionKey,
          'name': submissionValue['Region'],
          'id': submissionValue['alertID'],
        };

        alerts.add(entry);
        dropdownEntries.add(
          DropdownMenuItem(
            value: entry['id'].toString(),
            child: Text('${entry['name']} - ID ${entry['id'].toString()}'),
          )
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate scale factors

    return Scaffold(
      appBar: AppBar(
        title: DropdownButton<String>(
          value: dropdownText,
          hint: const Text("Select Alert"),
          onChanged: (String? newValue) {
            setState(() {
              dropdownText = newValue;
            });
          },
          items: dropdownEntries,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Storage().uploadPhoto(widget.previewImage.path, widget.previewImage.path, widget.azimuth, (dropdownText ?? '0'));
              Navigator.of(context).pop();
            },
            style: ButtonStyle(backgroundColor:  MaterialStateProperty.all<Color>(const Color.fromARGB(255, 241, 241, 241))),
            child: const Text("Submit", style: TextStyle(color: Colors.black)),
          ),
          const SizedBox(width: 10)
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Divider(height: 10,),
          SizedBox(
            width: 500,
            height: 500,
            child: Image.file(widget.previewImage, fit: BoxFit.contain),
          ),
                              
          ..._recognitions.map((recog) {
            return Positioned(
              left: recog["rect"]["x"] * scaleFactorX,
              top: recog["rect"]["y"] * (MediaQuery.of(context).size.height / 2 + imageHeight/2 )+ 175,
              width: recog["rect"]["w"] * scaleFactorX,
              height: recog["rect"]["h"] * (MediaQuery.of(context).size.height / 2 + imageHeight/2) ,
              child: GestureDetector(
                onTap: () => cropAndUploadImage(recog),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 3),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      child: Container(
                        color: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Text(
                          '${recog['detectedClass']} ${recog['confidenceInClass']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

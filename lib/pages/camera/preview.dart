import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
// import 'package:camera/camera.dart';
import 'dart:io';
// import 'package:flutter/services.dart';
import '../../services/storage.dart';
import 'package:image/image.dart' as img;

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

  @override
  void initState() {
    super.initState();
    loadModel();
    detectObjects();
    loadImage();
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
    });
  }

  void cropAndUploadImage(Map recognition) {
    final cropX = (recognition['rect']['x'] * image!.width).toInt();
    final cropY = (recognition['rect']['y'] * image!.height).toInt();
    final cropW = (recognition['rect']['w'] * image!.width).toInt();
    final cropH = (recognition['rect']['h'] * image!.height).toInt();

    img.Image croppedImg = img.copyCrop(image!, x:cropX, y: cropY, width: cropW, height: cropH);
    var croppedFile = File('${widget.previewImage.path}_cropped.png')
      ..writeAsBytesSync(img.encodePng(croppedImg));

    Storage().uploadPhoto(croppedFile.path, widget.previewImage.path, widget.azimuth);
    Navigator.of(context).pop();
  }
  
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Preview'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Storage().uploadPhoto(widget.previewImage.path, widget.previewImage.path, widget.azimuth);
            Navigator.of(context).pop();
          },
          child: const Text("Submit", style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
    body: Stack(
      
      children: [
        Image.file(widget.previewImage,
          width: 500,
          height: 500,
         ),
        
        ..._recognitions.map((recog) {
          debugPrint('${MediaQuery.of(context).size.width.toString()}, ${MediaQuery.of(context).size.height.toString()}');
          debugPrint('${image?.width}, ${image?.height}');
          return Positioned(
            left: recog["rect"]["x"] * MediaQuery.of(context).size.width,
            top: recog["rect"]["y"] * MediaQuery.of(context).size.height,
            width: recog["rect"]["w"] * MediaQuery.of(context).size.width,
            height: recog["rect"]["h"] * MediaQuery.of(context).size.height,
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

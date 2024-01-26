import 'package:flutter/material.dart';

class CameraHandler extends StatefulWidget {
  const CameraHandler({super.key});

  @override
  State<CameraHandler> createState() => _CameraHandlerState();
}

class _CameraHandlerState extends State<CameraHandler> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

//  vid/pic function should return file to vid/pic, which is passed thru firebase fileupload function
import 'package:flutter/material.dart';
import 'dart:io';

class PreviewPage extends StatefulWidget {
  final File? previewImage;
  const PreviewPage({super.key, required this.previewImage});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(), // This line will navigate back to the previous screen
        ),
      ),
      body: widget.previewImage != null
          ? Image.file(widget.previewImage!) // Display the image if it's not null
          : const Center(child: Text('No image selected')), // Display a placeholder text if the image is null
    );
  }
}



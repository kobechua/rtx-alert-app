import 'package:flutter/material.dart';
import 'dart:io';

import '../../services/storage.dart';

class PreviewPage extends StatefulWidget {
  final File previewImage;
  const PreviewPage({super.key, required this.previewImage});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  @override
  Widget build(BuildContext context) {
    final Storage storage = Storage();
    return Scaffold(
      appBar: 
          AppBar(
            title: const Text('Preview'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(), // This line will navigate back to the previous screen
            ),
            actions: [
                Positioned(
                right: 20,
                top: 20,
                child: TextButton(
                  onPressed: () => {
                    storage.uploadPhoto(widget.previewImage.path, widget.previewImage.path)
                  },
                  
                  child:  const Text("Submit",  
                                      style: TextStyle(
                                      color: Colors.black, // Text color set to white
                                      fontSize: 16.0,
                                      )
                                    ),
                ),
              ),
            ],
          ),
          
// Display a placeholder text if the image is null
          body : Image.file(widget.previewImage) // Display the image if it's not null

      );
    // );
  }
}



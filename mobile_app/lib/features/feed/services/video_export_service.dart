import 'package:flutter/material.dart';

class VideoExportService {
  static void downloadVideo(BuildContext context, Map<String, dynamic> productData) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class VideoExportService {
  static Future<void> downloadVideo(
      BuildContext context, Map<String, dynamic> productData) async {
    final allowDownload = productData['allowDownload'] == true ||
        productData['allow_download'] == true;
    if (!allowDownload) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The seller has disabled downloads for this video.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final videoUrl = productData['video']?['url'] ?? productData['video_url'];
    if (videoUrl == null || videoUrl.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video file not available for download.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Downloading pitch video...'),
          ],
        ),
        duration: Duration(seconds: 20),
      ),
    );

    try {
      final file =
          await DefaultCacheManager().getSingleFile(videoUrl.toString());
      final appDir = await getApplicationDocumentsDirectory();
      final sanitizedName = (productData['name'] ?? 'pitch_video')
          .toString()
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetPath =
          '${appDir.path}/${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final savedFile = await file.copy(targetPath);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Video saved: ${savedFile.path.split('/').last.split('\\').last}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Share / Export',
            textColor: Colors.white,
            onPressed: () {
              Share.shareXFiles([XFile(savedFile.path)],
                  text: 'Exported from Pitch & Sell: ${productData['name']}');
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('Video download error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download video: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

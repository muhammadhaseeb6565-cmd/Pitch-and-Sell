import os

def extract_method(content, method_name):
    start = content.find(method_name)
    if start == -1: return None, content
    
    brace_start = content.find('{', start)
    count = 1
    i = brace_start + 1
    while count > 0 and i < len(content):
        if content[i] == '{': count += 1
        elif content[i] == '}': count -= 1
        i += 1
        
    extracted = content[start:i]
    new_content = content[:start] + content[i:]
    return extracted, new_content

with open('mobile_app/lib/features/feed/widgets/video_player_item.dart', 'r', encoding='utf-8') as f:
    content = f.read()

download, content = extract_method(content, 'void _handleDownloadVideo() {')

# Make it static
download = download.replace('void _handleDownloadVideo() {', 'static void downloadVideo(BuildContext context, Map<String, dynamic> productData) {')
download = download.replace('widget.productData', 'productData')
download = download.replace('_controller?.pause();', '')

export_service = '''import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoExportService {
''' + download + '\n}\n'

os.makedirs('mobile_app/lib/features/feed/services', exist_ok=True)
with open('mobile_app/lib/features/feed/services/video_export_service.dart', 'w', encoding='utf-8') as f:
    f.write(export_service)

# Update tap handler
content = content.replace('onTap: _handleDownloadVideo,', 'onTap: () => VideoExportService.downloadVideo(context, widget.productData),')
content = content.replace("import '../services/feed_dialog_service.dart';", "import '../services/feed_dialog_service.dart';\nimport '../services/video_export_service.dart';")

with open('mobile_app/lib/features/feed/widgets/video_player_item.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Extracted VideoExportService successfully')

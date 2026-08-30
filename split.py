import re

with open('mobile_app/lib/screens/feed_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_idx = content.find('class VideoPlayerItem extends StatefulWidget {')

if start_idx != -1:
    feed_screen_content = content[:start_idx]
    video_item_content = content[start_idx:]
    
    # We need imports for video_item_content
    imports = '''import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/api_service.dart';
import '../../../providers/cart_provider.dart';
import '../../screens/checkout_screen.dart';
import '../../screens/seller_profile_screen.dart';

'''
    
    with open('mobile_app/lib/features/feed/widgets/video_player_item.dart', 'w', encoding='utf-8') as f:
        f.write(imports + video_item_content)
        
    # Update feed_screen.dart to import VideoPlayerItem
    # Feed screen now needs to point to the correct widget
    feed_screen_content = feed_screen_content.replace(
        "import '../services/socket_service.dart';",
        "import '../services/socket_service.dart';\nimport '../features/feed/widgets/video_player_item.dart';"
    )
    
    with open('mobile_app/lib/screens/feed_screen.dart', 'w', encoding='utf-8') as f:
        f.write(feed_screen_content)
        
    print('Split successful.')
else:
    print('Failed to find VideoPlayerItem')

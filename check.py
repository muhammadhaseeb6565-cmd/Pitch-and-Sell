import re

with open('mobile_app/lib/screens/feed_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start = content.find('class VideoPlayerItem extends StatefulWidget {')
if start == -1:
    print('Not found')
else:
    print(f'Starts at: {start}')

import re

with open('mobile_app/lib/features/feed/widgets/video_player_item.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Grab _showOrderCheckoutSheet
start_idx = content.find('void _showOrderCheckoutSheet() {')
end_idx = content.find('void _handleDownloadVideo() {')

if start_idx != -1 and end_idx != -1:
    print(content[start_idx:end_idx][:500])
else:
    print('Not found')

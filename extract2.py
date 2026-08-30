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

checkout, content = extract_method(content, 'void _showOrderCheckoutSheet() {')
comments, content = extract_method(content, 'void _showCommentsSheet() async {')

# Transform checkout method to static
checkout = checkout.replace('void _showOrderCheckoutSheet() {', 'static void showOrderCheckoutSheet(BuildContext context, Map<String, dynamic> productData) {')
checkout = checkout.replace('widget.productData', 'productData')
# The inner method uses 'context' and 'Provider.of', we pass 'context' to it.

# Transform comments method to static
comments = comments.replace('void _showCommentsSheet() async {', 'static void showCommentsSheet(BuildContext context, Map<String, dynamic> productData) async {')
comments = comments.replace('widget.productData', 'productData')
comments = comments.replace('_controller?.pause();', '')

dialog_service = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../providers/cart_provider.dart';
import '../../../screens/checkout_screen.dart';
import '../../../screens/seller_profile_screen.dart';
import 'dart:convert';

class FeedDialogService {
''' + checkout + '\n\n  ' + comments + '\n}\n'

os.makedirs('mobile_app/lib/features/feed/services', exist_ok=True)
with open('mobile_app/lib/features/feed/services/feed_dialog_service.dart', 'w', encoding='utf-8') as f:
    f.write(dialog_service)

# Now rewrite video_player_item.dart to use the service
content = content.replace('_showOrderCheckoutSheet();', 'FeedDialogService.showOrderCheckoutSheet(context, widget.productData);')
content = content.replace('_showCommentsSheet();', 'FeedDialogService.showCommentsSheet(context, widget.productData);')
content = content.replace("import '../../../screens/seller_profile_screen.dart';", "import '../../../screens/seller_profile_screen.dart';\nimport '../services/feed_dialog_service.dart';")

with open('mobile_app/lib/features/feed/widgets/video_player_item.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Extracted FeedDialogService successfully')

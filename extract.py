def extract_method(content, method_name):
    start = content.find(method_name)
    if start == -1: return None, content
    
    # find the first {
    brace_start = content.find('{', start)
    if brace_start == -1: return None, content
    
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

checkout_method, content = extract_method(content, 'void _showOrderCheckoutSheet() {')
download_method, content = extract_method(content, 'void _handleDownloadVideo() {')
comments_method, content = extract_method(content, 'void _showCommentsSheet() async {')
share_method, content = extract_method(content, 'void _handleShareProduct() async {')

print(f'Checkout size: {len(checkout_method) if checkout_method else 0}')
print(f'Download size: {len(download_method) if download_method else 0}')
print(f'Comments size: {len(comments_method) if comments_method else 0}')
print(f'Share size: {len(share_method) if share_method else 0}')

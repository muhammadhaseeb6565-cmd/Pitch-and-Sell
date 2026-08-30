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

with open('mobile_app/lib/screens/dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

upload_sheet, content = extract_method(content, 'void _showUploadVideoSheet() {')
print(upload_sheet[:1000])


import re

with open('mobile_app/lib/screens/chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r"final res = await Supabase\.instance\.client\s*\.from\('messages'\)\s*\.select\('sender_id, content, created_at'\)\s*\.eq\('chat_id', widget\.chatId\)\s*\.order\('created_at', ascending: true\);",
    r"final res = await SocketService.fetchOldMessages(widget.chatId);",
    content, flags=re.DOTALL
)

content = re.sub(
    r"final user = Supabase\.instance\.client\.auth\.currentUser;\s*if \(user != null\) \{\s*Supabase\.instance\.client\s*\.from\('messages'\)\s*\.update\(\{'is_read': true\}\)\s*\.eq\('chat_id', widget\.chatId\)\s*\.neq\('sender_id', user\.id\);\s*\}",
    r"final user = Provider.of<AuthProvider>(context, listen: false).user;\n      if (user != null) {\n        await SocketService.markAsRead(widget.chatId, user['id']);\n      }",
    content, flags=re.DOTALL
)

with open('mobile_app/lib/screens/chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched chat_screen.dart')

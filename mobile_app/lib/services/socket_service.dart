import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;

  static void connect(String userId) {
    // Wrapped in try-catch — socket server being offline must never crash auth
    try {
      if (_socket != null && _socket!.connected) return;
      _socket = IO.io(
        'https://pitch-and-sell-backend.onrender.com',
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setTimeout(3000)
          .build(),
      );
      _socket!.connect();
      _socket!.onConnect((_) => print('Socket connected'));
      _socket!.onConnectError((e) => print('Socket connect error: $e'));
      _socket!.onDisconnect((_) => print('Socket disconnected'));
    } catch (e) {
      print('SocketService.connect error: $e');
    }
  }

  static void joinChat(String chatId) {
    try { _socket?.emit('join_chat', chatId); } catch (_) {}
  }

  static void sendMessage(String chatId, String senderId, String content) {
    try {
      _socket?.emit('send_message', {
        'chatId': chatId,
        'senderId': senderId,
        'content': content,
      });
    } catch (_) {}
  }

  static void onReceiveMessage(Function(dynamic) callback) {
    try {
      _socket?.on('receive_message', (data) => callback(data));
    } catch (_) {}
  }

  static void disconnect() {
    try {
      _socket?.disconnect();
      _socket = null;
    } catch (_) {}
  }
}
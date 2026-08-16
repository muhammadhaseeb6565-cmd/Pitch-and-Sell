import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;

  static void connect(String userId) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io('http://127.0.0.1:5000', IO.OptionBuilder()
      .setTransports(['websocket']) // for Flutter compatibility
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Connected to Socket Server');
    });

    _socket!.onDisconnect((_) => print('Disconnected from Socket Server'));
  }

  static void joinChat(String chatId) {
    _socket?.emit('join_chat', chatId);
  }

  static void sendMessage(String chatId, String senderId, String content) {
    _socket?.emit('send_message', {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
    });
  }

  static void onReceiveMessage(Function(dynamic) callback) {
    _socket?.on('receive_message', (data) {
      callback(data);
    });
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}

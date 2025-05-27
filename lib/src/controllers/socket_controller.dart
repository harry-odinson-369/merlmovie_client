import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketController {
  WebSocketChannel? _channel;
  StreamController<dynamic>? _controller;
  StreamSubscription<dynamic>? _subscription;

  SocketController(String host) {
    _controller = StreamController<dynamic>.broadcast();
    _channel = WebSocketChannel.connect(Uri.parse(host));
    _subscription = _channel?.stream.listen((event) {
        _controller?.add(event);
      },
      onError: (err) {
        _controller?.addError(err);
      },
    );
  }

  Stream<dynamic>? get message => _controller?.stream;

  Future<bool> get ready async {
    try {
      await _channel?.ready.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw "Connection timeout!";
        },
      );
      return true;
    } catch (err) {
      debugPrint("[WebSocket] Error => ${err.toString()}");
      return false;
    }
  }

  void sendMessage(String msg) => _channel?.sink.add(msg);

  Future close() async {
    await _channel?.sink.close();
    await _controller?.close();
    await _subscription?.cancel();
    _channel = null;
    _controller = null;
    _subscription = null;
  }
}
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:merlmovie_client/src/models/cast_action.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketController {
  WebSocketChannel? _channel;
  StreamController<dynamic>? _controller;
  StreamSubscription<dynamic>? _subscription;
  Duration? _timeout;

  SocketController(String host, {Duration? timeout}) {
    _timeout = timeout;
    _controller = StreamController<dynamic>.broadcast();
    _channel = WebSocketChannel.connect(Uri.parse(host));
    _subscription = _channel?.stream.listen(
      (event) {
        _controller?.add(event);
      },
      onError: (err) {
        _controller?.addError(err);
      },
      onDone: () {
        _controller?.add("closed");
      }
    );
  }

  Stream<dynamic>? get message => _controller?.stream;

  Future<bool> get ready async {
    try {
      await _channel?.ready.timeout(
        _timeout ?? Duration(seconds: 8),
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

  void sendMessage(dynamic msg) {
    if (msg is ServerAction) {
      _channel?.sink.add(json.encode(msg.encoded));
    } else if (msg is String) {
      _channel?.sink.add(msg);
    } else {
      _channel?.sink.add(json.encode(msg));
    }
  }

  Future close() async {
    await _channel?.sink.close();
    await _controller?.close();
    await _subscription?.cancel();
    _channel = null;
    _controller = null;
    _subscription = null;
  }
}

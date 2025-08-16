import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:merlmovie_client/src/models/cast_action.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketController {
  WebSocketChannel? _channel;
  StreamController<dynamic>? _controller;
  StreamController<dynamic>? _errorController;
  StreamController<dynamic>? _closedController;
  StreamSubscription<dynamic>? _subscription;
  Duration? _timeout;

  SocketController(String host, {Duration? timeout}) {
    _timeout = timeout;
    _controller = StreamController<dynamic>.broadcast();
    _errorController = StreamController<dynamic>.broadcast();
    _closedController = StreamController<dynamic>.broadcast();
    _channel = WebSocketChannel.connect(Uri.parse(host));
    _subscription = _channel?.stream.listen(
      (event) {
        _controller?.add(event);
      },
      onError: (err) {
        _errorController?.add(err);
      },
      onDone: () {
        _closedController?.add("closed");
      },
    );
  }

  Stream<dynamic>? get onMessage => _controller?.stream;
  Stream<dynamic>? get onError => _errorController?.stream;
  Stream<dynamic>? get onClosed => _closedController?.stream;

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
    try {
      if (msg is ServerAction) {
        _channel?.sink.add(json.encode(msg.encoded));
      } else if (msg is String) {
        _channel?.sink.add(msg);
      } else {
        _channel?.sink.add(json.encode(msg));
      }
    } catch (err) {
      log(err.toString());
    }
  }

  Future close() async {
    await _channel?.sink.close();
    await _controller?.close();
    await _errorController?.close();
    await _closedController?.close();
    await _subscription?.cancel();
    _channel = null;
    _controller = null;
    _errorController = null;
    _closedController = null;
    _subscription = null;
  }
}

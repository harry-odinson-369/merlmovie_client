import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:merlmovie_client/merlmovie_client.dart';
import 'package:merlmovie_client/src/cast_receiver/models/action.dart';
import 'package:wifi_address_helper/wifi_address_helper.dart';

class ServerControl {
  ServerControl._();

  static final int _port = 3679;

  static final ServerControl _instance = ServerControl._();
  static ServerControl get instance => _instance;

  ValueNotifier<LandingModel> landing = ValueNotifier(
    LandingModel(appName: "Media Receiver"),
  );

  void setLanding(LandingModel model) => landing.value = model;

  void listen(
    void Function(ServerAction action, WebSocket socket) handle, {
    void Function(HttpServer server)? onBind,
    void Function(WebSocket socket)? onCreated,
    void Function()? onDone,
  }) async {
    String? address = await WifiAddressHelper.getAddress;
    if (address == null) throw Exception("The address was null!");
    var server = await HttpServer.bind(address, _port);
    onBind?.call(server);
    await for (HttpRequest request in server) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        onCreated?.call(socket);
        socket.listen((message) async {
          var msg = ServerAction.parse(message);
          if (msg.action == ActionServer.connect) {
            if (msg.payload.isNotEmpty) {
              landing.value = LandingModel.fromMap(msg.payload);
            }
            var info = await DeviceInfoPlugin().androidInfo;
            socket.add(
              json.encode(
                ServerAction(
                  action: ActionServer.connected,
                  payload:
                      CastDeviceInfo(
                        appName: "TV-Receiver",
                        deviceName: info.name,
                        deviceModel: info.model,
                      ).toMap(),
                ).toMap(),
              ),
            );
          } else {
            handle(msg, socket);
          }
        }, onDone: onDone);
      } else {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..close();
      }
    }
  }
}

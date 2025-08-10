// ignore_for_file: constant_identifier_names

import 'dart:convert';

enum ActionServer {
  idle,
  start,
  play,
  pause,
  forward,
  rewind,
  status,
  disconnect,
  connected,
  connect,
  subtitle,
  subtitle_theme,
  loading,
  seek,
  video_mode,
  video_loaded,
  video_error,
  playback_speed,
}

class ServerAction {
  ActionServer action = ActionServer.idle;
  Map<String, dynamic> payload = {};

  ServerAction({this.action = ActionServer.idle, this.payload = const {}});

  factory ServerAction.fromMap(Map<String, dynamic> map) => ServerAction(
    action: ActionServer.values.firstWhere(
      (e) => e.name == (map["action"] ?? "idle"),
    ),
    payload: map["payload"] ?? {},
  );

  factory ServerAction.parse(dynamic message) =>
      ServerAction.fromMap(json.decode(message.toString()));

  Map<String, dynamic> toMap() => {"action": action.name, "payload": payload};

  String get encoded => json.encode(toMap());
}

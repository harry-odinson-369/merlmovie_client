import 'package:flutter/material.dart';
import 'package:merlmovie_client/src/providers/player_state.dart';
import 'package:provider/provider.dart';

extension GlobalKeyExtension on GlobalKey<NavigatorState> {
  bool get isPlayerActive =>
      currentContext?.read<PlayerStateProvider>().isPlaying == true;
}

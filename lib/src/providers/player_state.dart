import 'package:flutter/foundation.dart';

class PlayerStateProvider extends ChangeNotifier {

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  void setValue(bool value) {
    _isPlaying = value;
    notifyListeners();
    isPlayingNotifier.value = value;
  }

}
import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:merlmovie_client/src/extensions/completer.dart';
import 'package:video_player/video_player.dart';

class VideoAdController {
  VideoAdController({
    required this.adUnitId,
    this.controller,
    this.interval = const Duration(minutes: 15),
  });

  VideoPlayerController? controller;

  String adUnitId;
  bool isShowing = false;
  bool isCooldown = true;
  Duration interval = const Duration(minutes: 15);

  Function? onShowed;
  Function? onClosed;

  Timer? _timer;

  void start() {
    controller?.addListener(_playerListener);
    _timer = _createNewTimer();
  }

  Future<bool> show() async {
    isCooldown = true;
    Completer<bool> completer = Completer<bool>();
    var advertisement = await _requestAd();
    if (advertisement == null) {
      isShowing = false;
      _timer = _createNewTimer();
      completer.finish(false);
      return false;
    }
    advertisement.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        isShowing = true;
        onShowed?.call();
      },
      onAdDismissedFullScreenContent: (ad) {
        isShowing = false;
        onClosed?.call();
        _timer = _createNewTimer();
        completer.finish(true);
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        isShowing = false;
        isCooldown = false;
        completer.finish(false);
        ad.dispose();
      },
    );
    advertisement.show();
    return completer.future;
  }

  Timer _createNewTimer() {
    _timer?.cancel();
    _timer = null;
    return Timer(interval, () => isCooldown = false);
  }

  Future<InterstitialAd?> _requestAd() async {
    var completer = Completer<InterstitialAd?>();
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => completer.finish(ad),
        onAdFailedToLoad: (error) => completer.finish(null),
      ),
    );
    return completer.future;
  }

  void _playerListener() {
    if (controller?.value.isPlaying == true && !isShowing && !isCooldown) {
      show();
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    onShowed = null;
    onClosed = null;
    controller?.removeListener(_playerListener);
  }
}

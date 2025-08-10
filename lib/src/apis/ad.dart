import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:merlmovie_client/src/extensions/completer.dart';
import 'package:video_player/video_player.dart';

class VideoAdController {
  VideoAdController({
    required this.adUnitId,
    required this.controller,
    this.interval = const Duration(minutes: 15),
  });

  VideoPlayerController controller;

  String adUnitId;
  bool isShowing = false;
  bool isCooldown = true;
  Duration interval = const Duration(minutes: 15);

  Function? onShowed;
  Function? onClosed;

  Timer? _timer;

  void start() {
    controller.addListener(_playerListener);
    _timer = Timer(interval, () => isCooldown = false);
  }

  Future<bool> _show() async {
    Completer<bool> completer = Completer<bool>();
    var advertisement = await _requestAd();
    if (advertisement == null) {
      isCooldown = false;
      completer.finish(false);
      return false;
    }
    advertisement.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        isShowing = true;
        isCooldown = true;
        onShowed?.call();
      },
      onAdDismissedFullScreenContent: (ad) {
        isShowing = false;
        onClosed?.call();
        _timer?.cancel();
        _timer = null;
        _timer = Timer(interval, () => isCooldown = false);
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
    if (controller.value.isPlaying && !isShowing && !isCooldown) _show();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    controller.removeListener(_playerListener);
  }
}

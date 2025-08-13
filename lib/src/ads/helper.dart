import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:merlmovie_client/src/extensions/completer.dart';
import 'package:merlmovie_client/src/extensions/list.dart';

enum AdState { idle, showing, cooldown, requesting }

class AdWithView {
  InterstitialAd? interstitialAd;
  AppOpenAd? appOpenAd;

  AdWithView({this.appOpenAd, this.interstitialAd});
}

abstract class BaseAd<T> {
  bool _isDisposed = false;
  AdState state = AdState.cooldown;
  late String adUnitId;
  Duration interval = Duration(minutes: 5);
  Timer? _timer;

  Future initialize(String adUnitId, {Duration? interval});
  Future<bool> show({List<BaseAd> variants = const []});
  Future<AdWithView?> request();
  void dispose();
  void cooldown();

  Timer _createNewTimer() {
    _timer?.cancel();
    _timer = null;
    return Timer(interval, () => state = AdState.idle);
  }
}

class GoogleAdHelper<T> extends BaseAd<T> {
  @override
  void dispose() {
    assert(!_isDisposed, "${runtimeType.toString()} has been disposed.");
    _timer?.cancel();
    _timer = null;
    _isDisposed = true;
  }

  @override
  Future initialize(String adUnitId, {Duration? interval}) async {
    assert(!_isDisposed, "${runtimeType.toString()} has been disposed.");
    this.adUnitId = adUnitId;
    this.interval = interval ?? this.interval;
    _timer = _createNewTimer();
  }

  @override
  Future<AdWithView?> request() {
    assert(!_isDisposed, "${runtimeType.toString()} has been disposed.");
    var completer = Completer<AdWithView?>();
    if (T == AppOpenAd) {
      AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            completer.finish(AdWithView(appOpenAd: ad));
          },
          onAdFailedToLoad: (error) {
            completer.finish(null);
          },
        ),
      );
    } else if (T == InterstitialAd) {
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            completer.finish(AdWithView(interstitialAd: ad));
          },
          onAdFailedToLoad: (error) {
            completer.finish(null);
          },
        ),
      );
    } else {
      completer.finish(null);
      throw UnsupportedError("Unsupported ad type $T");
    }
    return completer.future;
  }

  @override
  Future<bool> show({List<BaseAd> variants = const []}) async {
    assert(!_isDisposed, "${runtimeType.toString()} has been disposed.");
    if (variants.exist(
      (e) => e.state == AdState.requesting || e.state == AdState.showing,
    )) {
      return false;
    }
    var completer = Completer<bool>();
    if (state == AdState.idle) {
      state = AdState.requesting;
      var ad = await request();
      if (ad == null) {
        state = AdState.cooldown;
        _timer = _createNewTimer();
        completer.finish(false);
      } else {
        ad.interstitialAd?.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
          onAdShowedFullScreenContent: (ad) {
            state = AdState.showing;
          },
          onAdDismissedFullScreenContent: (ad) {
            state = AdState.cooldown;
            completer.finish(true);
            ad.dispose();
            _timer = _createNewTimer();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            state = AdState.idle;
            completer.finish(false);
            ad.dispose();
          },
        );
        ad.interstitialAd?.show();
        ad.appOpenAd?.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
          onAdShowedFullScreenContent: (ad) {
            state = AdState.showing;
          },
          onAdDismissedFullScreenContent: (ad) {
            state = AdState.cooldown;
            completer.finish(true);
            ad.dispose();
            _timer = _createNewTimer();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            state = AdState.idle;
            completer.finish(false);
            ad.dispose();
          },
        );
        ad.appOpenAd?.show();
      }
    }
    bool isShowed = await completer.future;
    if (isShowed) {
      for (BaseAd ad in variants) {
        ad.cooldown();
      }
    }
    return isShowed;
  }

  @override
  void cooldown() {
    state = AdState.cooldown;
    _timer = _createNewTimer();
  }
}

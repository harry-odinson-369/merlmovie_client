import 'dart:async';
import 'dart:developer';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:merlmovie_client/src/extensions/completer.dart';
import 'package:merlmovie_client/src/helpers/generate.dart';

String? _unitId;
Duration? _minDur;
Duration? _maxDur;
bool _isAppActive = true;
bool _debug = false;

class GAdController {
  static Duration defMaxDur = Duration(minutes: 10);
  static Duration defMinDur = Duration(minutes: 5);

  bool _isShowing = false;
  bool get isShowing => _isShowing;

  bool _isRetrying = false;

  Timer? _interval;

  int _scheduleInSeconds = 0;

  Function? onClosed;
  Function? onShowed;
  Function? onShowFailed;

  static void _log(String msg) {
    if (_debug) log("\n\n[GAdController] $msg\n\n");
  }

  static void setAppState(bool isActive) {
    _isAppActive = isActive;
  }

  static void setAdUnitId(String adUnitId) {
    _unitId = adUnitId;
  }

  static void setDuration(Duration min, Duration max) {
    _minDur = min;
    _maxDur = max;
  }

  static void setDebugLog(bool isDebug) {
    _debug = isDebug;
  }

  static Future<ConsentStatus> requestConsent({
    ConsentDebugSettings? consentDebugSettings,
  }) async {
    _log("Requesting user consent");
    final completer = Completer<ConsentStatus>();
    final params = ConsentRequestParameters(
      consentDebugSettings: consentDebugSettings,
    );
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          var state = await ConsentInformation.instance.getConsentStatus();
          completer.finish(state);
        });
      },
      (error) async {
        var state = await ConsentInformation.instance.getConsentStatus();
        completer.finish(state);
      },
    );
    final state = await completer.future;
    _log("Consent state ${state.name}");
    return state;
  }

  void create({String? adUnitId, Duration? min, Duration? max}) {
    if (adUnitId != null) _unitId = adUnitId;
    if (min != null) _minDur = min;
    if (max != null) _maxDur = max;
    _scheduleNext();
  }

  void _scheduleNext() {
    _interval?.cancel();
    _interval = null;
    int min = (_minDur ?? defMinDur).inSeconds;
    int max = (_maxDur ?? defMaxDur).inSeconds;
    final delay = Duration(seconds: GenerateHelper.random(min, max));
    _scheduleInSeconds = delay.inSeconds;
    _interval = Timer(delay, _show);
    _log("Schedule the next ad in ${delay.inSeconds} seconds");
  }

  Future<bool> _canRequestAd() async {
    if (_unitId == null) return false;
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      return true;
    }
  }

  Future _show() async {
    if (_isShowing) {
      _log("Ad is showing");
      _scheduleNext();
      return;
    }
    if (!await _canRequestAd()) {
      _log("Cannot request ad, ${_unitId == null ? "unitId cannot be null" : "user has not consent"}!");
      _scheduleNext();
      return;
    }
    if (!_isAppActive) {
      _log("Cannot request/show ad while the app is in background.");
      _scheduleNext();
      return;
    }
    final ad = await _requestAndShow();
    if (ad == null && !_isRetrying) {
      _isRetrying = true;
      final delay = GenerateHelper.random(30, 60);
      _log("1st Ad failed to load, retry once again in the next $delay seconds.");
      await Future.delayed(Duration(seconds: delay));
      if (!_isShowing && _isAppActive) {
        await _requestAndShow();
      } else {
        _scheduleNext();
      }
      _isRetrying = false;
    }
  }

  Future<InterstitialAd?> _requestAndShow() {
    final completer = Completer<InterstitialAd?>();
    if (_unitId == null) {
      completer.finish(null);
      return completer.future;
    }
    _log("Requesting a new ad at schedule time in $_scheduleInSeconds seconds");
    InterstitialAd.load(
      adUnitId: _unitId!,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) async {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _log("Ad showed fullscreen content.");
              _isShowing = true;
              onShowed?.call();
            },
            onAdDismissedFullScreenContent: (ad) async {
              _log("Ad closed");
              _scheduleNext();
              _isShowing = false;
              onClosed?.call();
              Future.delayed(const Duration(seconds: 8), () {
                ad.dispose();
              });
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _log("Ad failed to show fullscreen content");
              _scheduleNext();
              _isShowing = false;
              onShowFailed?.call();
              ad.dispose();
            },
          );
          completer.finish(ad);
          final delay = GenerateHelper.random(6, 30);
          await Future.delayed(Duration(seconds: delay));
          ad.show().catchError((_) {});
          _log("Start showing ad. total time in ${_scheduleInSeconds + delay} seconds");
        },
        onAdFailedToLoad: (error) {
          completer.finish(null);
        },
      ),
    );
    return completer.future;
  }

  void dispose() {
    _interval?.cancel();
    _interval = null;
  }

}

import 'dart:async';
import 'dart:developer';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:merlmovie_client/src/extensions/completer.dart';

bool _debug = false;
GAdConfig _globalConfig = GAdConfig();

class GAdConfig {
  Duration interval;
  String unitId;

  GAdConfig({this.interval = const Duration(minutes: 15), this.unitId = ""});
}

class GAdHelper {
  GAdConfig? _option;
  GAdConfig get config => _option ?? _globalConfig;

  late DateTime _lastShowTime;

  bool _isShowing = false;
  bool _isLoading = false;

  Timer? _timer;

  String debugName = "GAdHelper";

  InterstitialAd? _preloadedAd;

  Function? onShowed;
  Function? onClosed;
  Function? onFailed;

  bool get canShowAd {
    var diff = DateTime.now().difference(_lastShowTime);
    return diff.inMinutes >= config.interval.inMinutes;
  }

  void _log(String msg, [String? prefix]) {
    if (_debug) log("[${prefix ?? debugName}] $msg");
  }

  void configure(GAdConfig conf) {
    _option = conf;
  }

  static void setGlobalConfig(GAdConfig conf) {
    _globalConfig = conf;
  }

  static Future<InitializationStatus> initialize({
    ConsentDebugSettings? consentDebugSettings,
    bool debug = false,
  }) async {
    _debug = debug;
    final status = await MobileAds.instance.initialize();
    if (_debug) log("[GAdHelper] MobileAds initialized.");
    final params = ConsentRequestParameters(
      consentDebugSettings: consentDebugSettings,
    );
    final completer = Completer<void>();
    if (_debug) log("[GAdHelper] Requesting user consent info update...");
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (_debug) log("[GAdHelper] Consent info updated.");
        ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            if (_debug) {
              log("[GAdHelper] Consent form error: ${formError.message}");
            }
          } else {
            final consentStatus =
                await ConsentInformation.instance.getConsentStatus();
            if (_debug) {
              log("[GAdHelper] Consent form status: ${consentStatus.name}");
            }
          }
          completer.finish();
        });
      },
      (error) {
        if (_debug) {
          log("[GAdHelper] Consent info update failed: ${error.message}");
        }
        completer.finish();
      },
    );
    await completer.future;
    if (_debug) log("[GAdHelper] UMP consent process finished.");
    return status;
  }

  void create({bool autoShow = false}) {
    _lastShowTime = DateTime.now();
    _timer ??= Timer.periodic(Duration(seconds: 1), (_) {
      _checkAndShow(autoShow: autoShow);
    });
    _log("Created ad timer.");
  }

  void destroy() {
    _timer?.cancel();
    _timer = null;
  }

  void _checkAndShow({bool autoShow = false}) {
    if (config.unitId.isEmpty) {
      _log("unitId cannot be empty.");
      return;
    }
    if (_isShowing) return;
    final diff = DateTime.now().difference(_lastShowTime);
    final isReadyToShow = diff.inMinutes >= config.interval.inMinutes;
    final isNearTime = diff.inMinutes >= (config.interval.inMinutes - 1);
    if (isNearTime && !isReadyToShow) {
      _preloadAd(autoShow: autoShow);
      return;
    }
    if (!isReadyToShow) return;
  }

  void showAd() {
    if (_isShowing) {
      _log("Ad is showing.");
      return;
    }
    if (!canShowAd) {
      _log("Ad is in cooldown.");
      return;
    }
    if (_preloadedAd != null) {
      _isShowing = true;
      _log("Start showing ad.");
      _attachCallbacksAndShow(_preloadedAd!);
      _preloadedAd = null;
      return;
    }
  }

  void _preloadAd({bool autoShow = false}) {
    if (_preloadedAd != null || _isLoading) return;
    _isLoading = true;
    _log("Preloading ad in 1 min left.");
    InterstitialAd.load(
      adUnitId: config.unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _preloadedAd = ad;
          if (autoShow) {
            _isShowing = true;
            _attachCallbacksAndShow(_preloadedAd!);
          }
          _isLoading = false;
          _log("Ad preloaded.");
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _preloadedAd?.dispose();
          _preloadedAd = null;
          _log("Failed to preload ad: Code ${error.code}");
        },
      ),
    );
  }

  void _attachCallbacksAndShow(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        onClosed?.call();
        ad.dispose();
        _isShowing = false;
        _lastShowTime = DateTime.now();
        _log("Ad closed.");
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        onFailed?.call();
        ad.dispose();
        _isShowing = false;
        _log("Failed to show ad: Code ${error.code}, ${error.message}");
      },
      onAdShowedFullScreenContent: (ad) {
        onShowed?.call();
        _log("Ad showed fullscreen.");
      },
      onAdClicked: (ad) {
        _log("Ad clicked.");
      },
      onAdImpression: (ad) {
        _log("Ad impression.");
      },
    );
    ad.show();
  }
}

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  AppOpenAdManager({required this.adUnitId});

  final String adUnitId;

  static const Duration _maxCacheDuration = Duration(hours: 4);
  static const Duration _minimumShowInterval = Duration(minutes: 2);

  AppOpenAd? _appOpenAd;
  bool _isLoadingAd = false;
  bool _isShowingAd = false;
  bool _showOnLoad = false;
  DateTime? _loadedAt;
  DateTime? _lastShownAt;

  bool get _isAdAvailable {
    final loadedAt = _loadedAt;
    if (_appOpenAd == null || loadedAt == null) {
      return false;
    }
    return DateTime.now().difference(loadedAt) < _maxCacheDuration;
  }

  void loadAd({bool showOnLoad = false}) {
    if (_isLoadingAd) {
      _showOnLoad = _showOnLoad || showOnLoad;
      return;
    }

    _isLoadingAd = true;
    _showOnLoad = _showOnLoad || showOnLoad;

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _loadedAt = DateTime.now();
          _isLoadingAd = false;

          if (_showOnLoad) {
            _showOnLoad = false;
            showAdIfAvailable();
          }
        },
        onAdFailedToLoad: (error) {
          _isLoadingAd = false;
          _showOnLoad = false;
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  void showAdIfAvailable() {
    if (_isShowingAd) {
      return;
    }

    final lastShownAt = _lastShownAt;
    if (lastShownAt != null &&
        DateTime.now().difference(lastShownAt) < _minimumShowInterval) {
      return;
    }

    if (!_isAdAvailable) {
      loadAd(showOnLoad: true);
      return;
    }

    final ad = _appOpenAd!;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        _lastShownAt = DateTime.now();
        ad.dispose();
        _appOpenAd = null;
        _loadedAt = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadedAt = null;
        debugPrint('AppOpenAd failed to show: $error');
        loadAd();
      },
    );

    ad.show();
  }

  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}

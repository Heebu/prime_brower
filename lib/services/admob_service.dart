import 'package:flutter/foundation.dart';

class AdMobService with ChangeNotifier {
  static const String testBannerUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String testBannerUnitIdIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String testNativeUnitIdAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const String testNativeUnitIdIos = 'ca-app-pub-3940256099942544/3986624511';

  bool _isInitialized = false;
  int _impressionsCount = 0;
  int _clicksCount = 0;

  bool get isInitialized => _isInitialized;
  int get impressionsCount => _impressionsCount;
  int get clicksCount => _clicksCount;

  String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return testBannerUnitIdIos;
    }
    return testBannerUnitIdAndroid;
  }

  String get nativeAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return testNativeUnitIdIos;
    }
    return testNativeUnitIdAndroid;
  }

  AdMobService() {
    _init();
  }

  void _init() {
    // Flag service as ready for rendering AdMob slots
    _isInitialized = true;
  }

  void recordImpression() {
    _impressionsCount++;
    notifyListeners();
  }

  void recordClick() {
    _clicksCount++;
    notifyListeners();
  }
}

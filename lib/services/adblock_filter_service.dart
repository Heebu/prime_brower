import 'dart:collection';

class AdBlockFilterService {
  static final AdBlockFilterService _instance = AdBlockFilterService._internal();
  factory AdBlockFilterService() => _instance;
  AdBlockFilterService._internal();

  final Set<String> _whitelistedDomains = <String>{};

  /// High-speed HashSet of known ad, tracker, analytics, and telemetry host domains
  static final HashSet<String> _blockedDomains = HashSet<String>.from([
    // Major Ad Networks
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'google-analytics.com',
    'adnxs.com',
    'criteo.com',
    'criteo.net',
    'rubiconproject.com',
    'pubmatic.com',
    'openx.net',
    'casalemedia.com',
    'bidswitch.net',
    'smartadserver.com',
    'amazon-adsystem.com',
    'advertising.com',
    'yieldmo.com',
    'indexww.com',
    'outbrain.com',
    'taboola.com',
    'popads.net',
    'propellerads.com',
    'adcash.com',
    'revcontent.com',
    'adblade.com',
    'mgid.com',
    'inmobi.com',
    'applovin.com',
    'unityads.unity3d.com',
    'ironsrc.com',
    'vungle.com',
    'chartboost.com',
    'adcolony.com',
    'adroll.com',
    'moatads.com',
    'adservice.google.com',
    'pagead2.googlesyndication.com',
    'pagead2.googleadservices.com',
    'adtechus.com',
    'advertising.yahoo.com',
    'adtech.de',
    'media.net',
    'sovrn.com',
    'conversantmedia.com',
    'exponential.com',
    'tribalfusion.com',
    'zedo.com',
    'adbutler.com',
    'clicksor.com',
    'bidvertiser.com',

    // Trackers & Analytics
    'scorecardresearch.com',
    'quantserve.com',
    'hotjar.com',
    'mouseflow.com',
    'crazyegg.com',
    'fullstory.com',
    'segment.io',
    'segment.com',
    'mixpanel.com',
    'amplitude.com',
    'branch.io',
    'appsflyer.com',
    'adjust.com',
    'kochava.com',
    'singular.net',
    'flurry.com',
    'telemetry.api',
    'newrelic.com',
    'nr-data.net',
    'browser-update.org',
    'luckyorange.com',
    'clarity.ms',
    'statcounter.com',
    'histats.com',
    'alexa.com',
    'chartbeat.com',
    'optimizely.com',
    'kissmetrics.io',
    'heapanalytics.com',
    'bugsnag.com',
    'sentry.io/api',

    // Social Trackers & Beacons
    'facebook.com/tr',
    'connect.facebook.net',
    'facebook.net',
    'analytics.twitter.com',
    'static.ads-twitter.com',
    'ads-twitter.com',
    'ads.linkedin.com',
    'px.ads.linkedin.com',
    'ads.tiktok.com',
    'analytics.tiktok.com',
    'pinterest.com/ct',
    'ct.pinterest.com',
    'ads.reddit.com',
    'events.reddit.com',
  ]);

  /// Common tracking query parameters and URL patterns
  static final List<RegExp> _trackingUrlPatterns = [
    RegExp(r'[?&](fbclid|gclid|utm_source|utm_medium|utm_campaign|utm_term|utm_content)=', caseSensitive: false),
    RegExp(r'/ads?(\.js|_banner|\.min\.js|/display/|/track/)', caseSensitive: false),
    RegExp(r'/(doubleclick|googlesyndication|adservice)/', caseSensitive: false),
    RegExp(r'/(tracker|telemetry|analytics|beacon)\.(js|php|gif|png)', caseSensitive: false),
    RegExp(r'fbevents(\.min)?\.js', caseSensitive: false),
  ];

  Set<String> get whitelistedDomains => Set.unmodifiable(_whitelistedDomains);

  void whitelistDomain(String domain) {
    final cleaned = _extractHost(domain);
    if (cleaned.isNotEmpty) {
      _whitelistedDomains.add(cleaned);
    }
  }

  void removeWhitelistDomain(String domain) {
    final cleaned = _extractHost(domain);
    _whitelistedDomains.remove(cleaned);
  }

  bool isWhitelisted(String urlOrDomain) {
    final host = _extractHost(urlOrDomain);
    return _whitelistedDomains.contains(host);
  }

  String _extractHost(String urlOrDomain) {
    var host = urlOrDomain.trim().toLowerCase();
    if (host.startsWith('http://') || host.startsWith('https://')) {
      try {
        final uri = Uri.parse(host);
        host = uri.host;
      } catch (_) {}
    }
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }
    return host;
  }

  /// Evaluates whether a network URL corresponds to a known ad, tracker, or telemetry endpoint
  bool isAdOrTracker(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;

    // Check if domain is whitelisted by user
    if (isWhitelisted(trimmed)) return false;

    String host = '';
    try {
      final uri = Uri.parse(trimmed);
      host = uri.host.toLowerCase();
    } catch (_) {
      return false;
    }

    if (host.isEmpty) return false;

    final lowerUrl = trimmed.toLowerCase();

    // 1. Direct or suffix domain match against blocked list
    for (final blocked in _blockedDomains) {
      final lowerBlocked = blocked.toLowerCase();
      if (host == lowerBlocked || host.endsWith('.$lowerBlocked') || lowerUrl.contains(lowerBlocked)) {
        return true;
      }
    }

    // 2. RegEx patterns for ad scripts, tracking beacons, and analytics
    for (final regex in _trackingUrlPatterns) {
      if (regex.hasMatch(trimmed)) {
        return true;
      }
    }

    return false;
  }
}

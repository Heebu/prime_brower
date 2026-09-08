import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_item.dart';
import '../models/ad_item.dart';
import 'admob_service.dart';

class FeedEntry {
  final NewsFeedItem? news;
  final SponsoredAdItem? ad;

  const FeedEntry.news(NewsFeedItem item)
      : news = item,
        ad = null;

  const FeedEntry.ad(SponsoredAdItem item)
      : ad = item,
        news = null;

  bool get isAd => ad != null;
  bool get isNews => news != null;
  String get id => isAd ? ad!.id : news!.id;
}

class FeedAdService with ChangeNotifier {
  final AdMobService admobService;
  FirebaseFirestore? _firestore;
  bool _isLoading = false;
  bool _isInitialized = false;

  final String _userDeviceId;
  final Map<String, int> _tabRefreshSeeds = {};

  List<NewsFeedItem> _firestoreNews = [];
  List<SponsoredAdItem> _firestoreAds = [];
  StreamSubscription<QuerySnapshot>? _newsSubscription;
  StreamSubscription<QuerySnapshot>? _adsSubscription;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String get userDeviceId => _userDeviceId;
  bool get isUsingFirestoreNews => _firestoreNews.isNotEmpty;
  int get firestoreNewsCount => _firestoreNews.length;
  List<NewsFeedItem> get firestoreNews => List.unmodifiable(_firestoreNews);

  FeedAdService({
    AdMobService? admobService,
    String? userDeviceId,
  })  : admobService = admobService ?? AdMobService(),
        _userDeviceId = userDeviceId ?? 'usr_${DateTime.now().millisecondsSinceEpoch % 100000}' {
    _initFirestore();
  }

  void _initFirestore() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
        _isInitialized = true;
        _listenToRemoteStreams();
        fetchRemoteFeedsAndAds();
      }
    } catch (e) {
      debugPrint('FeedAdService: Firestore not initialized: $e');
    }
  }

  void _listenToRemoteStreams() {
    if (_firestore == null) return;
    try {
      _newsSubscription?.cancel();
      _newsSubscription = _firestore!
          .collection('news_feeds')
          .limit(40)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _firestoreNews = snapshot.docs
              .map((doc) => NewsFeedItem.fromFirestore(doc))
              .toList();
          _firestoreNews.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('FeedAdService: News stream error: $e');
      });

      _adsSubscription?.cancel();
      _adsSubscription = _firestore!
          .collection('adverts')
          .limit(15)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _firestoreAds = snapshot.docs
              .map((doc) => SponsoredAdItem.fromFirestore(doc))
              .toList();
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('FeedAdService: Ads stream error: $e');
      });
    } catch (e) {
      debugPrint('FeedAdService: Stream setup notice: $e');
    }
  }

  Future<void> fetchRemoteFeedsAndAds() async {
    if (_firestore == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      var newsSnapshot = await _firestore!
          .collection('news_feeds')
          .limit(40)
          .get()
          .timeout(const Duration(seconds: 8));

      // Fallback query to 'news' collection if 'news_feeds' is empty
      if (newsSnapshot.docs.isEmpty) {
        newsSnapshot = await _firestore!
            .collection('news')
            .limit(40)
            .get()
            .timeout(const Duration(seconds: 8));
      }

      final adsSnapshot = await _firestore!
          .collection('adverts')
          .limit(15)
          .get()
          .timeout(const Duration(seconds: 8));

      if (newsSnapshot.docs.isNotEmpty) {
        _firestoreNews = newsSnapshot.docs
            .map((doc) => NewsFeedItem.fromFirestore(doc))
            .toList();
        _firestoreNews.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      }

      if (adsSnapshot.docs.isNotEmpty) {
        _firestoreAds = adsSnapshot.docs
            .map((doc) => SponsoredAdItem.fromFirestore(doc))
            .toList();
      }
    } catch (e) {
      debugPrint('FeedAdService: Error fetching remote feeds: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refreshTabFeed(String tabId) {
    _tabRefreshSeeds[tabId] = (_tabRefreshSeeds[tabId] ?? 0) + 1;
    notifyListeners();
  }

  /// Produces a deterministic yet unique randomized feed for each tab and user.
  List<FeedEntry> getFeedForTab({
    required String tabId,
    String selectedCategory = 'All',
  }) {
    final refreshCount = _tabRefreshSeeds[tabId] ?? 0;
    // Combine device ID, tab ID, and refresh count for distinct random entropy
    final seed = _userDeviceId.hashCode ^ tabId.hashCode ^ (refreshCount * 397);
    final random = Random(seed);

    // Prioritize Firebase saved news; fallback to defaults if offline or empty
    final allNews = _firestoreNews.isNotEmpty
        ? List<NewsFeedItem>.from(_firestoreNews)
        : List<NewsFeedItem>.from(_defaultNewsItems);

    // Deduplicate by ID
    final seenNewsIds = <String>{};
    final uniqueNews = <NewsFeedItem>[];
    for (final item in allNews) {
      if (seenNewsIds.add(item.id)) {
        uniqueNews.add(item);
      }
    }

    // Filter by category if requested
    final filteredNews = selectedCategory == 'All'
        ? List<NewsFeedItem>.from(uniqueNews)
        : uniqueNews.where((item) => item.category.toLowerCase() == selectedCategory.toLowerCase()).toList();

    // Shuffle news stories using the tab's random instance
    filteredNews.shuffle(random);

    // Combine ads (Firestore custom ads, default sponsored ads, and AdMob banner units)
    final allAds = _firestoreAds.isNotEmpty
        ? [
            ..._firestoreAds,
            _createAdMobUnit(tabId, 1),
            _createAdMobUnit(tabId, 2),
          ]
        : [
            ..._defaultSponsoredAds,
            _createAdMobUnit(tabId, 1),
            _createAdMobUnit(tabId, 2),
          ];

    final seenAdIds = <String>{};
    final uniqueAds = <SponsoredAdItem>[];
    for (final ad in allAds) {
      if (seenAdIds.add(ad.id)) {
        uniqueAds.add(ad);
      }
    }

    uniqueAds.shuffle(random);

    // Interleave ads into news feed (e.g. after every 3-4 news items)
    final List<FeedEntry> result = [];
    int adIndex = 0;

    for (int i = 0; i < filteredNews.length; i++) {
      result.add(FeedEntry.news(filteredNews[i]));

      // Insert an advert at position 2, 6, 11, etc.
      if ((i == 2 || (i > 2 && (i - 2) % 4 == 0)) && adIndex < uniqueAds.length) {
        result.add(FeedEntry.ad(uniqueAds[adIndex]));
        adIndex++;
      }
    }

    // If there were few news items or remaining ads, ensure at least one ad is included
    if (result.isNotEmpty && adIndex == 0 && uniqueAds.isNotEmpty) {
      result.insert(min(1, result.length), FeedEntry.ad(uniqueAds.first));
    }

    return result;
  }

  SponsoredAdItem _createAdMobUnit(String tabId, int unitIndex) {
    return SponsoredAdItem(
      id: 'admob_banner_${tabId}_$unitIndex',
      advertiserName: 'Google AdMob Network',
      headline: 'Discover Leading Cloud & Mobile Tools',
      description: 'Targeted relevant developer and tech services curated by Google AdMob.',
      ctaText: 'Visit Ad',
      targetUrl: 'https://admob.google.com',
      badge: 'Ad · AdMob',
      adType: AdType.admobBanner,
    );
  }

  // --- Curated Built-in Stories & Ads (Fallback & Instant Zero-Latency Load) ---

  static final List<NewsFeedItem> _defaultNewsItems = [
    NewsFeedItem(
      id: 'tech_quantum_1',
      title: 'Next-Gen Quantum Computing Chips Reach Critical 99.9% Coherence',
      description: 'Researchers achieve unprecedented logical qubit error-suppression, bringing commercial fault-tolerant quantum calculation years closer.',
      source: 'TechCrunch',
      url: 'https://techcrunch.com',
      category: 'Tech',
      publishedAt: DateTime(2026, 9, 7, 12, 15),
      readTimeMinutes: 3,
    ),
    NewsFeedItem(
      id: 'biz_green_energy_2',
      title: 'Global Renewable Energy Investment Surpasses Fossil Fuels by Record 40%',
      description: 'Solar microgrids and solid-state grid batteries drive unprecedented expansion across emerging economies and European markets.',
      source: 'Bloomberg',
      url: 'https://bloomberg.com',
      category: 'Business',
      publishedAt: DateTime(2026, 9, 7, 11, 40),
      readTimeMinutes: 4,
    ),
    NewsFeedItem(
      id: 'world_space_mars_3',
      title: 'Deep-Space Probe Confirms Subsurface Water Reservoirs on Martian South Pole',
      description: 'Radar sounding telemetry validates vast liquid brine lakes beneath the polar ice caps, pointing toward viable sites for future crewed bases.',
      source: 'Reuters',
      url: 'https://reuters.com',
      category: 'Science',
      publishedAt: DateTime(2026, 9, 7, 10, 50),
      readTimeMinutes: 5,
    ),
    NewsFeedItem(
      id: 'tech_ai_open_4',
      title: 'Compact Open-Source LLMs Achieve Parity with 100B Parameter Proprietary Models',
      description: 'New model quantization and architecture distillation techniques enable smartphones to run full coding and translation assistants entirely offline.',
      source: 'Ars Technica',
      url: 'https://arstechnica.com',
      category: 'Tech',
      publishedAt: DateTime(2026, 9, 7, 9, 30),
      readTimeMinutes: 3,
    ),
    NewsFeedItem(
      id: 'sports_olympics_5',
      title: 'High-Tech Biometric Wearables Reshape Training Regimens Ahead of World Games',
      description: 'Real-time lactic acid and muscle oxygen sensors give endurance runners and sprinters micro-adjustments during championship trials.',
      source: 'BBC Sport',
      url: 'https://bbc.com/sport',
      category: 'Sports',
      publishedAt: DateTime(2026, 9, 7, 8, 15),
      readTimeMinutes: 2,
    ),
    NewsFeedItem(
      id: 'biz_startup_funding_6',
      title: 'Seed-Stage Robotics Startups See Surge in Global Cross-Border Angel Financing',
      description: 'Autonomous logistics and agricultural harvesting bots capture renewed institutional capital as supply chain automation accelerates.',
      source: 'Wall Street Journal',
      url: 'https://wsj.com',
      category: 'Business',
      publishedAt: DateTime(2026, 9, 7, 7, 45),
      readTimeMinutes: 4,
    ),
    NewsFeedItem(
      id: 'world_summit_climate_7',
      title: 'Global Coastal Nations Ratify Landmark Ocean Protection & Restoration Accord',
      description: 'Treaty establishes protected international marine corridors covering over 30% of high seas to safeguard biodiversity and coral ecosystems.',
      source: 'The Guardian',
      url: 'https://theguardian.com',
      category: 'World',
      publishedAt: DateTime(2026, 9, 7, 6, 30),
      readTimeMinutes: 4,
    ),
    NewsFeedItem(
      id: 'sci_neurotech_8',
      title: 'Non-Invasive Neural Interface Translates Intended Speech to Text in Real-Time',
      description: 'Breakthrough EEG acoustic decoder enables patients with vocal cord injuries to communicate at 110 words per minute with 97% accuracy.',
      source: 'Nature',
      url: 'https://nature.com',
      category: 'Science',
      publishedAt: DateTime(2026, 9, 7, 5, 10),
      readTimeMinutes: 5,
    ),
    NewsFeedItem(
      id: 'tech_privacy_browser_9',
      title: 'Zero-Knowledge Cryptography Becomes Standard Across Next-Generation Web Apps',
      description: 'Client-side encrypted protocols and secure multi-party compute prevent telemetry harvesting while preserving rich cloud syncing capabilities.',
      source: 'Wired',
      url: 'https://wired.com',
      category: 'Tech',
      publishedAt: DateTime(2026, 9, 6, 22, 0),
      readTimeMinutes: 3,
    ),
    NewsFeedItem(
      id: 'sports_football_tactics_10',
      title: 'European Champions League Adopts AI Tactical Video Mapping for Referee Reviews',
      description: 'Automated 4D player limb tracking virtually eliminates offside controversy and cuts VAR decision times down to under ten seconds.',
      source: 'ESPN',
      url: 'https://espn.com',
      category: 'Sports',
      publishedAt: DateTime(2026, 9, 6, 20, 15),
      readTimeMinutes: 3,
    ),
    NewsFeedItem(
      id: 'biz_fintech_instant_11',
      title: 'Cross-Border Real-Time Settlement Network Cuts Remittance Fees to Under 0.5%',
      description: 'Direct central bank digital rails connect 28 nations, transforming foreign payments for small merchants and international workers.',
      source: 'Financial Times',
      url: 'https://ft.com',
      category: 'Business',
      publishedAt: DateTime(2026, 9, 6, 18, 30),
      readTimeMinutes: 4,
    ),
    NewsFeedItem(
      id: 'world_archeology_12',
      title: 'LiDAR Satellite Imaging Uncovers Massive Ancient Metropolis Hidden Under Canopy',
      description: 'Complex canal networks, stone roadways, and elevated plazas reveal an urban society dating back more than 2,500 years in the Amazon basin.',
      source: 'National Geographic',
      url: 'https://nationalgeographic.com',
      category: 'World',
      publishedAt: DateTime(2026, 9, 6, 16, 0),
      readTimeMinutes: 5,
    ),
  ];

  static final List<SponsoredAdItem> _defaultSponsoredAds = [
    const SponsoredAdItem(
      id: 'ad_prime_vpn_promo',
      advertiserName: 'Prime VPN Unlimited',
      headline: 'Protect Your Online Privacy Everywhere with 70% Off',
      description: 'High-speed WireGuard nodes across 90+ countries with military-grade encryption and zero DNS logs.',
      ctaText: 'Get 70% Discount',
      targetUrl: 'https://primebrowser.app/vpn',
      badge: 'Sponsored',
      adType: AdType.firebaseCustom,
    ),
    const SponsoredAdItem(
      id: 'ad_cloud_host_launch',
      advertiserName: 'CloudMatrix Developer Hosting',
      headline: 'Deploy Flutter & Docker Apps Globally in 30 Seconds',
      description: 'Instant edge deployments, free SSL certificates, and 100GB fast NVMe SSD storage included.',
      ctaText: 'Start Free Trial',
      targetUrl: 'https://cloudmatrix.dev',
      badge: 'Featured Partner',
      adType: AdType.firebaseCustom,
    ),
    const SponsoredAdItem(
      id: 'ad_quantum_academy',
      advertiserName: 'CodeSprint Academy',
      headline: 'Master Full-Stack Flutter & AI Engineering in 12 Weeks',
      description: 'Hands-on projects, 1-on-1 mentorship, and certified engineering diplomas recognized worldwide.',
      ctaText: 'Explore Courses',
      targetUrl: 'https://codesprint.io',
      badge: 'Sponsored',
      adType: AdType.firebaseCustom,
    ),
  ];

  /// Utility method to seed sample feed data into Firebase Firestore for testing
  Future<void> seedDemoDataToFirestore() async {
    if (_firestore == null) return;

    try {
      final batch = _firestore!.batch();

      for (final item in _defaultNewsItems) {
        final docRef = _firestore!.collection('news_feeds').doc(item.id);
        batch.set(docRef, item.toMap());
      }

      for (final ad in _defaultSponsoredAds) {
        final docRef = _firestore!.collection('adverts').doc(ad.id);
        batch.set(docRef, ad.toMap());
      }

      await batch.commit();
      debugPrint('FeedAdService: Successfully seeded demo feeds to Firestore!');
      await fetchRemoteFeedsAndAds();
    } catch (e) {
      debugPrint('FeedAdService: Error seeding demo data: $e');
    }
  }

  /// Seeds news and adverts into Firestore collections ('news_feeds', 'news', 'adverts')
  Future<int> seedRemoteNewsDatabase() async {
    if (_firestore == null) return 0;
    int count = 0;
    try {
      final batch = _firestore!.batch();
      for (final item in _defaultNewsItems) {
        final docRef1 = _firestore!.collection('news_feeds').doc(item.id);
        final docRef2 = _firestore!.collection('news').doc(item.id);
        batch.set(docRef1, item.toMap());
        batch.set(docRef2, item.toMap());
        count++;
      }
      for (final ad in _defaultSponsoredAds) {
        final docRef = _firestore!.collection('adverts').doc(ad.id);
        batch.set(docRef, ad.toMap());
      }
      await batch.commit();
      await fetchRemoteFeedsAndAds();
    } catch (e) {
      debugPrint('FeedAdService: Error in seedRemoteNewsDatabase: $e');
    }
    return count;
  }

  @override
  void dispose() {
    _newsSubscription?.cancel();
    _adsSubscription?.cancel();
    super.dispose();
  }
}

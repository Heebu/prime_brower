import 'package:cloud_firestore/cloud_firestore.dart';

enum AdType {
  firebaseCustom,
  admobBanner,
  admobNative,
}

class SponsoredAdItem {
  final String id;
  final String advertiserName;
  final String headline;
  final String description;
  final String ctaText;
  final String targetUrl;
  final String? imageUrl;
  final String badge;
  final AdType adType;

  const SponsoredAdItem({
    required this.id,
    required this.advertiserName,
    required this.headline,
    required this.description,
    required this.ctaText,
    required this.targetUrl,
    this.imageUrl,
    this.badge = 'Sponsored',
    this.adType = AdType.firebaseCustom,
  });

  factory SponsoredAdItem.fromMap(Map<String, dynamic> map, String id) {
    AdType type = AdType.firebaseCustom;
    final typeStr = map['adType'] as String?;
    if (typeStr == 'admobBanner') {
      type = AdType.admobBanner;
    } else if (typeStr == 'admobNative') {
      type = AdType.admobNative;
    }

    return SponsoredAdItem(
      id: id,
      advertiserName: map['advertiserName'] as String? ?? 'Sponsored Partner',
      headline: map['headline'] as String? ?? 'Special Offer',
      description: map['description'] as String? ?? '',
      ctaText: map['ctaText'] as String? ?? 'Learn More',
      targetUrl: map['targetUrl'] as String? ?? 'https://primebrowser.app',
      imageUrl: map['imageUrl'] as String?,
      badge: map['badge'] as String? ?? (type == AdType.firebaseCustom ? 'Sponsored' : 'Ad · AdMob'),
      adType: type,
    );
  }

  factory SponsoredAdItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SponsoredAdItem.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'advertiserName': advertiserName,
      'headline': headline,
      'description': description,
      'ctaText': ctaText,
      'targetUrl': targetUrl,
      'imageUrl': imageUrl,
      'badge': badge,
      'adType': adType.name,
    };
  }
}

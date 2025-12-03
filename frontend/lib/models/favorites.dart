import 'listing.dart';
import 'user.dart';

class FavoriteCollections {
  final List<Listing> listings;
  final List<User> sellers;

  const FavoriteCollections({
    this.listings = const [],
    this.sellers = const [],
  });

  factory FavoriteCollections.fromJson(Map<String, dynamic> json) {
    final listingJson = json['listings'] as List<dynamic>? ?? const [];
    final sellerJson = json['sellers'] as List<dynamic>? ?? const [];

    return FavoriteCollections(
      listings:
          listingJson.map((item) => Listing.fromJson(item as Map<String, dynamic>)).toList(),
      sellers: sellerJson.map((item) => User.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/favorites.dart';
import '../models/listing.dart';
import '../models/user.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../services/search_navigation_service.dart';
import '../widgets/listing_card.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/tunimode_app_bar.dart';
import '../widgets/auth_guard.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'listing_detail_screen.dart';
import 'profile_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<FavoriteCollections> _futureFavorites;
  final Map<int, Future<List<Review>>> _sellerReviewsCache = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureFavorites = _loadFavorites();
  }

  Future<FavoriteCollections> _loadFavorites() {
    return ApiService.fetchFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    SearchNavigationService.openSearchResults(
      context: context,
      query: query,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _futureFavorites = _loadFavorites();
    });
    await _futureFavorites;
  }

  Future<List<Review>> _loadSellerReviews(int sellerId) {
    return _sellerReviewsCache.putIfAbsent(
      sellerId,
      () => ApiService.fetchUserReviews(sellerId),
    );
  }

  double? _averageRating(List<Review> reviews) {
    if (reviews.isEmpty) return null;
    final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        if (rating >= starIndex) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (rating >= starIndex - 0.5) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        }
        return const Icon(Icons.star_border, color: Colors.amber, size: 16);
      }),
    );
  }

  Future<void> _removeListing(int listingId) async {
    final success = await ApiService.removeFavoriteListing(listingId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce retirée des favoris.')),
      );
      await _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de retirer cette annonce.')),
      );
    }
  }

  Future<void> _removeSeller(int sellerId) async {
    final success = await ApiService.removeFavoriteSeller(sellerId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendeur retiré des favoris.')),
      );
      await _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de retirer ce vendeur.')),
      );
    }
  }

  void _openListing(Listing listing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(listingId: listing.id),
      ),
    );
  }

  void _openSellerProfile(User seller) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: seller.id),
      ),
    );
  }

  Widget _buildListingTab(List<Listing> listings) {
  if (listings.isEmpty) {
    return const Center(
      child: Text('Aucune annonce dans vos favoris pour le moment.'),
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100, // comme HomeScreen
          ),
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

            // 🟢 IMPORTANT : on laisse le GridView SCROLLER
            shrinkWrap: false,
            physics: const AlwaysScrollableScrollPhysics(),

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 24,
              mainAxisSpacing: 32,
              childAspectRatio: 0.70,
            ),

            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return Stack(
                children: [
                  ListingCard(
                    listing: listing,
                    onTap: () => _openListing(listing),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        tooltip: 'Retirer des favoris',
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () => _removeListing(listing.id),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}


  Widget _buildSellerInfo(User seller) {
    final details = <Widget>[];

    if (seller.email.isNotEmpty) {
      details.add(_buildInfoRow(Icons.email_outlined, seller.email));
    }
    if (seller.phone != null && seller.phone!.isNotEmpty) {
      details.add(_buildInfoRow(Icons.phone_outlined, seller.phone!));
    }
    if (seller.address != null && seller.address!.isNotEmpty) {
      details.add(
        _buildInfoRow(Icons.place_outlined, seller.address!),
      );
    }

    return Column(children: details);
  }

  Widget _buildSellerTab(List<User> sellers) {
    if (sellers.isEmpty) {
      return const Center(
        child: Text('Aucun vendeur enregistré en favori.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sellers.length,
        itemBuilder: (context, index) {
          final seller = sellers[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              onTap: () => _openSellerProfile(seller),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage:
                              seller.avatarUrl != null ? NetworkImage(seller.avatarUrl!) : null,
                          child: seller.avatarUrl == null
                              ? Icon(Icons.person_outline, color: Colors.blueGrey.shade700)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                seller.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                seller.role == 'pro' ? 'Vendeur professionnel' : 'Vendeur particulier',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<List<Review>>(
                                future: _loadSellerReviews(seller.id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return const Text(
                                      'Note indisponible',
                                      style: TextStyle(color: Colors.black54),
                                    );
                                  }

                                  final reviews = snapshot.data ?? [];
                                  final average = _averageRating(reviews);

                                  if (average == null) {
                                    return const Text(
                                      'Aucun avis pour le moment',
                                      style: TextStyle(color: Colors.black54),
                                    );
                                  }

                                  return Row(
                                    children: [
                                      _buildStarRating(average),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${reviews.length} avis',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Retirer ce vendeur',
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => _removeSeller(seller.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSellerInfo(seller),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      builder: (context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: TuniModeAppBar(
            showSearchBar: true,
            searchController: _searchController,
            onSearch: _handleSearch,
            actions: const [
              AccountMenuButton(),
              SizedBox(width: 16),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Annonces'),
                Tab(text: 'Vendeurs'),
              ],
            ),
          ),
          body: FutureBuilder<FavoriteCollections>(
            future: _futureFavorites,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Text('Erreur lors du chargement : ${snapshot.error}'),
                );
              }

              final favorites = snapshot.data!;
              return TabBarView(
                children: [
                  _buildListingTab(favorites.listings),
                  _buildSellerTab(favorites.sellers),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

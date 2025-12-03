import 'package:flutter/material.dart';

import '../models/favorites.dart';
import '../models/listing.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<FavoriteCollections> _futureFavorites;

  @override
  void initState() {
    super.initState();
    _futureFavorites = _loadFavorites();
  }

  Future<FavoriteCollections> _loadFavorites() {
    return ApiService.fetchFavorites();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureFavorites = _loadFavorites();
    });
    await _futureFavorites;
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

  Widget _buildListingTab(List<Listing> listings) {
    if (listings.isEmpty) {
      return const Center(
        child: Text('Aucune annonce dans vos favoris pour le moment.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final listing = listings[index];
          return Stack(
            children: [
              ListingCard(
                listing: listing,
                onTap: () => _openListing(listing),
                onGenderTap: (_) {},
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 22),
                      const SizedBox(width: 8),
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
    if (ApiService.authToken == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes favoris')),
        body: const Center(
          child: Text('Connectez-vous pour enregistrer et consulter vos favoris.'),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes favoris'),
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
    );
  }
}

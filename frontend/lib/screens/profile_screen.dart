import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/listing.dart';
import '../models/review.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final int? _userId;
  late final Future<User?> _userFuture;
  late final Future<List<Review>> _reviewsFuture;
  late final Future<List<Listing>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId ?? ApiService.currentUser?.id;

    if (_userId != null) {
      _userFuture = ApiService.fetchUserProfile(_userId!);
      _reviewsFuture = ApiService.fetchUserReviews(_userId!);
      _listingsFuture = ApiService.fetchUserListings(_userId!);
    } else {
      _userFuture = Future.value(null);
      _reviewsFuture = Future.value([]);
      _listingsFuture = Future.value([]);
    }
  }

  double? _averageRating(List<Review> reviews) {
    if (reviews.isEmpty) return null;
    final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}';
  }

  int _columnCountForWidth(double width) {
    if (width >= 1400) return 5;
    if (width >= 1100) return 4;
    if (width >= 800) return 3;
    if (width >= 520) return 2;
    return 1;
  }

  void _openListing(Listing listing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(listingId: listing.id),
      ),
    );
  }

  Widget _buildRatingRow() {
    return FutureBuilder<List<Review>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasError) {
          return const Text('Note totale indisponible');
        }

        final reviews = snapshot.data ?? [];
        final average = _averageRating(reviews);

        if (average == null) {
          return const Text('Aucune note pour le moment');
        }

        return Row(
          children: [
            Icon(Icons.star, color: Colors.amber[700]),
            const SizedBox(width: 6),
            Text(
              '${average.toStringAsFixed(1)}/5',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Text('(${reviews.length} avis)'),
          ],
        );
      },
    );
  }

  Widget _buildHeader(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? const Icon(Icons.person, size: 36, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  _buildRatingRow(),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.address?.isNotEmpty == true
                              ? user.address!
                              : 'Adresse non renseignée',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewTile(Review review) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[700], size: 18),
                const SizedBox(width: 6),
                Text('${review.rating}/5',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text(
                  _formatDate(review.createdAt),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              review.reviewerName != null
                  ? 'Par ${review.reviewerName}'
                  : 'Avis reçu',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review.comment!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListingsTab() {
    return FutureBuilder<List<Listing>>(
      future: _listingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Impossible de charger les annonces de cet utilisateur.'),
          );
        }

        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Cet utilisateur n\'a pas encore publié d\'annonce.'),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = _columnCountForWidth(constraints.maxWidth);

            return MasonryGridView.count(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: listings.length,
              itemBuilder: (context, index) => ListingCard(
                listing: listings[index],
                onTap: () => _openListing(listings[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return FutureBuilder<List<Review>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Impossible de charger les avis pour le moment.'),
          );
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun avis trouvé pour cet utilisateur.'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: reviews.length,
          itemBuilder: (context, index) => _buildReviewTile(reviews[index]),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_userId == null) {
      return const Center(
        child: Text('Connectez-vous pour accéder à votre profil.'),
      );
    }

    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Impossible de charger ce profil pour le moment.'),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const Center(child: Text('Profil introuvable.'));
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _buildHeader(user),
              const SizedBox(height: 12),
              const TabBar(
                tabs: [
                  Tab(text: 'Annonces'),
                  Tab(text: 'Avis'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildListingsTab(),
                    _buildReviewsTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = widget.userId == null || widget.userId == ApiService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUser ? 'Mon profil' : 'Profil utilisateur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildContent(),
      ),
    );
  }
}

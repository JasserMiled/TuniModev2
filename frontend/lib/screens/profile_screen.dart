import 'package:flutter/material.dart';

import '../models/review.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    final user = ApiService.currentUser;
    _reviewsFuture =
        user != null ? ApiService.fetchUserReviews(user.id) : Future.value([]);
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

  Widget _buildReviewTile(Review review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.rate_review, color: Colors.amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[700], size: 18),
                    const SizedBox(width: 4),
                    Text('${review.rating}/5',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review.reviewerName != null
                      ? 'Par ${review.reviewerName}'
                      : 'Avis reçu',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(review.comment!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return FutureBuilder<List<Review>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Impossible de charger vos évaluations pour le moment.',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final reviews = snapshot.data ?? [];
        final average = _averageRating(reviews);

        if (reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Aucune évaluation reçue pour le moment.'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[700]),
                const SizedBox(width: 6),
                Text(
                  average != null
                      ? 'Note totale : ${average.toStringAsFixed(1)}/5'
                      : 'Note totale indisponible',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text('(${reviews.length} avis)'),
              ],
            ),
            const SizedBox(height: 12),
            ...reviews.map(_buildReviewTile),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Utilisateur',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(user?.email ?? 'Email non disponible'),
                const SizedBox(height: 8),
                if (user?.phone != null && user!.phone!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 18),
                        const SizedBox(width: 6),
                        Text(user.phone!),
                      ],
                    ),
                  ),
                if (user?.address != null && user!.address!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.home, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(user.address!)),
                      ],
                    ),
                  ),
                Chip(
                  label: Text(
                    user?.role == 'pro' ? 'Professionnel' : 'Acheteur',
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Évaluations reçues',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildReviewsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

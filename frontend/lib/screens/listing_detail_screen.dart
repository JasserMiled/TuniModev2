import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/api_service.dart';

class ListingDetailScreen extends StatefulWidget {
  final int listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late Future<Listing> _futureListing;

  @override
  void initState() {
    super.initState();
    _futureListing = ApiService.fetchListingDetail(widget.listingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail annonce'),
      ),
      body: FutureBuilder<Listing>(
        future: _futureListing,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('Erreur : ${snapshot.error}'),
            );
          }
          final listing = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, size: 80),
                ),
                const SizedBox(height: 16),
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${listing.price.toStringAsFixed(0)} TND',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (listing.city != null)
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16),
                      const SizedBox(width: 4),
                      Text(listing.city!),
                    ],
                  ),
                const SizedBox(height: 8),
                if (listing.gender != null)
                  Text('Genre : ${listing.gender!.substring(0, 1).toUpperCase()}${listing.gender!.substring(1)}'),
                if (listing.sizes.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: listing.sizes
                        .map((s) => Chip(label: Text('Taille $s')))
                        .toList(),
                  ),
                if (listing.colors.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: listing.colors
                        .map((c) => Chip(label: Text('Couleur $c')))
                        .toList(),
                  ),
                if (listing.condition != null)
                  Text('État : ${listing.condition}'),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(listing.description ?? 'Pas de description.'),
                const SizedBox(height: 16),
                if (listing.sellerName != null)
                  Text(
                    'Vendeur : ${listing.sellerName}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

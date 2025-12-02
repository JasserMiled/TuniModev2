import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/api_service.dart';
import '../widgets/order_form.dart';

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

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '${ApiService.baseUrl}$url';
  }

  String _formatGender(String gender) {
    if (gender.isEmpty) return gender;
    return '${gender[0].toUpperCase()}${gender.substring(1)}';
  }

  void _openOrderSheet(Listing listing) {
    if (ApiService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour commander.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: OrderForm(listing: listing),
      ),
    );
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
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: listing.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _resolveImageUrl(listing.imageUrls.first),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 60),
                          ),
                        )
                      : const Center(child: Icon(Icons.image, size: 80)),
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
                if (listing.deliveryAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: const [
                        Icon(Icons.local_shipping, size: 18, color: Colors.green),
                        SizedBox(width: 6),
                        Text(
                          'Livraison disponible',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                if (listing.gender != null && listing.gender!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.wc, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Genre : ${_formatGender(listing.gender!)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 18),
                    const SizedBox(width: 6),
                    Text('Stock disponible : ${listing.stock}'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openOrderSheet(listing),
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('Acheter'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

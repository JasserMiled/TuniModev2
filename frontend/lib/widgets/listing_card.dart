import 'package:flutter/material.dart';
import '../models/listing.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.imageUrls.isNotEmpty ? listing.imageUrls.first : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: Icon(Icons.image_outlined, size: 36),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${listing.price.toStringAsFixed(0)} TND',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (listing.gender != null)
                          _buildTag(listing.gender!),
                        if (listing.categoryName != null)
                          _buildTag(listing.categoryName!),
                        if (listing.sizes.isNotEmpty)
                          _buildTag('Tailles: ${listing.sizes.join(', ')}'),
                        if (listing.colors.isNotEmpty)
                          _buildTag('Couleurs: ${listing.colors.join(', ')}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (listing.gender != null ||
                        listing.sizes.isNotEmpty ||
                        listing.colors.isNotEmpty)
                      Text(
                        [
                          if (listing.gender != null)
                            listing.gender!.substring(0, 1).toUpperCase() +
                                listing.gender!.substring(1),
                          if (listing.sizes.isNotEmpty)
                            'Tailles: ${listing.sizes.join(', ')}',
                          if (listing.colors.isNotEmpty)
                            'Couleurs: ${listing.colors.join(', ')}'
                        ].join(' • '),
                        style: const TextStyle(fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (listing.city != null)
                          Row(
                            children: [
                              const Icon(Icons.place, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                listing.city!,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(width: 8),
                        if (listing.sellerName != null)
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                listing.sellerName!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

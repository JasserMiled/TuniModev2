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
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image, size: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${listing.price.toStringAsFixed(0)} TND',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
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
                              const Icon(Icons.place, size: 14),
                              const SizedBox(width: 4),
                              Text(listing.city!),
                            ],
                          ),
                        const SizedBox(width: 8),
                        if (listing.sellerName != null)
                          Text(
                            'Vendeur: ${listing.sellerName!}',
                            style: const TextStyle(fontSize: 12),
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
}

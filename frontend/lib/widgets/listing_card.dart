import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/api_service.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;
  final ValueChanged<String>? onGenderTap;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.onGenderTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        listing.imageUrls.isNotEmpty ? _resolveImageUrl(listing.imageUrls.first) : null;

return SizedBox(
  height: 310, // hauteur EXACTE comme Vinted desktop
  child: Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 1,
    clipBehavior: Clip.hardEdge,
    child: InkWell(
      onTap: onTap,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // IMAGE CARRÉE VINTED
            AspectRatio(
              aspectRatio: 1,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    )
                  : const _PlaceholderImage(),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // TITRE
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // DETAILS
                  if (_buildDetails().isNotEmpty)
                    Text(
                      _buildDetails(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 6),

                  // PRIX ALIGNÉ À DROITE
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        '${listing.price.toStringAsFixed(0)} TND',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF0B6EFE),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
	  ),
    );
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http')) return url;

    // FIX : éviter les doubles slash + bon port
    final normalized = url.startsWith('/') ? url.substring(1) : url;
    return '${ApiService.baseUrl}/$normalized';
  }

  String _buildDetails() {
    final l = <String>[];
    if (listing.sizes.isNotEmpty) l.add(listing.sizes.join(', '));
    if (listing.condition != null) l.add(listing.condition!);
    return l.join(' • ');
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F2),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 32, color: Colors.grey),
    );
  }
}

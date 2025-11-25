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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const _PlaceholderImage(),
                          )
                        : const _PlaceholderImage(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                listing.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (_buildDetailsLine().isNotEmpty)
                Text(
                  _buildDetailsLine(),
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (listing.gender != null)
                    _buildTag(
                      _formatLabel(listing.gender!),
                      onTap: () => onGenderTap?.call(listing.gender!),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${listing.price.toStringAsFixed(0)} TND',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final normalized = url.startsWith('/') ? url : '/$url';
    return '${ApiService.baseUrl}$normalized';
  }

  String _buildDetailsLine() {
    final details = <String>[];

    if (listing.sizes.isNotEmpty) {
      details.add(listing.sizes.join(', '));
    }
    if (listing.condition != null && listing.condition!.isNotEmpty) {
      details.add(listing.condition!);
    }

    return details.join(' - ');
  }

  Widget _buildTag(String label, {VoidCallback? onTap}) {
    final tag = Container(
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

    if (onTap == null) return tag;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: tag,
    );
  }

  String _formatLabel(String label) {
    if (label.isEmpty) return label;
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 38),
    );
  }
}

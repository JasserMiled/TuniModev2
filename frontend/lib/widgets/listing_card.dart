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
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.2,
      shadowColor: Colors.black.withOpacity(0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
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
              const SizedBox(height: 6),
              Text(
                listing.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_buildDetailsLine().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _buildDetailsLine(),
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (listing.gender != null)
                    _buildTag(
                      _formatLabel(listing.gender!),
                      onTap: () => onGenderTap?.call(listing.gender!),
                    ),
                  if (listing.deliveryAvailable)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _buildTag(
                        'Livraison',
                        leading: const Icon(
                          Icons.local_shipping,
                          size: 14,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
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
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
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

  Widget _buildTag(String label, {VoidCallback? onTap, Widget? leading}) {
    final tag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

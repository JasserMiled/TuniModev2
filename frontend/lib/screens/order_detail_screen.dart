import 'package:flutter/material.dart';

import '../models/order.dart';
import 'listing_detail_screen.dart';
import 'profile_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmée';
      case 'shipped':
        return 'Expédiée';
      case 'reception_refused':
        return 'Refus de réception';
      case 'ready_for_pickup':
        return 'À retirer';
      case 'picked_up':
        return 'Retirée';
      case 'received':
        return 'Reçu';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return 'En attente';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blueAccent;
      case 'shipped':
        return Colors.deepPurple;
      case 'reception_refused':
        return Colors.redAccent;
      case 'ready_for_pickup':
        return Colors.orange;
      case 'picked_up':
        return Colors.teal;
      case 'received':
        return Colors.lightGreen;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(d.day)}/${twoDigits(d.month)}/${d.year} à ${twoDigits(d.hour)}h${twoDigits(d.minute)}';
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails de la commande')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.listingTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Commande #${order.id}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          _buildTile(
            icon: Icons.shopping_bag,
            title: 'Statut : ${_statusLabel(order.status)}',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(order.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusLabel(order.status),
                style: TextStyle(
                  color: _statusColor(order.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          _buildTile(
            icon: Icons.calendar_today,
            title: 'Créée le ${_formatDate(order.createdAt)}',
          ),
          _buildTile(
            icon: Icons.format_list_numbered,
            title: 'Quantité : ${order.quantity}',
          ),
          _buildTile(
            icon: Icons.payments,
            title: 'Total : ${order.totalAmount.toStringAsFixed(2)} TND',
          ),
          _buildTile(
            icon: Icons.local_shipping,
            title:
                "Mode de réception : ${order.receptionMode == 'livraison' ? 'Livraison' : 'Retrait sur place'}",
          ),
          _buildTile(
            icon: Icons.storefront_outlined,
            title: 'Voir l\'annonce utilisée',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ListingDetailScreen(listingId: order.listingId),
              ),
            ),
          ),
          if (order.sellerId != null)
            _buildTile(
              icon: Icons.badge_outlined,
              title: 'Profil du vendeur',
              subtitle: order.sellerName,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: order.sellerId!),
                ),
              ),
            ),
          if (order.buyerId != null)
            _buildTile(
              icon: Icons.person_outline,
              title: 'Profil de l\'acheteur',
              subtitle: order.buyerName,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: order.buyerId!),
                ),
              ),
            ),
          if (order.color != null && order.color!.isNotEmpty)
            _buildTile(
              icon: Icons.palette,
              title: 'Couleur : ${order.color}',
            ),
          if (order.size != null && order.size!.isNotEmpty)
            _buildTile(
              icon: Icons.straighten,
              title: 'Taille : ${order.size}',
            ),
          if (order.receptionMode == 'livraison' &&
              order.shippingAddress != null &&
              order.shippingAddress!.isNotEmpty)
            _buildTile(
              icon: Icons.home_outlined,
              title: 'Adresse de livraison',
              subtitle: order.shippingAddress,
            ),
          if (order.phone != null && order.phone!.isNotEmpty)
            _buildTile(
              icon: Icons.phone,
              title: 'Téléphone',
              subtitle: order.phone,
            ),
          if (order.buyerNote != null && order.buyerNote!.isNotEmpty)
            _buildTile(
              icon: Icons.note_alt_outlined,
              title: 'Note',
              subtitle: order.buyerNote,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

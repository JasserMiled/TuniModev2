import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';
import '../widgets/account_menu_button.dart';
import '../services/search_navigation_service.dart';
import 'listing_detail_screen.dart';
import 'profile_screen.dart';
import '../widgets/tunimode_app_bar.dart';
import '../widgets/tunimode_drawer.dart';
import '../widgets/quick_filters_launcher.dart';
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _order;
  bool _isUpdatingStatus = false;
  bool _isConfirmingReception = false;
  bool _isCancelling = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    SearchNavigationService.openSearchResults(
      context: context,
      query: query,
    );
  }

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

  bool get _isSellerForOrder {
    final user = ApiService.currentUser;
    return user != null && _order.sellerId == user.id;
  }

  bool get _isBuyerForOrder {
    final user = ApiService.currentUser;
    return user != null && _order.buyerId == user.id;
  }

  Future<void> _updateSellerStatus(String status) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final updatedOrder = await ApiService.updateSellerOrderStatus(
        orderId: _order.id,
        status: status,
      );

      if (mounted) {
        setState(() {
          _order = updatedOrder;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut mis à jour en ${_statusLabel(status)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Future<void> _confirmReception() async {
    setState(() {
      _isConfirmingReception = true;
    });

    try {
      final updatedOrder = await ApiService.confirmOrderReception(_order.id);
      if (mounted) {
        setState(() {
          _order = updatedOrder;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Réception confirmée, en attente de finalisation par le vendeur.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirmingReception = false;
        });
      }
    }
  }

  Future<void> _refuseReception() async {
    setState(() {
      _isConfirmingReception = true;
    });

    try {
      final updatedOrder = await ApiService.refuseOrderReception(_order.id);
      if (mounted) {
        setState(() {
          _order = updatedOrder;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réception refusée.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirmingReception = false;
        });
      }
    }
  }

  Future<void> _cancelOrder() async {
    setState(() {
      _isCancelling = true;
    });

    try {
      final updatedOrder = await ApiService.cancelOrder(_order.id);
      if (mounted) {
        setState(() {
          _order = updatedOrder;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande annulée.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  List<Widget> _buildSellerActions() {
    final actions = <Widget>[];

    final bool canCancel = _order.status == 'pending' ||
        _order.status == 'confirmed' ||
        _order.status == 'shipped' ||
        _order.status == 'ready_for_pickup';

    if (_order.status == 'pending') {
      actions.add(
        ElevatedButton(
          onPressed: _isUpdatingStatus ? null : () => _updateSellerStatus('confirmed'),
          child: Text(_isUpdatingStatus ? 'Mise à jour...' : 'Confirmer la commande'),
        ),
      );
    }

    if (_order.status == 'confirmed' && _order.receptionMode == 'livraison') {
      actions.add(
        ElevatedButton(
          onPressed: _isUpdatingStatus ? null : () => _updateSellerStatus('shipped'),
          child: Text(_isUpdatingStatus ? 'Mise à jour...' : 'Marquer comme expédiée'),
        ),
      );
    }

    if (_order.status == 'confirmed' && _order.receptionMode == 'retrait') {
      actions.add(
        ElevatedButton(
          onPressed: _isUpdatingStatus
              ? null
              : () => _updateSellerStatus('ready_for_pickup'),
          child: Text(_isUpdatingStatus ? 'Mise à jour...' : 'Commande prête – à retirer'),
        ),
      );
    }

    if (_order.status == 'ready_for_pickup' && _order.receptionMode == 'retrait') {
      actions.add(
        ElevatedButton(
          onPressed: _isUpdatingStatus ? null : () => _updateSellerStatus('picked_up'),
          child: Text(_isUpdatingStatus ? 'Mise à jour...' : 'Marquer comme retirée'),
        ),
      );
    }

    if (_order.status == 'shipped') {
      actions.add(
        OutlinedButton(
          onPressed:
              _isUpdatingStatus ? null : () => _updateSellerStatus('reception_refused'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
          ),
          child: Text(_isUpdatingStatus ? 'Mise à jour...' : 'Refus de réception'),
        ),
      );
    }

    if (_order.status == 'received' || _order.status == 'reception_refused') {
      actions.add(
        ElevatedButton(
          onPressed: _isUpdatingStatus ? null : () => _updateSellerStatus('completed'),
          child: Text(_isUpdatingStatus ? 'Mise à jour...' : 'Marquer comme terminée'),
        ),
      );
    }

    if (canCancel) {
      actions.add(
        OutlinedButton(
          onPressed: _isUpdatingStatus || _isCancelling ? null : _cancelOrder,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
          ),
          child: Text(
            _isCancelling ? 'Annulation...' : 'Annuler la commande',
          ),
        ),
      );
    }

    return actions;
  }

  List<Widget> _buildBuyerActions() {
    final actions = <Widget>[];

    final bool canConfirmReception =
        _order.status == 'shipped' || _order.status == 'picked_up';
    final bool canRefuseReception = _order.status == 'shipped';
    final bool canCancel = _order.status == 'pending';

    if (canConfirmReception) {
      actions.add(
        ElevatedButton(
          onPressed: _isConfirmingReception ? null : _confirmReception,
          child: Text(
            _isConfirmingReception ? 'Validation...' : 'Confirmer la réception',
          ),
        ),
      );
    }

    if (canRefuseReception) {
      actions.add(
        OutlinedButton(
          onPressed: _isConfirmingReception ? null : _refuseReception,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
          ),
          child: Text(
            _isConfirmingReception ? 'Traitement...' : 'Refuser la réception',
          ),
        ),
      );
    }

    if (canCancel) {
      actions.add(
        OutlinedButton(
          onPressed: _isCancelling ? null : _cancelOrder,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
          ),
          child: Text(
            _isCancelling ? 'Annulation...' : 'Annuler la commande',
          ),
        ),
      );
    }

    return actions;
  }

  Widget _buildActionsSection({required String title, required List<Widget> actions}) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const TuniModeDrawer(),
appBar: TuniModeAppBar(
  showSearchBar: true,
  searchController: _searchController,
  onSearch: _handleSearch,
  onQuickFilters: () => openQuickFiltersAndNavigate(
    context: context,
    searchQuery: _searchController.text,
    primaryColor: const Color(0xFF0B6EFE),
  ),
  actions: const [
    AccountMenuButton(),
    SizedBox(width: 8),
  ],
),

      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _order.listingTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Commande #${_order.id}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          _buildTile(
            icon: Icons.shopping_bag,
            title: 'Statut : ${_statusLabel(_order.status)}',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(_order.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusLabel(_order.status),
                style: TextStyle(
                  color: _statusColor(_order.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
            _buildTile(
              icon: Icons.calendar_today,
              title: 'Créée le ${_formatDate(_order.createdAt)}',
            ),
          _buildTile(
            icon: Icons.format_list_numbered,
            title: 'Quantité : ${_order.quantity}',
          ),
          _buildTile(
            icon: Icons.payments,
            title: 'Total : ${_order.totalAmount.toStringAsFixed(2)} TND',
          ),
          _buildTile(
            icon: Icons.local_shipping,
            title:
                "Mode de réception : ${_order.receptionMode == 'livraison' ? 'Livraison' : 'Retrait sur place'}",
          ),
          _buildTile(
            icon: Icons.storefront_outlined,
            title: 'Voir l\'annonce utilisée',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ListingDetailScreen(listingId: _order.listingId),
              ),
            ),
          ),
          if (_order.sellerId != null)
            _buildTile(
              icon: Icons.badge_outlined,
              title: 'Profil du vendeur',
              subtitle: _order.sellerName,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      ProfileScreen(userId: _order.sellerId!),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              ),
            ),
          if (_order.buyerId != null)
            _buildTile(
              icon: Icons.person_outline,
              title: 'Profil de l\'acheteur',
              subtitle: _order.buyerName,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      ProfileScreen(userId: _order.buyerId!),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              ),
            ),
          if (_order.color != null && _order.color!.isNotEmpty)
            _buildTile(
              icon: Icons.palette,
              title: 'Couleur : ${_order.color}',
            ),
          if (_order.size != null && _order.size!.isNotEmpty)
            _buildTile(
              icon: Icons.straighten,
              title: 'Taille : ${_order.size}',
            ),
          if (_order.receptionMode == 'livraison' &&
              _order.shippingAddress != null &&
              _order.shippingAddress!.isNotEmpty)
            _buildTile(
              icon: Icons.home_outlined,
              title: 'Adresse de livraison',
              subtitle: _order.shippingAddress,
            ),
          if (_order.phone != null && _order.phone!.isNotEmpty)
            _buildTile(
              icon: Icons.phone,
              title: 'Téléphone',
              subtitle: _order.phone,
            ),
          if (_order.buyerNote != null && _order.buyerNote!.isNotEmpty)
            _buildTile(
              icon: Icons.note_alt_outlined,
              title: 'Note',
              subtitle: _order.buyerNote,
            ),
          if (_isSellerForOrder)
            _buildActionsSection(
              title: 'Actions vendeur',
              actions: _buildSellerActions(),
            ),
          if (_isBuyerForOrder)
            _buildActionsSection(
              title: 'Actions acheteur',
              actions: _buildBuyerActions(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

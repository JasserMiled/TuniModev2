import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';
import '../widgets/review_dialog.dart';
import 'order_detail_screen.dart';

class OrderRequestsScreen extends StatefulWidget {
  const OrderRequestsScreen({super.key});

  @override
  State<OrderRequestsScreen> createState() => _OrderRequestsScreenState();
}

class _OrderRequestsScreenState extends State<OrderRequestsScreen> {
  late Future<List<Order>> _sellerOrdersFuture;
  late Future<List<Order>> _buyerOrdersFuture;
  int? _updatingOrderId;
  int? _reviewingOrderId;
  int? _confirmingOrderId;
  final Set<int> _reviewedOrders = {};

  @override
  void initState() {
    super.initState();
    _sellerOrdersFuture = _fetchSellerOrders();
    _buyerOrdersFuture = _fetchBuyerOrders();
  }

  Future<List<Order>> _fetchSellerOrders() {
    return ApiService.fetchSellerOrders();
  }

  Future<List<Order>> _fetchBuyerOrders() {
    return ApiService.fetchBuyerOrders();
  }

  Future<void> _refreshSeller() async {
    final future = _fetchSellerOrders();
    setState(() {
      _sellerOrdersFuture = future;
    });
    await future;
  }

  Future<void> _refreshBuyer() async {
    final future = _fetchBuyerOrders();
    setState(() {
      _buyerOrdersFuture = future;
    });
    await future;
  }

  Future<void> _startSellerReviewFlow(Order order) async {
    final user = ApiService.currentUser;
    if (user == null) return;

    setState(() {
      _reviewingOrderId = order.id;
    });

    try {
      final existingReviews = await ApiService.fetchOrderReviews(order.id);
      final hasAlreadyReviewed = existingReviews
              .any((review) => review.reviewerId == user.id) ||
          _reviewedOrders.contains(order.id);

      if (hasAlreadyReviewed) {
        setState(() {
          _reviewedOrders.add(order.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous avez déjà évalué cette commande.'),
            ),
          );
        }
        return;
      }

      final result = await showDialog<ReviewFormResult>(
        context: context,
        builder: (context) => const ReviewDialog(
          title: 'Noter l\'acheteur',
          subtitle:
              'Attribuez une note et un commentaire à l\'acheteur pour cette commande.',
        ),
      );

      if (result != null) {
        await ApiService.submitReview(
          orderId: order.id,
          rating: result.rating,
          comment: result.comment,
        );

        setState(() {
          _reviewedOrders.add(order.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avis enregistré, merci !')),
          );
        }
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
          _reviewingOrderId = null;
        });
      }
    }
  }

  Future<void> _startBuyerReviewFlow(Order order) async {
    final user = ApiService.currentUser;
    if (user == null) return;

    setState(() {
      _reviewingOrderId = order.id;
    });

    try {
      final existingReviews = await ApiService.fetchOrderReviews(order.id);
      final hasAlreadyReviewed = existingReviews
              .any((review) => review.reviewerId == user.id) ||
          _reviewedOrders.contains(order.id);

      if (hasAlreadyReviewed) {
        setState(() {
          _reviewedOrders.add(order.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous avez déjà évalué cette commande.'),
            ),
          );
        }
        return;
      }

      final result = await showDialog<ReviewFormResult>(
        context: context,
        builder: (context) => const ReviewDialog(
          title: 'Noter le vendeur',
          subtitle:
              'Attribuez une note et un commentaire au vendeur pour cette commande.',
        ),
      );

      if (result != null) {
        await ApiService.submitReview(
          orderId: order.id,
          rating: result.rating,
          comment: result.comment,
        );

        setState(() {
          _reviewedOrders.add(order.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avis enregistré, merci !')),
          );
        }
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
          _reviewingOrderId = null;
        });
      }
    }
  }

  Future<void> _updateStatus(Order order, String status) async {
    setState(() {
      _updatingOrderId = order.id;
    });

    try {
      await ApiService.updateSellerOrderStatus(orderId: order.id, status: status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut mis à jour en ${_statusLabel(status)}')),
        );
      }
      await _refreshSeller();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingOrderId = null;
        });
      }
    }
  }

  Future<void> _confirmReception(Order order) async {
    setState(() {
      _confirmingOrderId = order.id;
    });

    try {
      await ApiService.confirmOrderReception(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réception confirmée, commande terminée.')),
        );
      }
      await _refreshBuyer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _confirmingOrderId = null;
        });
      }
    }
  }

  List<Widget> _buildSellerActions(Order order) {
    final actions = <Widget>[];

    final bool isUpdating = _updatingOrderId == order.id;

    if (order.status == 'pending') {
      actions.add(
        ElevatedButton(
          onPressed: isUpdating ? null : () => _updateStatus(order, 'confirmed'),
          child: Text(isUpdating ? 'Mise à jour...' : 'Confirmer la commande'),
        ),
      );
    }

    if (order.status == 'confirmed' && order.receptionMode == 'livraison') {
      actions.add(
        ElevatedButton(
          onPressed: isUpdating ? null : () => _updateStatus(order, 'shipped'),
          child: Text(isUpdating ? 'Mise à jour...' : 'Marquer comme expédiée'),
        ),
      );
    }

    if (order.status == 'confirmed' && order.receptionMode == 'retrait') {
      actions.add(
        ElevatedButton(
          onPressed:
              isUpdating ? null : () => _updateStatus(order, 'ready_for_pickup'),
          child: Text(isUpdating ? 'Mise à jour...' : 'Commande prête – à retirer'),
        ),
      );
    }

    if (order.status == 'ready_for_pickup' && order.receptionMode == 'retrait') {
      actions.add(
        ElevatedButton(
          onPressed: isUpdating ? null : () => _updateStatus(order, 'picked_up'),
          child: Text(isUpdating ? 'Mise à jour...' : 'Marquer comme retirée'),
        ),
      );
    }

    return actions;
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(d.day)}/${twoDigits(d.month)}/${d.year} à ${twoDigits(d.hour)}h${twoDigits(d.minute)}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmée';
      case 'shipped':
        return 'Expédiée';
      case 'ready_for_pickup':
        return 'À retirer';
      case 'picked_up':
        return 'Retirée';
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
      case 'ready_for_pickup':
        return Colors.orange;
      case 'picked_up':
        return Colors.teal;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  Widget _buildSellerOrderCard(Order order) {
    final subtitleLines = <String>[
      'Statut : ${_statusLabel(order.status)}',
      "Mode : ${order.receptionMode == 'livraison' ? 'Livraison' : 'Retrait sur place'}",
      'Quantité : ${order.quantity}',
    ];

    if (order.color != null && order.color!.isNotEmpty) {
      subtitleLines.add('Couleur : ${order.color}');
    }
    if (order.size != null && order.size!.isNotEmpty) {
      subtitleLines.add('Taille : ${order.size}');
    }

    final actions = _buildSellerActions(order);

    final bool canLeaveReview = order.status == 'completed';
    final bool hasReviewed = _reviewedOrders.contains(order.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(order.status).withOpacity(0.15),
          child: Icon(
            Icons.receipt_long,
            color: _statusColor(order.status),
          ),
        ),
        title: Text(
          order.listingTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitleLines.join(' • ')),
              const SizedBox(height: 4),
              Text('Reçue le ${_formatDate(order.createdAt)}'),
              if (order.receptionMode == 'livraison' && order.shippingAddress != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Adresse : ${order.shippingAddress}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (order.phone != null && order.phone!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Téléphone : ${order.phone}'),
                ),
              if (order.buyerNote != null && order.buyerNote!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Note de l\'acheteur : ${order.buyerNote}'),
                ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              ],
              if (canLeaveReview) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _reviewingOrderId == order.id || hasReviewed
                      ? null
                      : () => _startSellerReviewFlow(order),
                  icon: _reviewingOrderId == order.id
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.reviews_outlined),
                  label: Text(
                    hasReviewed
                        ? 'Avis envoyé'
                        : 'Évaluer cette commande',
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${order.totalAmount.toStringAsFixed(2)} TND',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(order.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusLabel(order.status),
                style: TextStyle(
                  color: _statusColor(order.status),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBuyerOrderCard(Order order) {
    final subtitleLines = <String>[
      'Statut : ${_statusLabel(order.status)}',
      "Mode : ${order.receptionMode == 'livraison' ? 'Livraison' : 'Retrait sur place'}",
      'Quantité : ${order.quantity}',
    ];

    final bool canConfirmReception =
        order.status == 'shipped' || order.status == 'picked_up';

    if (order.color != null && order.color!.isNotEmpty) {
      subtitleLines.add('Couleur : ${order.color}');
    }
    if (order.size != null && order.size!.isNotEmpty) {
      subtitleLines.add('Taille : ${order.size}');
    }

    final bool canLeaveReview = order.status == 'completed';
    final bool hasReviewed = _reviewedOrders.contains(order.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(order.status).withOpacity(0.15),
          child: Icon(
            Icons.shopping_bag,
            color: _statusColor(order.status),
          ),
        ),
        title: Text(
          order.listingTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitleLines.join(' • ')),
              const SizedBox(height: 4),
              Text('Passée le ${_formatDate(order.createdAt)}'),
              if (order.receptionMode == 'livraison' && order.shippingAddress != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Adresse de livraison : ${order.shippingAddress}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (order.phone != null && order.phone!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Téléphone : ${order.phone}'),
                ),
              if (order.buyerNote != null && order.buyerNote!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Votre note : ${order.buyerNote}'),
                ),
              if (canConfirmReception || canLeaveReview) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canConfirmReception)
                      ElevatedButton(
                        onPressed: _confirmingOrderId == order.id
                            ? null
                            : () => _confirmReception(order),
                        child: _confirmingOrderId == order.id
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Confirmer la réception'),
                      ),
                    if (canLeaveReview)
                      OutlinedButton.icon(
                        onPressed: _reviewingOrderId == order.id || hasReviewed
                            ? null
                            : () => _startBuyerReviewFlow(order),
                        icon: _reviewingOrderId == order.id
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.reviews_outlined),
                        label: Text(
                          hasReviewed ? 'Avis envoyé' : 'Évaluer cette commande',
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${order.totalAmount.toStringAsFixed(2)} TND',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(order.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusLabel(order.status),
                style: TextStyle(
                  color: _statusColor(order.status),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSellerBody() {
    return FutureBuilder<List<Order>>(
      future: _sellerOrdersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Une erreur est survenue lors du chargement de vos commandes de vente.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refreshSeller,
                    child: const Text('Réessayer'),
                  )
                ],
              ),
            ),
          );
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Vous n\'avez pas encore reçu de commandes. Elles apparaîtront ici lorsque des acheteurs passeront commande.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshSeller,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: orders.length,
            itemBuilder: (context, index) => _buildSellerOrderCard(orders[index]),
          ),
        );
      },
    );
  }

  Widget _buildBuyerBody() {
    return FutureBuilder<List<Order>>(
      future: _buyerOrdersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Une erreur est survenue lors du chargement de vos commandes d\'achat.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refreshBuyer,
                    child: const Text('Réessayer'),
                  )
                ],
              ),
            ),
          );
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Vous n\'avez pas encore de commandes d\'achat.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshBuyer,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: orders.length,
            itemBuilder: (context, index) => _buildBuyerOrderCard(orders[index]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes commandes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Vente'),
              Tab(text: 'Achat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSellerBody(),
            _buildBuyerBody(),
          ],
        ),
      ),
    );
  }
}

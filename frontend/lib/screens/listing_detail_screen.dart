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

  bool _isOwner(Listing listing) {
    final currentId = ApiService.currentUser?.id;
    return currentId != null && currentId == listing.userId;
  }

  Future<void> _refreshListing() async {
    final next = ApiService.fetchListingDetail(widget.listingId);
    setState(() {
      _futureListing = next;
    });
    await next;
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

  Future<void> _confirmDelete(Listing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette annonce ?'),
        content: const Text(
          'Cette action est définitive et retirera votre annonce des acheteurs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ApiService.deleteListing(listing.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce supprimée.')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suppression impossible.')),
      );
    }
  }

  void _openEditDialog(Listing listing) {
    final priceController =
        TextEditingController(text: listing.price.toStringAsFixed(0));
    final sizesController = TextEditingController(text: listing.sizes.join(', '));
    final colorsController =
        TextEditingController(text: listing.colors.join(', '));
    final stockController = TextEditingController(text: listing.stock.toString());
    bool deliveryAvailable = listing.deliveryAvailable;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mettre à jour votre annonce',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix (TND)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Indiquez un prix valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock disponible',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Stock invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: sizesController,
                      decoration: const InputDecoration(
                        labelText: 'Tailles disponibles (séparées par des virgules)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: colorsController,
                      decoration: const InputDecoration(
                        labelText: 'Couleurs disponibles (séparées par des virgules)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Livraison disponible'),
                      value: deliveryAvailable,
                      onChanged: (value) {
                        setModalState(() {
                          deliveryAvailable = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final success = await ApiService.updateListing(
                            id: listing.id,
                            price: double.tryParse(priceController.text),
                            stock: int.tryParse(stockController.text),
                            sizes: sizesController.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList(),
                            colors: colorsController.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList(),
                            deliveryAvailable: deliveryAvailable,
                          );

                          if (!mounted) return;

                          Navigator.of(context).pop();

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Annonce mise à jour.')),
                            );
                            await _refreshListing();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('La mise à jour a échoué.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                if (_isOwner(listing)) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _openEditDialog(listing),
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(listing),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                        ),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Supprimer'),
                      ),
                    ],
                  ),
                ],
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

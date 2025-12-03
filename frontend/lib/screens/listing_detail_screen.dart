import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/api_service.dart';
import '../widgets/order_form.dart';
import 'profile_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final int listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late Future<Listing> _futureListing;
  bool _isListingFavorite = false;
  bool _isSellerFavorite = false;
  bool _isLoadingFavorites = false;
  bool _isTogglingListing = false;
  bool _isTogglingSeller = false;
  int? _syncedFavoriteForListingId;

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

  void _openImagePreview(String imageUrl, Listing listing) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: InteractiveViewer(
                    child: Image.network(
                      _resolveImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 80),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (listing.condition != null)
                          Chip(
                            avatar: const Icon(Icons.checkroom, size: 18),
                            label: Text('État: ${listing.condition}'),
                          ),
                        ...listing.sizes
                            .map((size) => Chip(label: Text('Taille $size'))),
                        ...listing.colors
                            .map((color) => Chip(label: Text('Couleur $color'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 18),
                        const SizedBox(width: 6),
                        Text(listing.city ?? 'Localisation non renseignée'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 18,
                          color: listing.deliveryAvailable ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          listing.deliveryAvailable
                              ? 'Livraison disponible'
                              : 'Livraison non disponible',
                          style: const TextStyle(fontWeight: FontWeight.w500),
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

  void _openSellerProfile(Listing listing) {
    if (listing.userId <= 0) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: listing.userId)),
    );
  }

  bool get _isAuthenticated => ApiService.currentUser != null;

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

  void _ensureFavoriteState(Listing listing) {
    if (!_isAuthenticated || _isLoadingFavorites) return;
    if (_syncedFavoriteForListingId == listing.id) return;

    _loadFavoriteState(listing);
  }

  Future<void> _loadFavoriteState(Listing listing) async {
    setState(() {
      _isLoadingFavorites = true;
    });

    try {
      final favorites = await ApiService.fetchFavorites();
      if (!mounted) return;
      setState(() {
        _syncedFavoriteForListingId = listing.id;
        _isListingFavorite =
            favorites.listings.any((favorite) => favorite.id == listing.id);
        _isSellerFavorite =
            favorites.sellers.any((seller) => seller.id == listing.userId);
      });
    } catch (_) {
      // Ignore and keep defaults when favorite state cannot be loaded
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavorites = false;
        });
      }
    }
  }

  Future<void> _toggleListingFavorite(Listing listing) async {
    if (!_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour ajouter des favoris.')),
      );
      return;
    }

    final targetState = !_isListingFavorite;
    setState(() {
      _isListingFavorite = targetState;
      _isTogglingListing = true;
    });

    final success = targetState
        ? await ApiService.addFavoriteListing(listing.id)
        : await ApiService.removeFavoriteListing(listing.id);

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isListingFavorite = !targetState;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de mettre à jour vos favoris.')),
      );
    }

    setState(() {
      _isTogglingListing = false;
    });
  }

  Future<void> _toggleSellerFavorite(Listing listing) async {
    if (!_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour ajouter des favoris.')),
      );
      return;
    }

    final targetState = !_isSellerFavorite;
    setState(() {
      _isSellerFavorite = targetState;
      _isTogglingSeller = true;
    });

    final success = targetState
        ? await ApiService.addFavoriteSeller(listing.userId)
        : await ApiService.removeFavoriteSeller(listing.userId);

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isSellerFavorite = !targetState;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de mettre à jour vos favoris.')),
      );
    }

    setState(() {
      _isTogglingSeller = false;
    });
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
    return FutureBuilder<Listing>(
      future: _futureListing,
      builder: (context, snapshot) {
        final listing = snapshot.data;
        if (listing != null) {
          _ensureFavoriteState(listing);
        }

        Widget body;
        if (snapshot.connectionState == ConnectionState.waiting) {
          body = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          body = Center(
            child: Text('Erreur : ${snapshot.error}'),
          );
        } else {
          final loadedListing = snapshot.data!;
          body = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loadedListing.imageUrls.isNotEmpty)
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _openImagePreview(loadedListing.imageUrls.first, loadedListing),
                        child: Container(
                          height: 240,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _resolveImageUrl(loadedListing.imageUrls.first),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 60),
                            ),
                          ),
                        ),
                      ),
                      if (loadedListing.imageUrls.length > 1) ...[
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: loadedListing.imageUrls.length - 1,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            final imageUrl = loadedListing.imageUrls[index + 1];
                            return GestureDetector(
                              onTap: () => _openImagePreview(imageUrl, loadedListing),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _resolveImageUrl(imageUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 40),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  )
                else
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Icon(Icons.image, size: 80)),
                  ),
                const SizedBox(height: 16),
                Text(
                  loadedListing.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isOwner(loadedListing)) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _openEditDialog(loadedListing),
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(loadedListing),
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
                  '${loadedListing.price.toStringAsFixed(0)} TND',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (loadedListing.city != null)
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16),
                      const SizedBox(width: 4),
                      Text(loadedListing.city!),
                    ],
                  ),
                if (loadedListing.deliveryAvailable)
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
                if (!loadedListing.deliveryAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: const [
                        Icon(Icons.local_shipping, size: 18, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(
                          'Livraison non disponible',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                if (loadedListing.gender != null && loadedListing.gender!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.wc, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Genre : ${_formatGender(loadedListing.gender!)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                if (loadedListing.sizes.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: loadedListing.sizes
                        .map((s) => Chip(label: Text('Taille $s')))
                        .toList(),
                  ),
                if (loadedListing.colors.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: loadedListing.colors
                        .map((c) => Chip(label: Text('Couleur $c')))
                        .toList(),
                  ),
                if (loadedListing.condition != null)
                  Text('État : ${loadedListing.condition}'),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(loadedListing.description ?? 'Pas de description.'),
                const SizedBox(height: 16),
                if (loadedListing.sellerName != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openSellerProfile(loadedListing),
                          child: Text(
                            'Vendeur : ${loadedListing.sellerName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed:
                            _isTogglingSeller ? null : () => _toggleSellerFavorite(loadedListing),
                        icon: Icon(
                          _isSellerFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        label: Text(
                          _isSellerFavorite ? 'Retirer le vendeur' : 'Ajouter le vendeur',
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 18),
                    const SizedBox(width: 6),
                    Text('Stock disponible : ${loadedListing.stock}'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openOrderSheet(loadedListing),
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('Acheter'),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Détail annonce'),
            actions: [
              IconButton(
                tooltip: _isListingFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                onPressed:
                    listing == null || _isTogglingListing ? null : () => _toggleListingFavorite(listing),
                icon: _isLoadingFavorites && listing != null
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isListingFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isListingFavorite ? Colors.red : null,
                      ),
              ),
            ],
          ),
          body: body,
        );
      },
    );
  }
}

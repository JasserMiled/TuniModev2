import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/listing.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/order_form.dart';
import 'profile_screen.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/listing_card.dart';

class ListingDetailScreen extends StatefulWidget {
  final int listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  int _selectedIndex = 0;
  late Future<Listing> _futureListing;

  bool _isListingFavorite = false;
  bool _isSellerFavorite = false;
  bool _isLoadingFavorites = false;
  bool _isTogglingListing = false;
  bool _isTogglingSeller = false;
  bool _isDeleting = false;
  Future<User>? _sellerFuture;
  Future<List<Listing>>? _otherListingsFuture;

  @override
  void initState() {
    super.initState();
    _futureListing = ApiService.fetchListingDetail(widget.listingId);
  }

  bool get _isAuthenticated => ApiService.currentUser != null;
  // -----------------------------------------------------------
  // UTILITIES
  // -----------------------------------------------------------
  String _resolveImageUrl(String url) {
    if (url.startsWith('http')) return url;
    return "${ApiService.baseUrl}$url";
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<List<Listing>> _loadOtherListings(Listing listing) {
    _otherListingsFuture ??= ApiService.fetchUserListings(listing.userId);
    return _otherListingsFuture!;
  }

  Widget _buildOtherListingsSection(Listing listing) {
    return FutureBuilder<List<Listing>>(
      future: _loadOtherListings(listing),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox();
        }

        final otherListings = snapshot.data!
            .where((item) => item.id != listing.id)
            .toList();

        if (otherListings.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Autres articles du vendeur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: otherListings.length,
              itemBuilder: (context, index) {
                final item = otherListings[index];
                return ListingCard(
                  listing: item,
                  onTap: () => _openListingDetail(item.id),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // -----------------------------------------------------------
  // UI BLOCKS (Vinted Style)
  // -----------------------------------------------------------

  /// 🔵 CARROUSEL + MINIATURES
/// 🔵 GALERIE D’IMAGES (image principale + miniatures)
Widget buildImageGallery(List<String> images, Listing listing) {
  // Sécurise l’index
  if (_selectedIndex >= images.length) _selectedIndex = 0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // 🟧 IMAGE PRINCIPALE
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 550,
          width: double.infinity,
          child: images.isEmpty
              ? Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 120),
                  ),
                )
              : GestureDetector(
                  onTap: () => _openImagePreview(
                    images[_selectedIndex],
                    listing,
                  ),
                  child: Image.network(
                    _resolveImageUrl(images[_selectedIndex]),
                    fit: BoxFit.cover,
                  ),
                ),
        ),
      ),

      const SizedBox(height: 20),

      // 🟦 MINIATURES
      if (images.isNotEmpty)
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final url = _resolveImageUrl(images[i]);
              final isSelected = i == _selectedIndex;

              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: Container(
                  width: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );
}


  /// 🔵 PRIX + BOUTON ACHETER
  Widget buildPriceSection(Listing listing) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Prix
      Text(
        "${listing.price.toStringAsFixed(0)} TND",
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ❤️ BOUTON FAVORIS MINIMALISTE
      IconButton(
        onPressed: () => _toggleListingFavorite(listing),
        icon: Icon(
          _isListingFavorite ? Icons.favorite : Icons.favorite_border,
          color: Colors.red,
    
        ),
      ),
    ],
  );
}



  /// 🔵 BLOC D’INFORMATIONS (Vinted Style)
  Widget buildInfoTable(Listing listing) {
    List<Map<String, String>> info = [
      if (listing.condition != null) {"État": listing.condition!},
      if (listing.sizes.isNotEmpty) {"Tailles": listing.sizes.join(", ")},
      if (listing.colors.isNotEmpty) {"Couleurs": listing.colors.join(", ")},
      if (listing.gender != null) {"Genre": _capitalize(listing.gender!)},
      if (listing.city != null) {"Ville": listing.city!},
      {"Livraison": listing.deliveryAvailable ? "Disponible" : "Indisponible"},
      {"Stock": listing.stock.toString()},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: info
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.keys.first,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(item.values.first),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  /// 🔵 CARTE VENDEUR (comme Vinted)
  Widget buildSellerCard(Listing listing) {
    _sellerFuture ??= ApiService.fetchUserProfile(listing.userId);

    return FutureBuilder<User>(
      future: _sellerFuture,
      builder: (context, snapshot) {
        final avatarUrl = snapshot.data?.avatarUrl;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, size: 28, color: Colors.blueGrey.shade700)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openSellerProfile(listing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.sellerName ?? "Vendeur inconnu",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Voir le profil",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _toggleSellerFavorite(listing),
                icon: Icon(
                  _isSellerFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------
  // EVENT HANDLERS
  // -----------------------------------------------------------

  void _openListingDetail(int listingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(listingId: listingId),
      ),
    );
  }

  void _openImagePreview(String url, Listing listing) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(_resolveImageUrl(url), fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _openSellerProfile(Listing listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: listing.userId),
      ),
    );
  }

  void _openEditListing(Listing listing) {
    if (!_isListingOwner(listing)) return;

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: listing.title);
    final descriptionController =
        TextEditingController(text: listing.description ?? '');
    final priceController =
        TextEditingController(text: listing.price.toStringAsFixed(0));
    final sizesController =
        TextEditingController(text: listing.sizes.join(', '));
    final colorsController =
        TextEditingController(text: listing.colors.join(', '));
    final cityController = TextEditingController(text: listing.city ?? '');
    final stockController =
        TextEditingController(text: listing.stock.toString());

    final conditionOptions = [
      'Neuf avec étiquette',
      'Neuf sans étiquette',
      'Très bon état',
      'Bon état',
      'Satisfaisant',
    ];

    String? condition = listing.condition;
    bool deliveryAvailable = listing.deliveryAvailable;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> submit() async {
                if (!formKey.currentState!.validate()) return;

                final parsedPrice = double.tryParse(
                  priceController.text.replaceAll(',', '.'),
                );
                if (parsedPrice == null) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez saisir un prix valide.'),
                    ),
                  );
                  return;
                }

                final parsedStock =
                    int.tryParse(stockController.text.trim().isEmpty ? '1' : stockController.text.trim());

                setModalState(() => submitting = true);

                final success = await ApiService.updateListing(
                  id: listing.id,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  price: parsedPrice,
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
                  condition: condition,
                  city: cityController.text.trim().isEmpty
                      ? null
                      : cityController.text.trim(),
                  deliveryAvailable: deliveryAvailable,
                  stock: parsedStock ?? listing.stock,
                );

                if (!mounted) return;

                setModalState(() => submitting = false);

                if (success) {
                  setState(() {
                    _futureListing = ApiService.fetchListingDetail(listing.id);
                    _sellerFuture = null;
                    _otherListingsFuture = null;
                  });
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Annonce mise à jour avec succès.'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impossible de mettre à jour l\'annonce.'),
                    ),
                  );
                }
              }

              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Modifier l\'annonce',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: submitting
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Titre'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Le titre est obligatoire'
                                : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              decoration: const InputDecoration(
                                labelText: 'Prix (TND)',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Prix obligatoire'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: stockController,
                              decoration: const InputDecoration(
                                labelText: 'Stock',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: sizesController,
                        decoration: const InputDecoration(
                          labelText: 'Tailles (séparées par des virgules)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: colorsController,
                        decoration: const InputDecoration(
                          labelText: 'Couleurs (séparées par des virgules)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: condition,
                        decoration:
                            const InputDecoration(labelText: 'État du produit'),
                        items: conditionOptions
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setModalState(() => condition = value),
                        isExpanded: true,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: cityController,
                        decoration: const InputDecoration(labelText: 'Ville'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Livraison disponible'),
                        value: deliveryAvailable,
                        onChanged: (value) {
                          setModalState(() => deliveryAvailable = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: submitting ? null : submit,
                          icon: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(submitting ? 'Enregistrement...' : 'Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPrimaryActionButton(Listing listing) {
    final isOwner = _isListingOwner(listing);
    final buttonLabel = isOwner ? 'Modifier' : 'Acheter';
    final onPressed = isOwner ? () => _openEditListing(listing) : () => _openOrderSheet(listing);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E5B96),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          buttonLabel,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  bool _isListingOwner(Listing listing) {
    final user = ApiService.currentUser;
    return user != null && user.id == listing.userId;
  }

  Future<void> _deleteListing(Listing listing) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer l\'annonce'),
            content: const Text('Voulez-vous vraiment supprimer cette annonce ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isDeleting = true;
    });

    final success = await ApiService.deleteListing(listing.id);

    if (!mounted) return;

    setState(() {
      _isDeleting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce supprimée avec succès.')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer l\'annonce.')),
      );
    }
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

  void _openOrderSheet(Listing listing) {
    if (ApiService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connectez-vous pour commander.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => OrderForm(listing: listing),
    );
  }

  // -----------------------------------------------------------
  // BUILD MAIN UI
  // -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Listing>(
      future: _futureListing,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text("Impossible de charger l’annonce.")),
          );
        }

        final listing = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Détail annonce"),
            actions: [
              IconButton(
                onPressed: () => _toggleListingFavorite(listing),
                icon: Icon(
                  _isListingFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isListingFavorite ? Colors.red : Colors.white,
                ),
              ),
              const AccountMenuButton(),
              const SizedBox(width: 16),
            ],
          ),

          // 🟢 CONTENU PRINCIPAL
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800; // écran web

              if (isWide) {
                // 🖥️ MODE WEB → 2 colonnes encadrées
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -----------------------------------------------------
                      // 🟧 ZONE GAUCHE : IMAGE PRINCIPALE + MINIATURES
                      // -----------------------------------------------------
                      Expanded(
                        flex: 7,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 550,
                                  width: double.infinity,
                                  child: GestureDetector(
                                    onTap: listing.imageUrls.isEmpty
                                        ? null
                                        : () => _openImagePreview(
                                              listing.imageUrls[_selectedIndex],
                                              listing,
                                            ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: listing.imageUrls.isEmpty
                                          ? Container(
                                              color: Colors.grey.shade300,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 120,
                                                ),
                                              ),
                                            )
                                          : Image.network(
                                              _resolveImageUrl(
                                                  listing.imageUrls[_selectedIndex]),
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                ),
                                if (listing.imageUrls.length > 1) ...[
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 12),
                                      itemCount: listing.imageUrls.length,
                                      itemBuilder: (_, i) {
                                        final url =
                                            _resolveImageUrl(listing.imageUrls[i]);
                                        final isSelected = i == _selectedIndex;

                                        return GestureDetector(
                                          onTap: () =>
                                              setState(() => _selectedIndex = i),
                                          child: Container(
                                            width: 90,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.blueAccent
                                                    : Colors.grey.shade300,
                                                width: isSelected ? 3 : 1,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child:
                                                  Image.network(url, fit: BoxFit.cover),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                _buildOtherListingsSection(listing),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // -----------------------------------------------------
                      // 🟩 ZONE DROITE : INFORMATIONS PRODUIT
                      // -----------------------------------------------------
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildPriceSection(listing),
                                const SizedBox(height: 20),
                                buildInfoTable(listing),
                                const SizedBox(height: 20),
                                const Text(
                                  "Description",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(listing.description ?? "Aucune description."),
                                const SizedBox(height: 20),
                                buildSellerCard(listing),
                                const SizedBox(height: 30),
                                _buildPrimaryActionButton(listing),
                                const SizedBox(height: 10),
                                if (_isListingOwner(listing))
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _isDeleting ? null : () => _deleteListing(listing),
                                      icon: _isDeleting
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.delete_forever, color: Colors.white),
                                      label: Text(
                                        _isDeleting ? 'Suppression...' : 'Supprimer',
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // -----------------------------------------------------
              // 📱 MODE MOBILE → 1 colonne classique
              // -----------------------------------------------------
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildImageGallery(listing.imageUrls, listing),
                    const SizedBox(height: 20),
                    buildPriceSection(listing),
                    const SizedBox(height: 20),
                    buildInfoTable(listing),
                    const SizedBox(height: 20),
                    const Text(
                      "Description",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(listing.description ?? "Aucune description."),
                    const SizedBox(height: 20),
                    buildSellerCard(listing),
                    const SizedBox(height: 20),
                    _buildPrimaryActionButton(listing),
                    const SizedBox(height: 12),
                    if (_isListingOwner(listing))
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isDeleting ? null : () => _deleteListing(listing),
                          icon: _isDeleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.delete_forever, color: Colors.white),
                          label: Text(
                            _isDeleting ? 'Suppression...' : 'Supprimer',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (_isListingOwner(listing)) const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleListingFavorite(listing),
                        icon: Icon(
                          _isListingFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                        ),
                        label: Text(
                          _isListingFavorite
                              ? "Retirer des favoris"
                              : "Ajouter aux favoris",
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

}

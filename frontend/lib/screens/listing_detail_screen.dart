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
int _selectedIndex = 0;
  late Future<Listing> _futureListing;

  bool _isListingFavorite = false;
  bool _isSellerFavorite = false;
  bool _isLoadingFavorites = false;
  bool _isTogglingListing = false;
  bool _isTogglingSeller = false;

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            child: Icon(Icons.person, size: 28),
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
  }

  // -----------------------------------------------------------
  // EVENT HANDLERS
  // -----------------------------------------------------------

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
              )
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

            /// ⭐ Structure verticale : image qui prend tout + miniatures en bas
            child: Column(
              children: [
                
                // ⭐ IMAGE PRINCIPALE QUI PREND TOUT L’ESPACE DISPONIBLE
Expanded(
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
                child: Icon(Icons.image_not_supported, size: 120),
              ),
            )
          : Image.network(
              _resolveImageUrl(listing.imageUrls[_selectedIndex]),
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
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemCount: listing.imageUrls.length,
      itemBuilder: (_, i) {
        final url = _resolveImageUrl(listing.imageUrls[i]);
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

                
              ],
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
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      Text(listing.description ?? "Aucune description."),
      const SizedBox(height: 20),

      buildSellerCard(listing),
      const SizedBox(height: 30),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _openOrderSheet(listing),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E5B96),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Acheter",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
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

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () => _toggleListingFavorite(listing),
    icon: Icon(
      _isListingFavorite ? Icons.favorite : Icons.favorite_border,
      color: Colors.white,
    ),
    label: Text(
      _isListingFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
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

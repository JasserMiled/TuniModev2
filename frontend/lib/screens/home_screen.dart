import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/listing.dart';
import '../services/api_service.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/category_picker.dart';
import '../widgets/listing_card.dart';
import '../widgets/tunimode_drawer.dart';
import '../widgets/tunimode_app_bar.dart';
import '../widgets/quick_filters_dialog.dart';
import 'dashboard_screen.dart';
import 'listing_detail_screen.dart';
import 'search_results_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primaryBlue = Color(0xFF0B6EFE);
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lavender = Color(0xFFF1EDFD);

  static const double _pagePadding = 16;
  static const double _gridSpacing = 12;

  late Future<List<Listing>> _futureListings;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listingsSectionKey = GlobalKey();

  String? _selectedGender;
  String? _selectedCity;
  double? _minPrice;
  double? _maxPrice;
  int? _selectedCategoryId;
  List<String> _selectedSizes = [];
  List<String> _selectedColors = [];
  bool? _deliveryAvailable;
  List<Category> _categoryTree = [];
  bool _isLoadingCategories = false;
  String? _categoryLoadError;

  @override
  void initState() {
    super.initState();
    _futureListings = ApiService.fetchListings();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isProfessionalAccount =
        ApiService.authToken != null && ApiService.currentUser?.role == 'pro';

    return Scaffold(
      backgroundColor: _lightBackground,
      drawer: const TuniModeDrawer(),
      appBar: TuniModeAppBar(
        showSearchBar: true,
        searchController: _searchController,
        onSearch: _performSearch,
        onQuickFilters: _openQuickFilters,
        actions: [
          AccountMenuButton(
            onAuthChanged: () => setState(() {}),
          ),
        ],
      ),
      floatingActionButton: isProfessionalAccount
          ? FloatingActionButton.extended(
              onPressed: _openDashboard,
              icon: const Icon(Icons.store),
              label: const Text('Espace Pro'),
            )
          : null,

    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _pagePadding,
          0,               // ✔ plus de padding top ici !
          _pagePadding,
          _pagePadding,
        ),

        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActiveFilters(),
              _buildHeroBanner(),
                          const SizedBox(height: 24),  // 🔥 ajout d’espace sous le banner

              _buildListingsSection(),
            ],
          ),
        ),
      ),
    ),
  );
}
Widget _buildHeroBanner() {
  return Container(
    height: 500,                          // 🔥 hauteur fixe partout
    width: double.infinity,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,             // remplit tout l'espace
        children: [
          Image.asset(
            'assets/images/banner.jpg',
            fit: BoxFit.cover,            // 🟦 uniforme sur toutes les tailles d’écran
            alignment: Alignment.center,
          ),

          _buildHeroGradient(),           // dégradé noir léger

        ],
      ),
    ),
  );
}


  Widget _buildHeroGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.45),
            Colors.black.withOpacity(0.15),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
    );
  }

  Widget _buildHeroContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              'Plateforme n°1 de mode circulaire en Tunisie',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Découvre les dernières trouvailles sélectionnées pour toi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _performSearch(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Explorer'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _openQuickFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Filtres rapides'),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildListingsSection() {
  return FutureBuilder<List<Listing>>(
    key: _listingsSectionKey,
    future: _futureListings,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text('Erreur : ${snapshot.error}'),
          ),
        );
      }

      final listings = snapshot.data ?? [];
      if (listings.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('Aucune annonce pour le moment.')),
        );
      }

      final latestListings = listings.take(10).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Derniers articles mis en ligne',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choisis tes prochaines trouvailles parmi des milliers de vêtements et accessoires.',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          /// 📌 GRID VINTED-LIKE CENTRÉ + PLUS PETIT
          LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100, // 👈 limite la largeur du grid
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24), // 👈 espace à gauche/droite
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,       // 👈 toujours 4 cartes par ligne
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 32,
                      childAspectRatio: 0.70,  // 👈 rend les cartes plus fines
                    ),
                    itemCount: latestListings.length,
                    itemBuilder: (context, index) {
                      return ListingCard(
                        listing: latestListings[index],
                        onTap: () => _openListingDetail(latestListings[index].id),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}

Widget _buildSearchBar({bool compact = false}) {
  return Material(
    elevation: compact ? 0 : 2,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: 70, // ✅ LA HAUTEUR RÉELLE QUI VA ENFIN MARCHER
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.shade50),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // ✅ centrage vertical parfait
        children: [
          const Icon(Icons.search, color: _primaryBlue, size: 22),
          const SizedBox(width: 12),

          // ✅ TEXTFIELD PLUS HAUT
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Rechercher...',
                contentPadding:
                    EdgeInsets.symmetric(vertical: 14), // ✅ hauteur interne
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
            ),
          ),

          if (!compact) ...[
            const SizedBox(width: 12),

            // ✅ FILTRES RAPIDES
            InkWell(
              onTap: _openQuickFilters,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _lavender,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.filter_alt_outlined,
                        color: _primaryBlue, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Filtres rapides',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ✅ BOUTON CHERCHER
            SizedBox(
              height: 40,
              child: TextButton(
                onPressed: _performSearch,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _primaryBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Chercher',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}


  Widget _buildActiveFilters() {
    final chips = <Widget>[];

    if (_selectedGender != null) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.wc, size: 18),
          label: Text('Genre : ${_formatGenderLabel(_selectedGender!)}'),
          onDeleted: _clearGenderFilter,
        ),
      );
    }

    if (_selectedCity != null) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.location_on_outlined, size: 18),
          label: Text('Ville : $_selectedCity'),
          onDeleted: _clearCityFilter,
        ),
      );
    }

    if (_minPrice != null || _maxPrice != null) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.sell_outlined, size: 18),
          label: Text(_formatPriceRange()),
          onDeleted: _clearPriceFilter,
        ),
      );
    }

    if (_selectedCategoryId != null) {
      final categoryLabel = _categoryLabelForId(_selectedCategoryId!);
      chips.add(
        InputChip(
          avatar: const Icon(Icons.category_outlined, size: 18),
          label: Text('Catégorie : ${categoryLabel ?? '#${_selectedCategoryId}'}'),
          onDeleted: _clearCategoryFilter,
        ),
      );
    }

    if (_selectedSizes.isNotEmpty) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.straighten, size: 18),
          label: Text('Tailles : ${_selectedSizes.join(', ')}'),
          onDeleted: _clearSizeFilter,
        ),
      );
    }

    if (_selectedColors.isNotEmpty) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.palette_outlined, size: 18),
          label: Text('Couleurs : ${_selectedColors.join(', ')}'),
          onDeleted: _clearColorFilter,
        ),
      );
    }

    if (_deliveryAvailable != null) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.local_shipping_outlined, size: 18),
          label: Text(
            _deliveryAvailable == true
                ? 'Livraison disponible'
                : 'Retrait uniquement',
          ),
          onDeleted: _clearDeliveryFilter,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: chips,
      ),
    );
  }

  void _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryLoadError = null;
    });

    try {
      final categories = await ApiService.fetchCategoryTree();
      setState(() {
        _categoryTree = categories;
      });
    } catch (_) {
      setState(() {
        _categoryLoadError = 'Impossible de charger les catégories';
      });
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  void _performSearch([String? rawQuery]) {
    final query = (rawQuery ?? _searchController.text).trim();
    _searchController.text = query;
    _refreshListings(scrollToResults: true);
    _openSearchResults(query: query);
  }

  void _filterByGender(String gender) {
    final normalized = gender.trim().toLowerCase();
    setState(() {
      _selectedGender = normalized;
      _searchController.clear();
    });
    _refreshListings(scrollToResults: true);
  }

  void _clearGenderFilter() {
    if (_selectedGender == null) return;
    setState(() {
      _selectedGender = null;
    });
    _refreshListings(scrollToResults: true);
  }

  void _clearCityFilter() {
    if (_selectedCity == null) return;
    setState(() {
      _selectedCity = null;
    });
    _refreshListings(scrollToResults: true);
  }

  void _clearPriceFilter() {
    if (_minPrice == null && _maxPrice == null) return;
    setState(() {
      _minPrice = null;
      _maxPrice = null;
    });
    _refreshListings(scrollToResults: true);
  }

  void _clearCategoryFilter() {
    if (_selectedCategoryId == null) return;
    setState(() {
      _selectedCategoryId = null;
    });
    _refreshListings(scrollToResults: true);
  }

  void _clearSizeFilter() {
    if (_selectedSizes.isEmpty) return;
    setState(() {
      _selectedSizes = [];
    });
    _refreshListings(scrollToResults: true);
  }

  void _clearColorFilter() {
    if (_selectedColors.isEmpty) return;
    setState(() {
      _selectedColors = [];
    });
    _refreshListings(scrollToResults: true);
  }

  void _clearDeliveryFilter() {
    if (_deliveryAvailable == null) return;
    setState(() {
      _deliveryAvailable = null;
    });
    _refreshListings(scrollToResults: true);
  }

  void _refreshListings({bool scrollToResults = false}) {
    final query = _searchController.text.trim();
    setState(() {
      _futureListings = ApiService.fetchListings(
        query: query.isEmpty ? null : query,
        gender: _selectedGender,
        city: _selectedCity,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        categoryId: _selectedCategoryId,
        sizes: _selectedSizes,
        colors: _selectedColors,
        deliveryAvailable: _deliveryAvailable,
      );
    });

    if (scrollToResults) {
      _scrollToListings();
    }
  }

  void _scrollToListings() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _listingsSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  void _openQuickFilters() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => QuickFiltersDialog(
        categoryTree: _categoryTree,
        isLoadingCategories: _isLoadingCategories,
        categoryLoadError: _categoryLoadError,
        initialCity: _selectedCity,
        initialMinPrice: _minPrice,
        initialMaxPrice: _maxPrice,
        initialCategoryId: _selectedCategoryId,
        initialSizes: _selectedSizes,
        initialColors: _selectedColors,
        initialDeliveryAvailable: _deliveryAvailable,
        primaryColor: _primaryBlue,
        onApply: (selection) {
          setState(() {
            _selectedCity = selection.city;
            _minPrice = selection.minPrice;
            _maxPrice = selection.maxPrice;
            _selectedCategoryId = selection.categoryId;
            _selectedSizes = selection.sizes;
            _selectedColors = selection.colors;
            _deliveryAvailable = selection.deliveryAvailable;
          });
          _openSearchResults();
        },
        onReset: () {
          setState(() {
            _selectedCity = null;
            _minPrice = null;
            _maxPrice = null;
            _selectedCategoryId = null;
            _selectedSizes = [];
            _selectedColors = [];
            _deliveryAvailable = null;
          });
          _openSearchResults();
        },
      ),
    );
  }

  void _openSearchResults({String? query}) {
    final searchQuery = query?.trim() ?? _searchController.text.trim();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SearchResultsScreen(
          initialQuery: searchQuery,
          initialGender: _selectedGender,
          initialCity: _selectedCity,
          initialMinPrice: _minPrice,
          initialMaxPrice: _maxPrice,
          initialCategoryId: _selectedCategoryId,
          initialSizes: _selectedSizes,
          initialColors: _selectedColors,
          initialDeliveryAvailable: _deliveryAvailable,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _openDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _openListingDetail(int listingId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(listingId: listingId),
      ),
    );
  }

  int _responsiveColumnCount(double maxWidth) {
    if (maxWidth >= 1200) return 5;
    if (maxWidth >= 900) return 4;
    if (maxWidth >= 700) return 3;
    if (maxWidth >= 500) return 2;
    return 1;
  }

  double _childAspectRatioForColumns(int c) {
    if (c == 5) return 0.66;   // Vinted desktop EXACT
    if (c == 4) return 0.70;   // desktop un peu plus large
    if (c == 3) return 0.78;   // tablette paysage
    if (c == 2) return 0.95;   // tablette portrait
    return 1.15;               // mobile
  }

  String _formatPriceRange() {
    final min = _minPrice?.toStringAsFixed(0);
    final max = _maxPrice?.toStringAsFixed(0);

    if (_minPrice != null && _maxPrice != null) return 'Prix : $min - $max DT';
    if (_minPrice != null) return 'Prix min : $min DT';
    if (_maxPrice != null) return 'Prix max : $max DT';
    return '';
  }

  String _formatGenderLabel(String gender) {
    if (gender.isEmpty) return gender;
    return '${gender[0].toUpperCase()}${gender.substring(1)}';
  }

  List<_CategoryOption> _flattenCategories(
    List<Category> categories, [
    String prefix = '',
  ]) {
    final List<_CategoryOption> options = [];

    for (final category in categories) {
      final label = prefix.isEmpty ? category.name : '$prefix ${category.name}';
      options.add(_CategoryOption(id: category.id, label: label));

      if (category.children.isNotEmpty) {
        options.addAll(
          _flattenCategories(category.children, '$label ›'),
        );
      }
    }

    return options;
  }

  String? _categoryLabelForId(int id) {
    for (final option in _flattenCategories(_categoryTree)) {
      if (option.id == id) return option.label;
    }
    return null;
  }
}

class _CategoryOption {
  final int id;
  final String label;

  const _CategoryOption({
    required this.id,
    required this.label,
  });
}

import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primaryBlue = Color(0xFF0B6EFE);
  static const Color _lightBackground = Color(0xFFF7F9FC);
  static const Color _accentGreen = Color(0xFF24B072);
  static const Color _lavender = Color(0xFFF1EDFD);
  static const Color _peach = Color(0xFFFFF4EC);

  late Future<List<Listing>> _futureListings;
  final TextEditingController _searchController = TextEditingController();
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
  final List<String> _categories = const [
    'Femmes',
    'Hommes',
    'Enfants',
    'Chaussures',
    'Accessoires',
  ];

  @override
  void initState() {
    super.initState();
    _futureListings = ApiService.fetchListings();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryLoadError = null;
    });

    try {
      final categories = await ApiService.fetchCategoryTree();
      setState(() {
        _categoryTree = categories;
      });
    } catch (e) {
      setState(() {
        _categoryLoadError = 'Impossible de charger les catégories';
      });
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  void _performSearch() {
    _refreshListings();
  }

  void _selectCategory(String category) {
    _searchController.text = category;
    _performSearch();
  }

  void _filterByGender(String gender) {
    final normalized = gender.trim().toLowerCase();
    setState(() {
      _selectedGender = normalized;
      _searchController.clear();
      _refreshListings();
    });
  }

  void _clearGenderFilter() {
    if (_selectedGender == null) return;
    setState(() {
      _selectedGender = null;
      _refreshListings();
    });
  }

  void _clearCityFilter() {
    if (_selectedCity == null) return;
    setState(() {
      _selectedCity = null;
      _refreshListings();
    });
  }

  void _clearPriceFilter() {
    if (_minPrice == null && _maxPrice == null) return;
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _refreshListings();
    });
  }

  void _clearCategoryFilter() {
    if (_selectedCategoryId == null) return;
    setState(() {
      _selectedCategoryId = null;
      _refreshListings();
    });
  }

  void _clearSizeFilter() {
    if (_selectedSizes.isEmpty) return;
    setState(() {
      _selectedSizes = [];
      _refreshListings();
    });
  }

  void _clearColorFilter() {
    if (_selectedColors.isEmpty) return;
    setState(() {
      _selectedColors = [];
      _refreshListings();
    });
  }

  void _clearDeliveryFilter() {
    if (_deliveryAvailable == null) return;
    setState(() {
      _deliveryAvailable = null;
      _refreshListings();
    });
  }

  void _refreshListings() {
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
  }

  void _openQuickFilters() {
    final TextEditingController cityController =
        TextEditingController(text: _selectedCity ?? '');
    double tempMin = _minPrice ?? 0;
    double tempMax = _maxPrice ?? 500;
    int? tempCategoryId = _selectedCategoryId;
    bool? tempDelivery = _deliveryAvailable;
    final TextEditingController sizeController =
        TextEditingController(text: _selectedSizes.join(', '));
    final TextEditingController colorController =
        TextEditingController(text: _selectedColors.join(', '));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void setPreset(double min, double max) {
              setModalState(() {
                tempMin = min;
                tempMax = max;
              });
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filtres rapides',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ville',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            hintText: 'Ex: Tunis, Sousse, Bizerte...',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Catégorie',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            if (_isLoadingCategories)
                              const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            if (_categoryLoadError != null)
                              const Icon(Icons.error_outline, color: Colors.redAccent),
                          ],
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int?>(
                          value: tempCategoryId,
                          decoration: const InputDecoration(
                            hintText: 'Toutes les catégories',
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Toutes les catégories'),
                            ),
                            ..._flattenCategories(_categoryTree)
                                .map(
                                  (option) => DropdownMenuItem<int?>(
                                    value: option.id,
                                    child: Text(option.label),
                                  ),
                                )
                                .toList(),
                          ],
                          onChanged: _isLoadingCategories
                              ? null
                              : (value) => setModalState(() {
                                    tempCategoryId = value;
                                  }),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tailles (séparées par des virgules)',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: sizeController,
                          decoration: const InputDecoration(
                            hintText: 'Ex: S, M, L',
                            prefixIcon: Icon(Icons.straighten),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Couleurs (séparées par des virgules)',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: colorController,
                          decoration: const InputDecoration(
                            hintText: 'Ex: noir, bleu, rouge',
                            prefixIcon: Icon(Icons.palette_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Livraison',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<bool?>(
                          value: tempDelivery,
                          decoration: const InputDecoration(
                            hintText: 'Peu importe',
                          ),
                          items: const [
                            DropdownMenuItem<bool?>(
                              value: null,
                              child: Text('Peu importe'),
                            ),
                            DropdownMenuItem<bool?>(
                              value: true,
                              child: Text('Livraison disponible'),
                            ),
                            DropdownMenuItem<bool?>(
                              value: false,
                              child: Text('Retrait uniquement'),
                            ),
                          ],
                          onChanged: (value) => setModalState(() {
                            tempDelivery = value;
                          }),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Plage de prix',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            InputChip(
                              label: const Text('0 - 50'),
                              selected: tempMin == 0 && tempMax == 50,
                              onSelected: (_) => setPreset(0, 50),
                            ),
                            InputChip(
                              label: const Text('50 - 150'),
                              selected: tempMin == 50 && tempMax == 150,
                              onSelected: (_) => setPreset(50, 150),
                            ),
                            InputChip(
                              label: const Text('150 - 300'),
                              selected: tempMin == 150 && tempMax == 300,
                              onSelected: (_) => setPreset(150, 300),
                            ),
                            InputChip(
                              label: const Text('300+'),
                              selected: tempMin == 300 && tempMax == 500,
                              onSelected: (_) => setPreset(300, 500),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: RangeValues(tempMin, tempMax),
                          onChanged: (values) {
                            setModalState(() {
                              tempMin = values.start;
                              tempMax = values.end;
                            });
                          },
                          min: 0,
                          max: 500,
                          divisions: 10,
                          activeColor: _primaryBlue,
                          labels: RangeLabels(
                            '${valuesToCurrency(tempMin)}',
                            '${valuesToCurrency(tempMax)}',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() {
                                    tempMin = 0;
                                    tempMax = 500;
                                    cityController.clear();
                                    tempCategoryId = null;
                                    tempDelivery = null;
                                    sizeController.clear();
                                    colorController.clear();
                                  });
                                },
                                child: const Text('Réinitialiser'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final hasPriceFilter = tempMin > 0 || tempMax < 500;
                                  setState(() {
                                    _minPrice = hasPriceFilter ? tempMin : null;
                                    _maxPrice = hasPriceFilter ? tempMax : null;
                                    final city = cityController.text.trim();
                                    _selectedCity = city.isEmpty ? null : city;
                                    _selectedCategoryId = tempCategoryId;
                                    _selectedSizes = _parseInputList(sizeController.text);
                                    _selectedColors = _parseInputList(colorController.text);
                                    _deliveryAvailable = tempDelivery;
                                  });
                                  Navigator.of(context).pop();
                                  _refreshListings();
                                },
                                icon: const Icon(Icons.filter_alt),
                                label: const Text('Appliquer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
  }

  String valuesToCurrency(double value) {
    return '${value.toStringAsFixed(0)} TND';
  }

  String _formatPriceRange() {
    final buffer = StringBuffer('Prix : ');

    if (_minPrice != null && _maxPrice != null) {
      buffer.write('${valuesToCurrency(_minPrice!)} - ${valuesToCurrency(_maxPrice!)}');
    } else if (_minPrice != null) {
      buffer.write('dès ${valuesToCurrency(_minPrice!)}');
    } else if (_maxPrice != null) {
      buffer.write('jusqu\'à ${valuesToCurrency(_maxPrice!)}');
    }

    return buffer.toString();
  }

  List<String> _parseInputList(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<_CategoryOption> _flattenCategories(List<Category> categories,
      [String prefix = '']) {
    final options = <_CategoryOption>[];

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

  String _formatGenderLabel(String gender) {
    if (gender.isEmpty) return gender;
    return '${gender[0].toUpperCase()}${gender.substring(1)}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openDashboard() {
    Navigator.of(context).pushNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBackground,
      appBar: AppBar(
        titleSpacing: 16,
        toolbarHeight: 86,
        backgroundColor: _lightBackground,
        surfaceTintColor: _lightBackground,
        elevation: 0.3,
        shadowColor: Colors.black12,
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: _primaryBlue),
            const SizedBox(width: 8),
            const Text(
              'TuniMode',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(child: _buildSearchBar()),
            TextButton(
              onPressed: _openLogin,
              child: const Text('Se connecter'),
            ),
            const SizedBox(width: 6),
            const SizedBox(width: 12),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openDashboard,
        icon: const Icon(Icons.store),
        label: const Text('Espace Pro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryChips(),
              _buildActiveFilters(),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 7,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=1400&q=80',
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, _, __) {
                            return Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported, size: 40),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Style, seconde main et coups de cœur',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Parcourez les annonces inspirantes près de chez vous.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Listing>>(
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

                  final latestListings = listings.take(8).toList();

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
                      SizedBox(
                        height: 340,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: latestListings.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final listing = latestListings[index];
                            return SizedBox(
                              width: 170,
                              child: ListingCard(
                                listing: listing,
                                onGenderTap: _filterByGender,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ListingDetailScreen(
                                        listingId: listing.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.search, color: _primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Rechercher une marque, une tendance ou une taille...',
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
              ),
            ),
            InkWell(
              onTap: _openQuickFilters,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: _lavender,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: const [
                    Icon(Icons.filter_alt_outlined, color: _primaryBlue, size: 18),
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
            const SizedBox(width: 10),
            TextButton(
              onPressed: _performSearch,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Chercher'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _searchController.text.trim().toLowerCase() ==
              category.toLowerCase();
          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => _selectCategory(category),
            selectedColor: _primaryBlue.withOpacity(0.12),
            checkmarkColor: _primaryBlue,
            labelStyle: TextStyle(
              color: isSelected ? _primaryBlue : Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: isSelected ? _primaryBlue : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
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

  Widget _buildHighlights() {
    final cards = [
      _Highlight(
        icon: Icons.new_releases_rounded,
        label: 'Nouveautés quotidiennes',
        color: _lavender,
      ),
      _Highlight(
        icon: Icons.favorite_border,
        label: 'Coups de cœur de la communauté',
        color: _peach,
      ),
      _Highlight(
        icon: Icons.verified_user_outlined,
        label: 'Transactions sécurisées',
        color: Colors.white,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cards
            .map(
              (card) => Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: card.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(card.icon, color: _primaryBlue, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      card.label,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Derniers articles mis en ligne',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          'Mis à jour en temps réel',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Highlight {
  final IconData icon;
  final String label;
  final Color color;

  const _Highlight({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class _CategoryOption {
  final int id;
  final String label;

  const _CategoryOption({
    required this.id,
    required this.label,
  });
}

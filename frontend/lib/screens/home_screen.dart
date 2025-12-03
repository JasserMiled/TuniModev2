import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';
import 'login_screen.dart';
import 'order_requests_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'my_listings_screen.dart';
import 'favorites_screen.dart';

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
  static const List<String> _sizeOptions = [
    'XXXS / 30 / 2',
    'XXS / 32 / 4',
    'XS / 34 / 6',
    'S / 36 / 8',
    'M / 38 / 10',
    'L / 40 / 12',
    'XL / 42 / 14',
    'XXL / 44 / 16',
    'XXXL / 46 / 18',
    '4XL / 48 / 20',
    '5XL / 50 / 22',
    '6XL / 52 / 24',
    '7XL / 54 / 26',
    '8XL / 56 / 28',
    '9XL / 58 / 30',
    'Taille unique',
    'Autre',
  ];
  static const List<_ColorOption> _colorOptions = [
    _ColorOption('Noir', Color(0xFF000000)),
    _ColorOption('Blanc', Color(0xFFFFFFFF)),
    _ColorOption('Gris', Color(0xFF808080)),
    _ColorOption('Gris clair', Color(0xFFD3D3D3)),
    _ColorOption('Gris foncé', Color(0xFF404040)),
    _ColorOption('Rouge', Color(0xFFFF0000)),
    _ColorOption('Rouge foncé', Color(0xFF8B0000)),
    _ColorOption('Rouge clair', Color(0xFFFF6666)),
    _ColorOption('Bordeaux', Color(0xFF800020)),
    _ColorOption('Rose', Color(0xFFFFC0CB)),
    _ColorOption('Rose fuchsia', Color(0xFFFF00FF)),
    _ColorOption('Framboise', Color(0xFFE30B5D)),
    _ColorOption('Orange', Color(0xFFFFA500)),
    _ColorOption('Orange foncé', Color(0xFFFF8C00)),
    _ColorOption('Saumon', Color(0xFFFA8072)),
    _ColorOption('Corail', Color(0xFFFF7F50)),
    _ColorOption('Jaune', Color(0xFFFFFF00)),
    _ColorOption('Or', Color(0xFFFFD700)),
    _ColorOption('Beige', Color(0xFFF5F5DC)),
    _ColorOption('Crème', Color(0xFFFFFDD0)),
    _ColorOption('Vert', Color(0xFF008000)),
    _ColorOption('Vert clair', Color(0xFF90EE90)),
    _ColorOption('Vert foncé', Color(0xFF006400)),
    _ColorOption('Vert menthe', Color(0xFF98FF98)),
    _ColorOption('Vert olive', Color(0xFF808000)),
    _ColorOption('Vert émeraude', Color(0xFF50C878)),
    _ColorOption('Turquoise', Color(0xFF40E0D0)),
    _ColorOption('Cyan', Color(0xFF00FFFF)),
    _ColorOption('Bleu', Color(0xFF0000FF)),
    _ColorOption('Bleu clair', Color(0xFFADD8E6)),
    _ColorOption('Bleu foncé', Color(0xFF00008B)),
    _ColorOption('Bleu ciel', Color(0xFF87CEEB)),
    _ColorOption('Bleu turquoise', Color(0xFF30D5C8)),
    _ColorOption('Bleu marine', Color(0xFF000080)),
    _ColorOption('Indigo', Color(0xFF4B0082)),
    _ColorOption('Violet', Color(0xFF800080)),
    _ColorOption('Violet foncé', Color(0xFF2E0854)),
    _ColorOption('Lavande', Color(0xFFE6E6FA)),
    _ColorOption('Pourpre', Color(0xFF722F37)),
    _ColorOption('Marron', Color(0xFF8B4513)),
    _ColorOption('Chocolat', Color(0xFF7B3F00)),
    _ColorOption('Brun clair', Color(0xFFA0522D)),
    _ColorOption('Sable', Color(0xFFC2B280)),
    _ColorOption('Kaki', Color(0xFFF0E68C)),
    _ColorOption('Cuivre', Color(0xFFB87333)),
    _ColorOption('Argent', Color(0xFFC0C0C0)),
    _ColorOption('Platine', Color(0xFFE5E4E2)),
    _ColorOption('Bronze', Color(0xFFCD7F32)),
    _ColorOption('Pêche', Color(0xFFFFDAB9)),
    _ColorOption('Champagne', Color(0xFFF7E7CE)),
  ];

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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listingsSectionKey = GlobalKey();
  final List<String> _categories = const [
    'Femmes',
    'Hommes',
    'Enfants',
    'Chaussures',
    'Accessoires',
  ];

  bool get _isAuthenticated => ApiService.authToken != null;

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
    final query = _searchController.text.trim();
    _searchController.text = query;
    _refreshListings(scrollToResults: true);
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
    final TextEditingController cityController =
        TextEditingController(text: _selectedCity ?? '');
    double tempMin = _minPrice ?? 0;
    double tempMax = _maxPrice ?? 500;
    int? tempCategoryId = _selectedCategoryId;
    bool? tempDelivery = _deliveryAvailable;
    final List<String> tempSelectedSizes = List.from(_selectedSizes);
    final List<String> tempSelectedColors = List.from(_selectedColors);
    final List<Category> tempCategoryPath = tempCategoryId == null
        ? []
        : _findCategoryPath(_categoryTree, tempCategoryId!);

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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ActionChip(
                                    label: const Text('Toutes les catégories'),
                                    avatar: const Icon(Icons.home_outlined, size: 18),
                                    backgroundColor: tempCategoryPath.isEmpty
                                        ? _primaryBlue.withOpacity(0.12)
                                        : null,
                                    side: BorderSide(
                                      color: tempCategoryPath.isEmpty
                                          ? _primaryBlue
                                          : Colors.grey.shade300,
                                    ),
                                    onPressed: _isLoadingCategories
                                        ? null
                                        : () => setModalState(() {
                                              tempCategoryPath.clear();
                                              tempCategoryId = null;
                                            }),
                                  ),
                                  ...tempCategoryPath
                                      .asMap()
                                      .entries
                                      .expand(
                                        (entry) => [
                                          const Icon(Icons.chevron_right, size: 18),
                                          ActionChip(
                                            label: Text(entry.value.name),
                                            avatar: Icon(
                                              entry.key == tempCategoryPath.length - 1
                                                  ? Icons.check_circle
                                                  : Icons.folder_open,
                                              size: 18,
                                              color: _primaryBlue,
                                            ),
                                            backgroundColor:
                                                entry.key == tempCategoryPath.length - 1
                                                    ? _primaryBlue.withOpacity(0.12)
                                                    : null,
                                            side: BorderSide(
                                              color: entry.key == tempCategoryPath.length - 1
                                                  ? _primaryBlue
                                                  : Colors.grey.shade300,
                                            ),
                                            onPressed: () => setModalState(() {
                                              if (entry.key + 1 <
                                                  tempCategoryPath.length) {
                                                tempCategoryPath.removeRange(
                                                    entry.key + 1,
                                                    tempCategoryPath.length);
                                              }
                                              tempCategoryId = entry.value.id;
                                            }),
                                          ),
                                        ],
                                      )
                                      .toList(),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_isLoadingCategories)
                                const Center(child: CircularProgressIndicator(strokeWidth: 2))
                              else if (_categoryLoadError != null)
                                Text(
                                  _categoryLoadError!,
                                  style: const TextStyle(color: Colors.redAccent),
                                )
                              else ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      (tempCategoryPath.isEmpty ? _categoryTree : tempCategoryPath.last.children)
                                          .map(
                                    (category) {
                                      final isSelected = tempCategoryId == category.id;
                                      final hasChildren = category.children.isNotEmpty;
                                      return ChoiceChip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(category.name),
                                            if (hasChildren) ...const [
                                              SizedBox(width: 6),
                                              Icon(Icons.chevron_right, size: 18),
                                            ],
                                          ],
                                        ),
                                        selected: isSelected,
                                        selectedColor: _primaryBlue.withOpacity(0.12),
                                        onSelected: (_) => setModalState(() {
                                          tempCategoryPath.add(category);
                                          tempCategoryId = category.id;
                                        }),
                                      );
                                    },
                                  ).toList(),
                                ),
                                if ((tempCategoryPath.isEmpty
                                        ? _categoryTree
                                        : tempCategoryPath.last.children)
                                    .isEmpty)
                                  const Text(
                                    'Aucune sous-catégorie',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tailles',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String?>(
                          value: null,
                          decoration: const InputDecoration(
                            hintText: 'Sélectionner une taille',
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Ajouter une taille'),
                            ),
                            ..._sizeOptions.map(
                              (option) => DropdownMenuItem<String?>(
                                value: option,
                                child: Text(option),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setModalState(() {
                              if (!tempSelectedSizes.contains(value)) {
                                tempSelectedSizes.add(value);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tempSelectedSizes
                              .map(
                                (size) => InputChip(
                                  label: Text(size),
                                  onDeleted: () => setModalState(() {
                                    tempSelectedSizes.remove(size);
                                  }),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Couleurs',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String?>(
                          value: null,
                          decoration: const InputDecoration(
                            hintText: 'Sélectionner une couleur',
                            prefixIcon: Icon(Icons.palette_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Ajouter une couleur'),
                            ),
                            ..._colorOptions.map(
                              (option) => DropdownMenuItem<String?>(
                                value: option.name,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: option.color,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    Text(option.name),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setModalState(() {
                              if (!tempSelectedColors.contains(value)) {
                                tempSelectedColors.add(value);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tempSelectedColors
                              .map(
                                (color) => InputChip(
                                  label: Text(color),
                                  onDeleted: () => setModalState(() {
                                    tempSelectedColors.remove(color);
                                  }),
                                ),
                              )
                              .toList(),
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
                                    tempCategoryPath.clear();
                                    tempDelivery = null;
                                    tempSelectedSizes.clear();
                                    tempSelectedColors.clear();
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
                                    _selectedSizes = List.from(tempSelectedSizes);
                                    _selectedColors = List.from(tempSelectedColors);
                                    _deliveryAvailable = tempDelivery;
                                  });
                                  Navigator.of(context).pop();
                                  _refreshListings(scrollToResults: true);
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

  List<Category> _findCategoryPath(List<Category> categories, int targetId) {
    for (final category in categories) {
      if (category.id == targetId) {
        return [category];
      }
      final childPath = _findCategoryPath(category.children, targetId);
      if (childPath.isNotEmpty) {
        return [category, ...childPath];
      }
    }

    return [];
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openLogin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (!mounted) return;
    setState(() {});
  }

  void _openDashboard() {
    Navigator.of(context).pushNamed('/dashboard');
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openOrders() {
    final destination =
        ApiService.currentUser?.role == 'pro' ? const OrderRequestsScreen() : const OrdersScreen();

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
    );
  }

  void _handleLogout() {
    ApiService.logout();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vous êtes déconnecté')),
    );
  }

  void _openMyListings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyListingsScreen()),
    );
  }

  Widget _buildAccountButton() {
    if (!_isAuthenticated) {
      return TextButton(
        onPressed: _openLogin,
        child: const Text('Se connecter'),
      );
    }

    final isPro = ApiService.currentUser?.role == 'pro';
    final isAdmin = ApiService.currentUser?.role == 'admin';
    final canSeeListings = isPro || isAdmin;
    final ordersLabel = isPro ? 'Mes demandes de commandes' : 'Mes commandes';

    return PopupMenuButton<String>(
      tooltip: 'Menu du compte',
      icon: const Icon(Icons.menu, color: Color(0xFF0F172A)),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            _openProfile();
            break;
          case 'my_listings':
            _openMyListings();
            break;
          case 'orders':
            _openOrders();
            break;
          case 'favorites':
            _openFavorites();
            break;
          case 'logout':
            _handleLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Text('Mon profil'),
        ),
        const PopupMenuItem(
          value: 'favorites',
          child: Text('Mes favoris'),
        ),
        if (canSeeListings)
          const PopupMenuItem(
            value: 'my_listings',
            child: Text('Mes annonces'),
          ),
        PopupMenuItem(
          value: 'orders',
          child: Text(ordersLabel),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Text('Se déconnecter'),
        ),
      ],
    );
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
            _buildAccountButton(),
            const SizedBox(width: 6),
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
          controller: _scrollController,
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

class _ColorOption {
  final String name;
  final Color color;

  const _ColorOption(this.name, this.color);
}

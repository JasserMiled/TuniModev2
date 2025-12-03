import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/category.dart';
import '../models/listing.dart';
import '../services/api_service.dart';
import '../widgets/filter_bar.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;

  const SearchResultsScreen({super.key, required this.initialQuery});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  static const _primaryBlue = Color(0xFF0B6EFE);
  static const _sizeOptions = [
    'XXS / 32 / 4',
    'XS / 34 / 6',
    'S / 36 / 8',
    'M / 38 / 10',
    'L / 40 / 12',
    'XL / 42 / 14',
    'XXL / 44 / 16',
    'XXXL / 46 / 18',
    'Taille unique',
  ];
  static const _conditionOptions = [
    'Neuf avec étiquette',
    'Neuf sans étiquette',
    'Très bon état',
    'Bon état',
    'Satisfaisant',
  ];
  static const _brandOptions = [
    'Nike',
    'Adidas',
    'Zara',
    'H&M',
    'Bershka',
    'Mango',
    'Autre',
  ];
  static const _colorOptions = [
    'Noir',
    'Blanc',
    'Gris',
    'Rouge',
    'Rose',
    'Orange',
    'Jaune',
    'Vert',
    'Bleu',
    'Indigo',
    'Violet',
    'Marron',
  ];

  late String _searchQuery;
  final TextEditingController _searchController = TextEditingController();

  int? _selectedCategoryId;
  String? _selectedSize;
  String? _selectedBrand;
  String? _selectedCondition;
  String? _selectedColor;

  late Future<List<Listing>> _futureResults;
  List<Category> _categoryTree = [];
  bool _isLoadingCategories = false;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery;
    _searchController.text = widget.initialQuery;
    _futureResults = _loadResults();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final categories = await ApiService.fetchCategoryTree();
      if (!mounted) return;
      setState(() {
        _categoryTree = categories;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoryError = 'Impossible de charger les catégories';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<List<Listing>> _loadResults() {
    return ApiService.fetchListings(
      query: _searchQuery,
      categoryId: _selectedCategoryId,
      sizes: _selectedSize == null ? null : [_selectedSize!],
      colors: _selectedColor == null ? null : [_selectedColor!],
    );
  }

  void _refreshResults() {
    setState(() {
      _futureResults = _loadResults();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedSize = null;
      _selectedBrand = null;
      _selectedCondition = null;
      _selectedColor = null;
      _futureResults = _loadResults();
    });
  }

  List<_CategoryOption> get _flatCategories {
    final buffer = <_CategoryOption>[];

    void walk(List<Category> nodes, {int depth = 0}) {
      for (final category in nodes) {
        buffer.add(
          _CategoryOption(
            id: category.id,
            label: '${'• ' * depth}${category.name}',
          ),
        );
        if (category.children.isNotEmpty) {
          walk(category.children, depth: depth + 1);
        }
      }
    }

    walk(_categoryTree);
    return buffer;
  }

  List<Listing> _applyLocalFilters(List<Listing> listings) {
    return listings.where((listing) {
      final matchesBrand = _selectedBrand == null
          || listing.title.toLowerCase().contains(_selectedBrand!.toLowerCase());
      final matchesCondition = _selectedCondition == null
          || (listing.condition?.toLowerCase() ==
              _selectedCondition!.toLowerCase());
      return matchesBrand && matchesCondition;
    }).toList();
  }

  List<Widget> _buildActiveChips() {
    final chips = <Widget>[];

    if (_selectedCategoryId != null) {
      final categoryLabel =
          _flatCategories.firstWhere((c) => c.id == _selectedCategoryId).label;
      chips.add(
        InputChip(
          avatar: const Icon(Icons.category_outlined, size: 18),
          label: Text('Catégorie : ${categoryLabel.replaceAll('• ', '')}'),
          onDeleted: () => setState(() {
            _selectedCategoryId = null;
            _refreshResults();
          }),
        ),
      );
    }

    if (_selectedSize != null) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.straighten, size: 18),
          label: Text('Taille : $_selectedSize'),
          onDeleted: () => setState(() {
            _selectedSize = null;
            _refreshResults();
          }),
        ),
      );
    }

    if (_selectedBrand != null) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.store_mall_directory_outlined, size: 18),
          label: Text('Marque : $_selectedBrand'),
          onDeleted: () => setState(() {
            _selectedBrand = null;
          }),
        ),
      );
    }

    if (_selectedCondition != null) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.check_circle_outline, size: 18),
          label: Text('État : $_selectedCondition'),
          onDeleted: () => setState(() {
            _selectedCondition = null;
          }),
        ),
      );
    }

    if (_selectedColor != null) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.palette_outlined, size: 18),
          label: Text('Couleur : $_selectedColor'),
          onDeleted: () => setState(() {
            _selectedColor = null;
            _refreshResults();
          }),
        ),
      );
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final dropdowns = [
      FilterDropdownConfig(
        label: 'Catégorie',
        icon: Icons.category_outlined,
        value: _selectedCategoryId == null
            ? null
            : _flatCategories
                .firstWhere((c) => c.id == _selectedCategoryId)
                .label,
        options: _flatCategories.map((c) => c.label).toList(),
        onChanged: (value) {
          final selected = _flatCategories.firstWhere(
            (c) => c.label == value,
            orElse: () => _CategoryOption(id: -1, label: ''),
          );
          setState(() {
            _selectedCategoryId = selected.id == -1 ? null : selected.id;
            _refreshResults();
          });
        },
      ),
      FilterDropdownConfig(
        label: 'Taille',
        icon: Icons.straighten,
        value: _selectedSize,
        options: _sizeOptions,
        onChanged: (value) {
          setState(() {
            _selectedSize = value;
            _refreshResults();
          });
        },
      ),
      FilterDropdownConfig(
        label: 'Marque',
        icon: Icons.store_mall_directory_outlined,
        value: _selectedBrand,
        options: _brandOptions,
        onChanged: (value) {
          setState(() {
            _selectedBrand = value;
          });
        },
      ),
      FilterDropdownConfig(
        label: 'État',
        icon: Icons.check_circle_outline,
        value: _selectedCondition,
        options: _conditionOptions,
        onChanged: (value) {
          setState(() {
            _selectedCondition = value;
          });
        },
      ),
      FilterDropdownConfig(
        label: 'Couleur',
        icon: Icons.palette_outlined,
        value: _selectedColor,
        options: _colorOptions,
        onChanged: (value) {
          setState(() {
            _selectedColor = value;
            _refreshResults();
          });
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.4,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (value) {
                    if (value.trim().isEmpty) return;
                    setState(() {
                      _searchQuery = value.trim();
                      _futureResults = _loadResults();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans les annonces',
                    prefixIcon:
                        const Icon(Icons.search, color: _primaryBlue, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade100),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FBFF),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résultats de recherche',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vous recherchez : "$_searchQuery"',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (_isLoadingCategories)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (_categoryError != null)
                  Tooltip(
                    message: _categoryError!,
                    child:
                        const Icon(Icons.error_outline, color: Colors.redAccent),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FilterBar(
              dropdowns: dropdowns,
              activeFilters: _buildActiveChips(),
              onClearFilters: _clearFilters,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: FutureBuilder<List<Listing>>(
                future: _futureResults,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erreur : ${snapshot.error}'),
                    );
                  }

                  final results = _applyLocalFilters(snapshot.data ?? []);

                  if (results.isEmpty) {
                    return const Center(
                      child: Text('Aucune annonce ne correspond à vos filtres.'),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 1100
                          ? 4
                          : width >= 850
                              ? 3
                              : 2;

                      return MasonryGridView.count(
                        padding: const EdgeInsets.all(12),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final listing = results[index];
                          return ListingCard(
                            listing: listing,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ListingDetailScreen(
                                    listingId: listing.id,
                                  ),
                                ),
                              );
                            },
                            onGenderTap: (_) {},
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption {
  final int id;
  final String label;

  const _CategoryOption({required this.id, required this.label});
}

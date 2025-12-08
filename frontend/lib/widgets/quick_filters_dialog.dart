import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'category_picker.dart';

class QuickFiltersSelection {
  final String? city;
  final double? minPrice;
  final double? maxPrice;
  final int? categoryId;
  final List<String> sizes;
  final List<String> colors;
  final bool? deliveryAvailable;

  const QuickFiltersSelection({
    required this.city,
    required this.minPrice,
    required this.maxPrice,
    required this.categoryId,
    required this.sizes,
    required this.colors,
    required this.deliveryAvailable,
  });
}

class QuickFiltersDialog extends StatefulWidget {
  const QuickFiltersDialog({
    super.key,
    required this.categoryTree,
    required this.isLoadingCategories,
    required this.categoryLoadError,
    required this.initialCity,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.initialCategoryId,
    required this.initialSizes,
    required this.initialColors,
    required this.initialDeliveryAvailable,
    required this.onApply,
    required this.onReset,
    this.primaryColor = const Color(0xFF0B6EFE),
  });

  final List<Category> categoryTree;
  final bool isLoadingCategories;
  final String? categoryLoadError;

  final String? initialCity;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final int? initialCategoryId;
  final List<String> initialSizes;
  final List<String> initialColors;
  final bool? initialDeliveryAvailable;

  final Color primaryColor;

  final void Function(QuickFiltersSelection selection) onApply;
  final VoidCallback onReset;

  @override
  State<QuickFiltersDialog> createState() => _QuickFiltersDialogState();
}

class _QuickFiltersDialogState extends State<QuickFiltersDialog> {
  late TextEditingController _cityController;

  double? _tempMin;
  double? _tempMax;
  int? _tempCategoryId;
  bool? _tempDelivery;
  late List<String> _tempSizes;
  late List<String> _tempColors;
  List<String> _sizeOptions = [];
  bool _sizesLoading = false;
  String? _sizeError;

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

  @override
  void initState() {
    super.initState();
    _cityController =
        TextEditingController(text: widget.initialCity ?? '');
    _tempMin = widget.initialMinPrice;
    _tempMax = widget.initialMaxPrice;
    _tempCategoryId = widget.initialCategoryId;
    _tempDelivery = widget.initialDeliveryAvailable;
    _tempSizes = List.from(widget.initialSizes);
    _tempColors = List.from(widget.initialColors);

    if (_tempCategoryId != null) {
      _loadSizesForCategory(_tempCategoryId!, resetSelection: false);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFiltersContent(),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Filtres rapides",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filterSection(
                title: "Ville",
                child: TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    hintText: "Ex : Tunis, Sousse, Bizerte...",
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ),
              _filterSection(
                title: "Catégorie",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryPickerField(
                      categories: widget.categoryTree,
                      selectedCategoryId: _tempCategoryId,
                      onSelected: (category) {
                        setState(() {
                          _tempCategoryId = category?.id;
                          _sizeOptions = [];
                          _sizeError = null;
                          _sizesLoading = false;
                          if (category == null) {
                            _tempSizes = [];
                          }
                        });

                        if (category != null) {
                          _loadSizesForCategory(category.id);
                        }
                      },
                      isLoading: widget.isLoadingCategories,
                      showLabel: false,
                    ),
                    if (widget.categoryLoadError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.categoryLoadError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ]
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _filterSection(
                      title: "Tailles",
                      child: _buildSizeSelector(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _filterSection(
                      title: "Couleurs",
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: "Ajouter",
                          prefixIcon: Icon(Icons.palette_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text("Ajouter")),
                          ..._colorOptions.map(
                            (c) => DropdownMenuItem(
                              value: c.name,
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: c.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(c.name)),
                                  if (_tempColors.contains(c.name))
                                    const Icon(Icons.check,
                                        color: Colors.green, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null && !_tempColors.contains(v)) {
                            setState(() => _tempColors.add(v));
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _filterSection(
                      title: "Livraison",
                      child: DropdownButtonFormField<bool?>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: "Tous",
                          prefixIcon: Icon(Icons.local_shipping_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text("Tous")),
                          DropdownMenuItem(value: true, child: Text("Livraison")),
                          DropdownMenuItem(value: false, child: Text("Retrait")),
                        ],
                        onChanged: (v) => setState(() => _tempDelivery = v),
                      ),
                    ),
                  ),
                ],
              ),
              _filterSection(
                title: "Budget",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _tempMin?.toStringAsFixed(0) ?? '',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Min"),
                            onChanged: (v) {
                              final value = double.tryParse(v.trim());
                              _tempMin = v.trim().isEmpty ? null : value;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: _tempMax?.toStringAsFixed(0) ?? '',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Max"),
                            onChanged: (v) {
                              final value = double.tryParse(v.trim());
                              _tempMax = v.trim().isEmpty ? null : value;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: widget.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Appliquer les filtres",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _reset,
              child: const Text("Réinitialiser"),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _filterSection({
    required String title,
    Widget? child,
    Widget? trailing,
    double bottomPadding = 18,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          if (child != null) child,
        ],
      ),
    );
  }

  void _apply() {
    Navigator.of(context).pop();
    widget.onApply(
      QuickFiltersSelection(
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        minPrice: _tempMin,
        maxPrice: _tempMax,
        categoryId: _tempCategoryId,
        sizes: List.from(_tempSizes),
        colors: List.from(_tempColors),
        deliveryAvailable: _tempDelivery,
      ),
    );
  }

  void _reset() {
    Navigator.of(context).pop();
    widget.onReset();
  }

  Future<void> _loadSizesForCategory(int categoryId,
      {bool resetSelection = true}) async {
    setState(() {
      _sizesLoading = true;
      _sizeError = null;
      _sizeOptions = [];
      if (resetSelection) {
        _tempSizes = [];
      }
    });

    try {
      final sizes = await ApiService.fetchSizesForCategory(categoryId);
      if (!mounted) return;
      setState(() {
        _sizeOptions = sizes;
        _sizesLoading = false;
        _tempSizes = _tempSizes.where((size) => sizes.contains(size)).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sizesLoading = false;
        _sizeError = 'Impossible de charger les tailles';
      });
    }
  }

  Widget _buildSizeSelector() {
    if (_tempCategoryId == null) {
      return Text(
        'Sélectionnez une catégorie pour afficher les tailles.',
        style: TextStyle(color: Colors.grey.shade700),
      );
    }

    if (_sizesLoading) {
      return Row(
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Chargement des tailles...'),
        ],
      );
    }

    if (_sizeError != null) {
      return Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _sizeError!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          TextButton.icon(
            onPressed: () => _loadSizesForCategory(_tempCategoryId!,
                resetSelection: false),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      );
    }

    if (_sizeOptions.isEmpty) {
      return Text(
        'Aucune taille disponible pour cette catégorie.',
        style: TextStyle(color: Colors.grey.shade700),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: "Ajouter",
            prefixIcon: Icon(Icons.straighten),
          ),
          value: null,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text("Ajouter"),
            ),
            ..._sizeOptions.map(
              (s) => DropdownMenuItem(
                value: s,
                child: Row(
                  children: [
                    Expanded(child: Text(s)),
                    if (_tempSizes.contains(s))
                      const Icon(Icons.check, color: Colors.green, size: 18),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (v) {
            if (v != null && !_tempSizes.contains(v)) {
              setState(() => _tempSizes.add(v));
            }
          },
        ),
        if (_tempSizes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tempSizes
                .map(
                  (size) => InputChip(
                    label: Text(size),
                    onDeleted: () =>
                        setState(() => _tempSizes.remove(size)),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ColorOption {
  final String name;
  final Color color;

  const _ColorOption(this.name, this.color);
}

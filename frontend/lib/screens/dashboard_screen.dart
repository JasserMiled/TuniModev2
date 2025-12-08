import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../services/search_navigation_service.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/tunimode_app_bar.dart';
import '../widgets/tunimode_drawer.dart';
import '../widgets/auth_guard.dart';

class _ColorOption {
  final String name;
  final String hex;

  const _ColorOption({required this.name, required this.hex});
}

const List<_ColorOption> _colorOptions = [
  _ColorOption(name: 'Noir', hex: '#000000'),
  _ColorOption(name: 'Blanc', hex: '#FFFFFF'),
  _ColorOption(name: 'Gris', hex: '#808080'),
  _ColorOption(name: 'Gris clair', hex: '#D3D3D3'),
  _ColorOption(name: 'Gris foncé', hex: '#404040'),
  _ColorOption(name: 'Rouge', hex: '#FF0000'),
  _ColorOption(name: 'Rouge foncé', hex: '#8B0000'),
  _ColorOption(name: 'Rouge clair', hex: '#FF6666'),
  _ColorOption(name: 'Bordeaux', hex: '#800020'),
  _ColorOption(name: 'Rose', hex: '#FFC0CB'),
  _ColorOption(name: 'Rose fuchsia', hex: '#FF00FF'),
  _ColorOption(name: 'Framboise', hex: '#E30B5D'),
  _ColorOption(name: 'Orange', hex: '#FFA500'),
  _ColorOption(name: 'Orange foncé', hex: '#FF8C00'),
  _ColorOption(name: 'Saumon', hex: '#FA8072'),
  _ColorOption(name: 'Corail', hex: '#FF7F50'),
  _ColorOption(name: 'Jaune', hex: '#FFFF00'),
  _ColorOption(name: 'Or', hex: '#FFD700'),
  _ColorOption(name: 'Beige', hex: '#F5F5DC'),
  _ColorOption(name: 'Crème', hex: '#FFFDD0'),
  _ColorOption(name: 'Vert', hex: '#008000'),
  _ColorOption(name: 'Vert clair', hex: '#90EE90'),
  _ColorOption(name: 'Vert foncé', hex: '#006400'),
  _ColorOption(name: 'Vert menthe', hex: '#98FF98'),
  _ColorOption(name: 'Vert olive', hex: '#808000'),
  _ColorOption(name: 'Vert émeraude', hex: '#50C878'),
  _ColorOption(name: 'Turquoise', hex: '#40E0D0'),
  _ColorOption(name: 'Cyan', hex: '#00FFFF'),
  _ColorOption(name: 'Bleu', hex: '#0000FF'),
  _ColorOption(name: 'Bleu clair', hex: '#ADD8E6'),
  _ColorOption(name: 'Bleu foncé', hex: '#00008B'),
  _ColorOption(name: 'Bleu ciel', hex: '#87CEEB'),
  _ColorOption(name: 'Bleu turquoise', hex: '#30D5C8'),
  _ColorOption(name: 'Bleu marine', hex: '#000080'),
  _ColorOption(name: 'Indigo', hex: '#4B0082'),
  _ColorOption(name: 'Violet', hex: '#800080'),
  _ColorOption(name: 'Violet foncé', hex: '#2E0854'),
  _ColorOption(name: 'Lavande', hex: '#E6E6FA'),
  _ColorOption(name: 'Pourpre', hex: '#722F37'),
  _ColorOption(name: 'Marron', hex: '#8B4513'),
  _ColorOption(name: 'Chocolat', hex: '#7B3F00'),
  _ColorOption(name: 'Brun clair', hex: '#A0522D'),
  _ColorOption(name: 'Sable', hex: '#C2B280'),
  _ColorOption(name: 'Kaki', hex: '#F0E68C'),
  _ColorOption(name: 'Cuivre', hex: '#B87333'),
  _ColorOption(name: 'Argent', hex: '#C0C0C0'),
  _ColorOption(name: 'Platine', hex: '#E5E4E2'),
  _ColorOption(name: 'Bronze', hex: '#CD7F32'),
  _ColorOption(name: 'Pêche', hex: '#FFDAB9'),
];

const List<String> _conditionOptions = [
  'Neuf',
  'Excellent état',
  'Très bon état',
  'Bon état',
  'Satisfaisant',
];

class _PickedImage {
  final String name;
  final Uint8List bytes;
  String? uploadedUrl;

  _PickedImage({required this.name, required this.bytes, this.uploadedUrl});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _price = '';
  final List<String> _selectedSizes = [];
  final List<String> _selectedColors = [];
  List<String> _sizeOptions = [];
  String? _selectedSizeOption;
  String? _selectedColorOption;
  String _city = '';
  String? _condition;
  List<_PickedImage> _images = [];
  List<Category> _categoryTree = [];
  List<Category> _categoryPath = [];
  List<Category> _currentCategories = [];
  final TextEditingController _categorySearchController = TextEditingController();
  String _categorySearchTerm = '';
  Category? _selectedCategory;
  bool _deliveryAvailable = false;

  bool _loading = false;
  bool _categoriesLoading = true;
  bool _sizesLoading = false;
  bool _uploadingImages = false;
  String? _message;
  String? _categoryError;
  String? _sizeError;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _categorySearchController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    SearchNavigationService.openSearchResults(
      context: context,
      query: query,
    );
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoryError = null;
    });

    try {
      final tree = await ApiService.fetchCategoryTree();
      setState(() {
        _categoryTree = tree;
        _currentCategories = tree;
        _categoryPath = [];
        _selectedCategory = null;
        _categorySearchTerm = '';
        _categorySearchController.clear();
        _selectedSizeOption = null;
        _selectedColorOption = null;
        _categoriesLoading = false;
      });
    } catch (_) {
      setState(() {
        _categoryError = 'Impossible de charger les catégories';
        _categoriesLoading = false;
      });
    }
  }

  Future<void> _loadSizesForCategory(Category category) async {
    setState(() {
      _sizesLoading = true;
      _sizeError = null;
      _sizeOptions = [];
      _selectedSizeOption = null;
      _selectedSizes.clear();
    });

    try {
      final sizes = await ApiService.fetchSizesForCategory(category.id);
      setState(() {
        _sizeOptions = sizes;
        _sizesLoading = false;
      });
    } catch (_) {
      setState(() {
        _sizeError = 'Impossible de charger les tailles';
        _sizesLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final filesWithBytes =
          result.files.where((file) => file.bytes != null && file.bytes!.isNotEmpty);

      setState(() {
        _images = filesWithBytes
            .map((file) => _PickedImage(name: file.name, bytes: file.bytes!))
            .toList();
      });
    }
  }

  Future<List<String>?> _uploadSelectedImages() async {
    if (_images.isEmpty) return [];

    setState(() {
      _uploadingImages = true;
    });

    final urls = <String>[];

    for (final image in _images) {
      if (image.uploadedUrl != null) {
        urls.add(image.uploadedUrl!);
        continue;
      }

      final uploadedUrl =
          await ApiService.uploadImage(bytes: image.bytes, filename: image.name);

      if (uploadedUrl == null) {
        setState(() {
          _uploadingImages = false;
          _message = "Échec de l'upload de l'image ${image.name}";
        });
        return null;
      }

      image.uploadedUrl = uploadedUrl;
      urls.add(uploadedUrl);
    }

    setState(() {
      _uploadingImages = false;
    });

    return urls;
  }

  Future<void> _submit() async {
    if (ApiService.authToken == null) {
      setState(() {
        _message = "Vous devez être connecté en tant que PRO pour publier.";
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _message = null;
    });

    final uploadedImages = await _uploadSelectedImages();
    if (uploadedImages == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final ok = await ApiService.createListing(
      title: _title,
      description: _description,
      price: double.tryParse(_price) ?? 0,
      sizes: _selectedSizes,
      colors: _selectedColors,
      condition: _condition,
      categoryId: _selectedCategory?.id,
      city: _city.isEmpty ? null : _city,
      deliveryAvailable: _deliveryAvailable,
      images: uploadedImages,
    );

    setState(() {
      _loading = false;
      _message = ok ? "Annonce créée avec succès" : "Erreur lors de la création";
    });

    if (ok) {
      _formKey.currentState!.reset();
      setState(() {
        _selectedSizes.clear();
        _selectedColors.clear();
        _images = [];
        _condition = null;
        _deliveryAvailable = false;
        _selectedCategory = null;
        _selectedSizeOption = null;
        _selectedColorOption = null;
        _categoryPath = [];
        _currentCategories = _categoryTree;
        _sizeOptions = [];
        _sizeError = null;
        _sizesLoading = false;
      });
    }
  }

  void _selectCategory(Category category) {
    setState(() {
      _selectedCategory = category;
      _selectedSizeOption = null;
    });

    _loadSizesForCategory(category);
  }

  void _openCategory(Category category) {
    if (category.children.isEmpty) {
      _selectCategory(category);
      return;
    }

    setState(() {
      _categoryPath = [..._categoryPath, category];
      _currentCategories = category.children;
      _selectedCategory = null;
      _categorySearchTerm = '';
      _categorySearchController.clear();
      _sizeOptions = [];
      _selectedSizeOption = null;
      _selectedSizes.clear();
      _sizeError = null;
      _sizesLoading = false;
    });
  }

  void _goToLevel(int index) {
    if (index < 0) {
      setState(() {
        _categoryPath = [];
        _currentCategories = _categoryTree;
        _selectedCategory = null;
        _categorySearchTerm = '';
        _categorySearchController.clear();
        _sizeOptions = [];
        _selectedSizeOption = null;
        _selectedSizes.clear();
        _sizeError = null;
        _sizesLoading = false;
      });
      return;
    }

    setState(() {
      _categoryPath = _categoryPath.sublist(0, index + 1);
      _currentCategories = _categoryPath.last.children;
      _selectedCategory = null;
      _categorySearchTerm = '';
      _categorySearchController.clear();
      _sizeOptions = [];
      _selectedSizeOption = null;
      _selectedSizes.clear();
      _sizeError = null;
      _sizesLoading = false;
    });
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _iconForCategoryName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('femme') || lower.contains('robe')) {
      return Icons.checkroom_outlined;
    }
    if (lower.contains('homme')) {
      return Icons.person_outline;
    }
    if (lower.contains('chauss')) {
      return Icons.hiking_outlined;
    }
    if (lower.contains('sac') || lower.contains('bag')) {
      return Icons.shopping_bag_outlined;
    }
    if (lower.contains('access')) {
      return Icons.watch_outlined;
    }
    if (lower.contains('enfant')) {
      return Icons.child_friendly;
    }
    return Icons.category_outlined;
  }

  void _toggleColor(String colorName) {
    setState(() {
      if (_selectedColors.contains(colorName)) {
        _selectedColors.remove(colorName);
      } else {
        _selectedColors.add(colorName);
      }
    });
  }

  void _toggleSize(String size) {
    setState(() {
      if (_selectedSizes.contains(size)) {
        _selectedSizes.remove(size);
      } else {
        _selectedSizes.add(size);
      }
    });
  }

  Widget _buildSizeSelector() {
    Widget sizeContent;

    if (_selectedCategory == null) {
      sizeContent = const Text('Sélectionnez une catégorie pour afficher les tailles.');
    } else if (_sizesLoading) {
      sizeContent = const Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('Chargement des tailles...'),
        ],
      );
    } else if (_sizeError != null) {
      sizeContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sizeError!,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed:
                _selectedCategory == null ? null : () => _loadSizesForCategory(_selectedCategory!),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      );
    } else if (_sizeOptions.isEmpty) {
      sizeContent = const Text('Aucune taille disponible pour cette catégorie.');
    } else {
      sizeContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedSizeOption,
            decoration: const InputDecoration(
              labelText: 'Ajouter une taille',
            ),
            items: _sizeOptions
                .map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: Text(size),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                if (!_selectedSizes.contains(value)) {
                  _selectedSizes.add(value);
                }
                _selectedSizeOption = null;
              });
            },
          ),
          if (_selectedSizes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedSizes
                  .map(
                    (size) => InputChip(
                      label: Text(size),
                      onDeleted: () => _toggleSize(size),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
	  const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tailles disponibles',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        sizeContent,
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Couleurs disponibles',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedColorOption,
              decoration: const InputDecoration(
                labelText: 'Sélectionnez une ou plusieurs couleurs dans la liste',
				  labelStyle: TextStyle(
    fontSize: 14, // 👈 taille du label
  ),
              ),
              items: _colorOptions
                  .map(
                    (option) => DropdownMenuItem(
                      value: option.name,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _colorFromHex(option.hex),
                            radius: 8,
                          ),
                          const SizedBox(width: 8),
                          Text(option.name),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  if (!_selectedColors.contains(value)) {
                    _selectedColors.add(value);
                  }
                  _selectedColorOption = null;
                });
              },
            ),
            if (_selectedColors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedColors
                    .map(
                      (color) => InputChip(
                        label: Text(color),
                        avatar: CircleAvatar(
                          backgroundColor:
                              _colorFromHex(_colorOptions.firstWhere((c) => c.name == color).hex),
                          radius: 10,
                        ),
                        onDeleted: () => _toggleColor(color),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    if (_categoriesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Chargement des catégories...'),
          ],
        ),
      );
    }

    if (_categoryError != null) {
      return Column(
        children: [
          Text(
            _categoryError!,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      );
    }

    final visibleCategories = _currentCategories
        .where(
          (category) => category.name
              .toLowerCase()
              .contains(_categorySearchTerm.toLowerCase()),
        )
        .toList();

    final pathSegments = _categoryPath.map((category) => category.name).toList();
    if (_selectedCategory != null &&
        !_categoryPath.any((category) => category.id == _selectedCategory!.id)) {
      pathSegments.add(_selectedCategory!.name);
    }

    final pathLabel = pathSegments.isEmpty ? 'Catégories' : pathSegments.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_categoryPath.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _goToLevel(_categoryPath.length - 2),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back),
                    const SizedBox(width: 12),
                    Text(
                      pathLabel,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        TextField(
          controller: _categorySearchController,
          decoration: InputDecoration(
            hintText: 'Trouver une catégorie',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey.shade200,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => setState(() => _categorySearchTerm = value.trim()),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (_selectedCategory != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sélectionné : ${_selectedCategory!.name}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _goToLevel(-1),
                        child: const Text('Changer'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: visibleCategories.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: Text('Aucune catégorie trouvée')), 
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: visibleCategories.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final category = visibleCategories[index];
                          final hasChildren = category.children.isNotEmpty;
                          final isSelected = _selectedCategory?.id == category.id;

                          return ListTile(
                            leading: Icon(
                              _iconForCategoryName(category.name),
                              color: Colors.teal.shade600,
                            ),
                            title: Text(category.name),
                            trailing: hasChildren
                                ? const Icon(Icons.chevron_right)
                                : (isSelected
                                    ? const Icon(Icons.check, color: Colors.green)
                                    : null),
                            onTap: hasChildren
                                ? () => _openCategory(category)
                                : () => _selectCategory(category),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      builder: (context) => Scaffold(
        drawer: const TuniModeDrawer(),
        appBar: TuniModeAppBar(
          showSearchBar: true,
          searchController: _searchController,
          onSearch: _handleSearch,
          actions: const [
            AccountMenuButton(),
            SizedBox(width: 16),
          ],
        ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Titre'),
                          onSaved: (v) => _title = v?.trim() ?? '',
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                        ),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                          onSaved: (v) => _description = v?.trim() ?? '',
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Photos du produit',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._images.asMap().entries.map(
                              (entry) => Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      entry.value.bytes,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _images.removeAt(entry.key);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _loading ? null : _pickImages,
                              icon: const Icon(Icons.photo_library),
                              label: Text(
                                _images.isEmpty
                                    ? 'Ajouter des photos'
                                    : 'Ajouter d\'autres photos',
                              ),
                            ),
                          ],
                        ),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Prix (TND)'),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => _price = v?.trim() ?? '',
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                        ),
                        _buildSizeSelector(),
                        const SizedBox(height: 8),
                        _buildColorSelector(),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Catégorie',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCategorySelector(),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Ville'),
                          onSaved: (v) => _city = v?.trim() ?? '',
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Livraison disponible'),
                          subtitle: const Text(
                            'Indiquez si vous pouvez expédier le produit.',
                          ),
                          value: _deliveryAvailable,
                          onChanged: (value) {
                            setState(() {
                              _deliveryAvailable = value;
                            });
                          },
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'État du produit'),
                          value: _condition,
                          items: _conditionOptions
                              .map(
                                (condition) => DropdownMenuItem(
                                  value: condition,
                                  child: Text(condition),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _condition = value;
                            });
                          },
                          onSaved: (value) => _condition = value,
                        ),
                        const SizedBox(height: 16),
                        if (_message != null)
                          Text(
                            _message!,
                            style: TextStyle(
                              color: _message!.contains("succès")
                                  ? Colors.blue
                                  : Colors.red,
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (_uploadingImages)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Upload des images...'),
                              ],
                            ),
                          ),
                        _loading
                            ? const CircularProgressIndicator()
                            : ElevatedButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.check),
                                label: const Text('Publier'),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';

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
  String _sizesText = '';
  String _colorsText = '';
  String? _gender;
  String _city = '';
  String _condition = '';
  List<_PickedImage> _images = [];
  List<Category> _categoryTree = [];
  List<Category> _categoryPath = [];
  List<Category> _currentCategories = [];
  Category? _selectedCategory;

  bool _loading = false;
  bool _categoriesLoading = true;
  bool _uploadingImages = false;
  String? _message;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
        _categoriesLoading = false;
      });
    } catch (_) {
      setState(() {
        _categoryError = 'Impossible de charger les catégories';
        _categoriesLoading = false;
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

    List<String> _splitValues(String input) => input
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();

    final ok = await ApiService.createListing(
      title: _title,
      description: _description,
      price: double.tryParse(_price) ?? 0,
      sizes: _splitValues(_sizesText),
      colors: _splitValues(_colorsText),
      gender: _gender,
      condition: _condition.isEmpty ? null : _condition,
      categoryId: _selectedCategory?.id,
      city: _city.isEmpty ? null : _city,
      images: uploadedImages,
    );

    setState(() {
      _loading = false;
      _message = ok ? "Annonce créée avec succès" : "Erreur lors de la création";
    });

    if (ok) {
      _formKey.currentState!.reset();
      setState(() {
        _gender = null;
        _sizesText = '';
        _colorsText = '';
        _images = [];
        _selectedCategory = null;
        _categoryPath = [];
        _currentCategories = _categoryTree;
      });
    }
  }

  void _selectCategory(Category category) {
    setState(() {
      _selectedCategory = category;
    });
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
    });
  }

  void _goToLevel(int index) {
    if (index < 0) {
      setState(() {
        _categoryPath = [];
        _currentCategories = _categoryTree;
        _selectedCategory = null;
      });
      return;
    }

    setState(() {
      _categoryPath = _categoryPath.sublist(0, index + 1);
      _currentCategories = _categoryPath.last.children;
      _selectedCategory = null;
    });
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Racine'),
              selected: _categoryPath.isEmpty,
              onSelected: (_) => _goToLevel(-1),
            ),
            ..._categoryPath.asMap().entries.map(
                  (entry) => FilterChip(
                    label: Text(entry.value.name),
                    selected: entry.key == _categoryPath.length - 1,
                    onSelected: (_) => _goToLevel(entry.key),
                  ),
                ),
          ],
        ),
        if (_selectedCategory != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Catégorie sélectionnée : ${_selectedCategory!.name}',
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
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _currentCategories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = _currentCategories[index];
              return ListTile(
                leading: Radio<int>(
                  value: category.id,
                  groupValue: _selectedCategory?.id,
                  onChanged: (_) => _selectCategory(category),
                ),
                title: Text(category.name),
                subtitle: category.children.isNotEmpty
                    ? Text('${category.children.length} sous-catégories')
                    : null,
                trailing: category.children.isNotEmpty
                    ? IconButton(
                        onPressed: () => _openCategory(category),
                        icon: const Icon(Icons.chevron_right),
                      )
                    : null,
                onTap: category.children.isNotEmpty
                    ? () => _openCategory(category)
                    : () => _selectCategory(category),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Pro - TuniMode'),
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
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Tailles disponibles',
                            helperText: 'Séparez les valeurs par des virgules',
                          ),
                          onSaved: (v) => _sizesText = v?.trim() ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Couleurs disponibles',
                            helperText: 'Séparez les valeurs par des virgules',
                          ),
                          onSaved: (v) => _colorsText = v?.trim() ?? '',
                        ),
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
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Genre'),
                          value: _gender,
                          items: const [
                            DropdownMenuItem(value: 'homme', child: Text('Homme')),
                            DropdownMenuItem(value: 'femme', child: Text('Femme')),
                            DropdownMenuItem(value: 'enfant', child: Text('Enfant')),
                            DropdownMenuItem(value: 'unisexe', child: Text('Unisexe')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _gender = value;
                            });
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Ville'),
                          onSaved: (v) => _city = v?.trim() ?? '',
                        ),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'État (Neuf, Bon, etc.)'),
                          onSaved: (v) => _condition = v?.trim() ?? '',
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
    );
  }
}

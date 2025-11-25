import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

  bool _loading = false;
  bool _uploadingImages = false;
  String? _message;

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
      categoryId: null,
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
      });
    }
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

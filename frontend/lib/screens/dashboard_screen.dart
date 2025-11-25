import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  bool _loading = false;
  String? _message;

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
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        const SizedBox(height: 8),
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

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _phone = '';
  String _role = 'buyer';
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await ApiService.register(
      name: _name,
      email: _email,
      password: _password,
      role: _role,
      phone: _phone,
    );

    setState(() {
      _loading = false;
    });

    if (ok) {
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      setState(() {
        _error = "Inscription échouée (email déjà utilisé ?)";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Créer un compte")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Nom'),
                          onSaved: (v) => _name = v?.trim() ?? '',
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (v) => _email = v?.trim() ?? '',
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Téléphone'),
                          keyboardType: TextInputType.phone,
                          onSaved: (v) => _phone = v?.trim() ?? '',
                        ),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Mot de passe'),
                          obscureText: true,
                          onSaved: (v) => _password = v ?? '',
                          validator: (v) =>
                              (v == null || v.length < 4) ? 'Min 4 caractères' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Type de compte : '),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _role,
                              items: const [
                                DropdownMenuItem(
                                  value: 'buyer',
                                  child: Text('Particulier'),
                                ),
                                DropdownMenuItem(
                                  value: 'pro',
                                  child: Text('Professionnel'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() {
                                  _role = v;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_error != null)
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        const SizedBox(height: 8),
                        _loading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _submit,
                                child: const Text("S'inscrire"),
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

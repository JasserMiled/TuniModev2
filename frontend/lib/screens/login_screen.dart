import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/search_navigation_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/tunimode_app_bar.dart';
import '../widgets/tunimode_drawer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await ApiService.login(email: _email, password: _password);

    setState(() {
      _loading = false;
    });

    if (ok) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else {
      setState(() {
        _error = 'Identifiants invalides';
      });
    }
  }

  void _openRegister() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RegisterScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _handleSearch(String query) {
    SearchNavigationService.openSearchResults(
      context: context,
      query: query,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        onSaved: (v) => _email = v?.trim() ?? '',
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Mot de passe'),
                        obscureText: true,
                        onSaved: (v) => _password = v ?? '',
                        validator: (v) =>
                            (v == null || v.length < 4) ? 'Min 4 caractères' : null,
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
                              child: const Text('Se connecter'),
                            ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _openRegister,
                        child: const Text("Créer un compte"),
                      ),
                    ],
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

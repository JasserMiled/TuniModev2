import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
enum RegistrationType { particulier, professionnel }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialType = RegistrationType.particulier});

  final RegistrationType initialType;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _individualFormKey = GlobalKey<FormState>();
  final _professionalFormKey = GlobalKey<FormState>();

  String _individualFirstName = '';
  String _individualLastName = '';
  String _individualEmail = '';
  String _individualPhone = '';
  DateTime? _birthDate;
  final _individualPasswordController = TextEditingController();
  final _individualConfirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();

  String _shopName = '';
  String _professionalFirstName = '';
  String _professionalLastName = '';
  String _professionalEmail = '';
  String _professionalPhone = '';
  final _professionalPasswordController = TextEditingController();
  final _professionalConfirmPasswordController = TextEditingController();
  bool _showIndividualPassword = false;
  bool _showProfessionalPassword = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialType == RegistrationType.particulier ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _individualPasswordController.dispose();
    _individualConfirmPasswordController.dispose();
    _professionalPasswordController.dispose();
    _professionalConfirmPasswordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ obligatoire';
    final normalized = value.trim();
    if (!normalized.contains('@') || !normalized.contains('.')) return 'Email invalide';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ obligatoire';
    var normalized = value.replaceAll(' ', '');
    if (normalized.startsWith('+216')) {
      normalized = normalized.substring(4);
    }
    final onlyDigits = normalized.split('').every((c) => int.tryParse(c) != null);
    if (!onlyDigits || normalized.length != 8) {
      return 'Numéro tunisien invalide (8 chiffres)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Champ obligatoire';
    if (value.length < 12) return '12 caractères minimum';
    if (!RegExp('[A-Z]').hasMatch(value)) return 'Ajoutez une majuscule';
    if (!RegExp('[a-z]').hasMatch(value)) return 'Ajoutez une minuscule';
    if (!RegExp('[^A-Za-z0-9]').hasMatch(value)) {
      return 'Ajoutez un caractère spécial';
    }
    return null;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 12),
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }


Future<void> _submit() async {
  final isIndividual = _tabController.index == 0;
  final formKey = isIndividual ? _individualFormKey : _professionalFormKey;

  if (!formKey.currentState!.validate()) return;
  formKey.currentState!.save();

  setState(() {
    _loading = true;
    _error = null;
  });

  bool ok = false;

  try {
    if (isIndividual) {
      ok = await _registerIndividual()
          .timeout(const Duration(seconds: 15));
    } else {
      ok = await _registerProfessional()
          .timeout(const Duration(seconds: 15));
    }
  } catch (e) {
    print("❌ ERREUR SUBMIT REGISTER: $e");
    ok = false;
  }

  if (!mounted) return;

  setState(() => _loading = false);

  if (ok) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()), // ✅ ICI
    );
  } else {
    setState(() {
      _error = "Inscription échouée (serveur indisponible)";
    });
  }
}


  Future<bool> _registerIndividual() async {
    final ok = await ApiService.register(
      name: '$_individualFirstName $_individualLastName'.trim(),
      email: _individualEmail,
      password: _individualPasswordController.text,
      role: 'buyer',
      phone: _individualPhone,
      address: _birthDateController.text.isNotEmpty
          ? 'Date de naissance: ${_birthDateController.text}'
          : null,
    );
    return ok;
  }

  Future<bool> _registerProfessional() async {
    final ok = await ApiService.register(
      name: '$_professionalFirstName $_professionalLastName'.trim(),
      email: _professionalEmail,
      password: _professionalPasswordController.text,
      role: 'pro',
      phone: _professionalPhone,
      address: _shopName,
    );
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Créer un compte',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choisissez votre profil et complétez les informations requises.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: 520,
                        child: TabBarView(
                          controller: _tabController,
						  physics: const NeverScrollableScrollPhysics(), // ✅ empêche le swipe
                          children: [
                            _buildIndividualForm(),
                            _buildProfessionalForm(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndividualForm() {
    return Form(
      key: _individualFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Nom'),
                  onSaved: (v) => _individualLastName = v?.trim() ?? '',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  onSaved: (v) => _individualFirstName = v?.trim() ?? '',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'E-mail'),
            keyboardType: TextInputType.emailAddress,
            onSaved: (v) => _individualEmail = v?.trim() ?? '',
            validator: _validateEmail,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Numéro de téléphone (tunisien)'),
            keyboardType: TextInputType.phone,
            onSaved: (v) => _individualPhone = v?.trim() ?? '',
            validator: _validatePhone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _birthDateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Date de naissance',
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            onTap: _pickBirthDate,
            validator: (v) => (v == null || v.isEmpty)
                ? 'Veuillez sélectionner votre date de naissance'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _individualPasswordController,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              helperText:
                  '12 caractères minimum avec majuscule, minuscule et caractère spécial.',
              suffixIcon: IconButton(
                icon: Icon(
                  _showIndividualPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _showIndividualPassword = !_showIndividualPassword;
                  });
                },
              ),
            ),
            obscureText: !_showIndividualPassword,
            validator: _validatePassword,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _individualConfirmPasswordController,
            decoration: const InputDecoration(labelText: 'Confirmez le mot de passe'),
            obscureText: !_showIndividualPassword,
            validator: (v) {
              final pwd = _individualPasswordController.text;
              if (v == null || v.isEmpty) return 'Champ obligatoire';
              if (v != pwd) return 'Les mots de passe ne correspondent pas';
              return null;
            },
          ),
          const Spacer(),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5B96),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "S'inscrire en tant que particulier",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildProfessionalForm() {
    return Form(
      key: _professionalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Nom de boutique'),
            onSaved: (v) => _shopName = v?.trim() ?? '',
            validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Nom'),
                  onSaved: (v) => _professionalLastName = v?.trim() ?? '',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  onSaved: (v) => _professionalFirstName = v?.trim() ?? '',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'E-mail'),
            keyboardType: TextInputType.emailAddress,
            onSaved: (v) => _professionalEmail = v?.trim() ?? '',
            validator: _validateEmail,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Numéro de téléphone (tunisien)'),
            keyboardType: TextInputType.phone,
            onSaved: (v) => _professionalPhone = v?.trim() ?? '',
            validator: _validatePhone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _professionalPasswordController,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              helperText:
                  '12 caractères minimum avec majuscule, minuscule et caractère spécial.',
              suffixIcon: IconButton(
                icon: Icon(
                  _showProfessionalPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _showProfessionalPassword = !_showProfessionalPassword;
                  });
                },
              ),
            ),
            obscureText: !_showProfessionalPassword,
            validator: _validatePassword,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _professionalConfirmPasswordController,
            decoration: const InputDecoration(labelText: 'Confirmez le mot de passe'),
            obscureText: !_showProfessionalPassword,
            validator: (v) {
              final pwd = _professionalPasswordController.text;
              if (v == null || v.isEmpty) return 'Champ obligatoire';
              if (v != pwd) return 'Les mots de passe ne correspondent pas';
              return null;
            },
          ),
          const Spacer(),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Inscrire votre boutique maintenant',
                    style: TextStyle(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
        ],
      ),
    );
  }
}

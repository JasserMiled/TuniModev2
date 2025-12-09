import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/tunimode_app_bar.dart';
import '../widgets/tunimode_drawer.dart';
import 'register_screen.dart';
import '../widgets/app_buttons.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({
  super.key,
  this.successMessage,
  this.prefilledEmail,
});

final String? successMessage;
final String? prefilledEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
bool _showSuccess = false;

  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _error;
  bool _rememberMe = false;
  bool _showPassword = false;
@override
void initState() {
  super.initState();

  if (widget.prefilledEmail != null) {
    _emailController.text = widget.prefilledEmail!;
  }

  if (widget.successMessage != null) {
    _showSuccess = true;
  }
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
      pageBuilder: (_, __, ___) => const RegisterScreen(
        initialType: RegistrationType.particulier, 
      ),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
  );
}

  void _openProRegister() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            const RegisterScreen(initialType: RegistrationType.professionnel),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF3F4F6),
	  // ✅ SAME DRAWER AS OTHER SCREENS
  drawer: const TuniModeDrawer(),

  // ✅ SAME APP BAR CONFIG (LOGO LEFT, NO SEARCH, NO BACK)
  appBar: const TuniModeAppBar(
    showSearchBar: false,
    showBackButton: false,
  ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          // ✅ ✅ ✅ CONTAINER AVEC SHADOW WEB
          child: Container(
		  height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 25,
                  spreadRadius: 3,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),

              // ✅ ✅ ✅ FORM PROPRE
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Connexion',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 28),
if (_showSuccess)
  Center( // ✅ centre le bloc dans la page
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 16, // ✅ largeur interne réduite
        vertical: 8,     // ✅ hauteur interne réduite
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5), // plus arrondi
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // ✅ empêche d'étirer en largeur
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle, color: Colors.green, size: 18), // ✅ icône plus petite
          SizedBox(width: 6),
          Text(
            "Compte créé avec succès",
            style: TextStyle(
              color: Colors.green,

              fontSize: 14, // ✅ texte plus petit
            ),
          ),
        ],
      ),
    ),
  ),

                    // ✅ EMAIL
                    TextFormField(
  controller: _emailController,
  decoration: const InputDecoration(
    labelText: 'E-mail',
                        prefixIcon: Icon(Icons.mail_outline),
                        border: UnderlineInputBorder(),
                      ),
                      onSaved: (v) => _email = _emailController.text.trim(),

                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                    ),

                    const SizedBox(height: 22),

                    // ✅ PASSWORD
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                        border: const UnderlineInputBorder(),
                      ),
                      obscureText: !_showPassword,
                      onSaved: (v) => _password = v ?? '',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                    ),

                    const SizedBox(height: 14),

                    // ✅ CHECKBOX + FORGOT
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                        ),
                        const Text('Rester connecté'),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    const SizedBox(height: 28),
					                    
                    const Divider(),
                    const SizedBox(height: 28),
                    // ✅ GOOGLE
OutlinedButton.icon(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(
      horizontal: 2, // ✅ réduit la largeur
      vertical: 16,
    ),
    minimumSize: Size.zero,      // ✅ enlève la largeur mini par défaut
    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // ✅ ultra compact
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5), // ✅ angles très arrondis
    ),
    side: const BorderSide(
      color: Colors.grey, // optionnel : couleur du contour
    ),
  ),
icon: SvgPicture.asset(
  'assets/google_logo.svg',
  height: 18,
),
  label: const Text('Connexion avec Google'),
),

					const SizedBox(height: 28),
					                    const Divider(),
                    const SizedBox(height: 28),
					

// ✅ BOUTONS
Row(
  children: [
    Expanded(
      child: SecondaryButton(
        label: "S'inscrire",
        onPressed: _openRegister,
		height: 32,
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: PrimaryButton(
        label: 'Se connecter',
        onPressed: _submit,
		height: 32,
      ),
    ),
  ],
),

const SizedBox(height: 28),

// ✅ BOUTIQUE

PrimaryButton(
  label: 'Inscrivez votre boutique maintenant',
  onPressed: _openProRegister,
  height: 32,
),






                    const SizedBox(height: 12),

TextButton(
  onPressed: () {
    setState(() {
      _showSuccess = true;
      _emailController.text = "test@gmail.com";
    });
  },
  child: const Text("Afficher succès (TEST)"),
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

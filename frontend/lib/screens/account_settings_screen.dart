import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/search_navigation_service.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/tunimode_app_bar.dart';
import '../widgets/auth_guard.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _generalFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _searchController = TextEditingController();

  User? _user;
  bool _loading = true;
  bool _savingGeneral = false;
  bool _savingSecurity = false;
  bool _uploadingAvatar = false;
  String? _message;
  String? _error;

  Uint8List? _avatarBytes;
  String? _avatarName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    SearchNavigationService.openSearchResults(
      context: context,
      query: query,
    );
  }

  Future<void> _loadUser() async {
    final current = ApiService.currentUser;
    if (current == null) {
      setState(() {
        _loading = false;
        _error = 'Connectez-vous pour accéder aux paramètres du compte.';
      });
      return;
    }

    try {
      final user = await ApiService.fetchUserProfile(current.id);
      _applyUser(user);
    } catch (_) {
      _applyUser(current);
    }
  }

  void _applyUser(User user) {
    setState(() {
      _user = user;
      _nameController.text = user.name;
      _addressController.text = user.address ?? '';
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _loading = false;
      _error = null;
    });
  }

  Future<void> _saveGeneral() async {
    if (_user == null) return;
    if (!_generalFormKey.currentState!.validate()) return;

    setState(() {
      _savingGeneral = true;
      _message = null;
      _error = null;
    });

    try {
      final updatedUser = await ApiService.updateProfile(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
      );
      _applyUser(updatedUser);
      setState(() {
        _message = 'Informations générales mises à jour';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _savingGeneral = false;
      });
    }
  }

  Future<void> _saveSecurity() async {
    if (_user == null) return;
    if (!_securityFormKey.currentState!.validate()) return;

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if ((currentPassword.isEmpty) != (newPassword.isEmpty)) {
      setState(() {
        _error = 'Pour changer de mot de passe, remplissez les deux champs.';
        _message = null;
      });
      return;
    }

    setState(() {
      _savingSecurity = true;
      _message = null;
      _error = null;
    });

    try {
      final updatedUser = await ApiService.updateProfile(
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        currentPassword: currentPassword.isNotEmpty ? currentPassword : null,
        newPassword: newPassword.isNotEmpty ? newPassword : null,
      );
      _applyUser(updatedUser);
      setState(() {
        _message = 'Paramètres de sécurité mis à jour';
        _currentPasswordController.clear();
        _newPasswordController.clear();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _savingSecurity = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        setState(() {
          _avatarBytes = file.bytes;
          _avatarName = file.name;
        });
      }
    }
  }

  Future<void> _uploadAvatar() async {
    if (_avatarBytes == null || _avatarName == null || _user == null) return;

    setState(() {
      _uploadingAvatar = true;
      _message = null;
      _error = null;
    });

    try {
      final url = await ApiService.uploadProfileImage(
        bytes: _avatarBytes!,
        filename: _avatarName!,
      );

      final updatedUser = await ApiService.updateProfile(avatarUrl: url);
      final updatedWithAvatar =
          (updatedUser.avatarUrl != null && updatedUser.avatarUrl!.isNotEmpty)
              ? updatedUser
              : updatedUser.copyWith(avatarUrl: url);

      ApiService.currentUser = updatedWithAvatar;
      _applyUser(updatedWithAvatar);
      setState(() {
        _avatarBytes = null;
        _avatarName = null;
        _message = 'Photo de profil mise à jour';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _uploadingAvatar = false;
      });
    }
  }

  Widget _buildAvatarSection() {
    ImageProvider? imageProvider;
    if (_avatarBytes != null) {
      imageProvider = MemoryImage(_avatarBytes!);
    } else if (_user?.avatarUrl != null && _user!.avatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_user!.avatarUrl!);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Photo de profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: imageProvider,
                  backgroundColor: Colors.grey.shade300,
                  child: imageProvider == null
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _avatarName ?? 'Sélectionnez une image pour votre profil',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickAvatar,
                            icon: const Icon(Icons.upload),
                            label: const Text('Choisir une photo'),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                _uploadingAvatar ? null : (_avatarBytes != null ? _uploadAvatar : null),
                            icon: const Icon(Icons.save),
                            label: _uploadingAvatar
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Mettre à jour la photo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _generalFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations générales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _savingGeneral ? null : _saveGeneral,
                  icon: _savingGeneral
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _securityFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sécurité',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Adresse e-mail',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'e-mail est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.lock_outline, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pour changer de mot de passe, remplissez les deux champs ci-dessous.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _savingSecurity ? null : _saveSecurity,
                  icon: _savingSecurity
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      builder: (context) => Scaffold(
        appBar: TuniModeAppBar(
          showSearchBar: true,
          searchController: _searchController,
          onSearch: _handleSearch,
          actions: const [
            AccountMenuButton(),
            SizedBox(width: 16),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_message != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_message!)),
                                ],
                              ),
                            ),
                          if (_error != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_error!)),
                                ],
                              ),
                            ),
                          _buildAvatarSection(),
                          const SizedBox(height: 12),
                          _buildGeneralSection(),
                          const SizedBox(height: 12),
                          _buildSecuritySection(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

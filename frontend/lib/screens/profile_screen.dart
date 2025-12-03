import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/review.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Review>> _reviewsFuture;
  final _generalFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _savingGeneral = false;
  bool _savingSecurity = false;
  bool _uploading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = ApiService.currentUser;
    _nameController.text = user?.name ?? '';
    _addressController.text = user?.address ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';
    _avatarUrl = user?.avatarUrl;
    _reviewsFuture =
        user != null ? ApiService.fetchUserReviews(user.id) : Future.value([]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: isError ? Colors.redAccent : null),
    );
  }

  Future<void> _saveGeneralInfo() async {
    if (!_generalFormKey.currentState!.validate()) return;
    setState(() => _savingGeneral = true);
    try {
      final updated = await ApiService.updateProfile(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
      );
      setState(() {
        _avatarUrl = updated.avatarUrl;
      });
      _showMessage('Informations générales mises à jour');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _savingGeneral = false);
    }
  }

  Future<void> _saveSecurityInfo() async {
    if (!_securityFormKey.currentState!.validate()) return;
    setState(() => _savingSecurity = true);
    try {
      await ApiService.updateProfile(
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        currentPassword: _currentPasswordController.text.isNotEmpty
            ? _currentPasswordController.text
            : null,
        newPassword:
            _newPasswordController.text.isNotEmpty ? _newPasswordController.text : null,
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _showMessage('Paramètres de sécurité mis à jour');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _savingSecurity = false);
    }
  }

  Future<void> _uploadAvatar() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (picked == null || picked.files.single.bytes == null) return;

    setState(() => _uploading = true);
    try {
      final file = picked.files.single;
      final url = await ApiService.uploadProfileImage(
        bytes: file.bytes!,
        filename: file.name,
      );
      final updated = await ApiService.updateProfile(avatarUrl: url);
      setState(() {
        _avatarUrl = updated.avatarUrl;
      });
      _showMessage('Photo de profil mise à jour');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  double? _averageRating(List<Review> reviews) {
    if (reviews.isEmpty) return null;
    final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}';
  }

  Widget _buildReviewTile(Review review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.rate_review, color: Colors.amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[700], size: 18),
                    const SizedBox(width: 4),
                    Text('${review.rating}/5',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review.reviewerName != null
                      ? 'Par ${review.reviewerName}'
                      : 'Avis reçu',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(review.comment!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return FutureBuilder<List<Review>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Impossible de charger vos évaluations pour le moment.',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final reviews = snapshot.data ?? [];
        final average = _averageRating(reviews);

        if (reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Aucune évaluation reçue pour le moment.'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[700]),
                const SizedBox(width: 6),
                Text(
                  average != null
                      ? 'Note totale : ${average.toStringAsFixed(1)}/5'
                      : 'Note totale indisponible',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text('(${reviews.length} avis)'),
              ],
            ),
            const SizedBox(height: 12),
            ...reviews.map(_buildReviewTile),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null
                          ? const Icon(Icons.person, size: 32, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Utilisateur',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(user?.email ?? 'Email non disponible'),
                          const SizedBox(height: 6),
                          Chip(
                            label: Text(
                              user?.role == 'pro' ? 'Professionnel' : 'Acheteur',
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _uploading ? null : _uploadAvatar,
                      icon: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined),
                      label: const Text('Photo de profil'),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Paramètre de compte',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Information générales',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Form(
                  key: _generalFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nom'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Le nom est requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration:
                            const InputDecoration(labelText: 'Adresse', hintText: 'Adresse complète'),
                        minLines: 1,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _savingGeneral ? null : _saveGeneralInfo,
                          icon: _savingGeneral
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sécurité',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Form(
                  key: _securityFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Email requis'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration:
                            const InputDecoration(labelText: 'Numéro de téléphone'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _currentPasswordController,
                        decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPasswordController,
                        decoration:
                            const InputDecoration(labelText: 'Nouveau mot de passe (optionnel)'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _savingSecurity ? null : _saveSecurityInfo,
                          icon: _savingSecurity
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.lock_outline),
                          label: const Text('Mettre à jour'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Évaluations reçues',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildReviewsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

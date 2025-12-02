import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.name ?? 'Utilisateur',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(user?.email ?? 'Email non disponible'),
                const SizedBox(height: 8),
                if (user?.phone != null && user!.phone!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 18),
                        const SizedBox(width: 6),
                        Text(user.phone!),
                      ],
                    ),
                  ),
                if (user?.address != null && user!.address!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.home, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(user.address!)),
                      ],
                    ),
                  ),
                Chip(
                  label: Text(
                    user?.role == 'pro' ? 'Professionnel' : 'Acheteur',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Les informations détaillées du profil seront affichées ici.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

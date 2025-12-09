import 'package:flutter/material.dart';

import '../screens/home_screen.dart';

class TuniModeDrawer extends StatelessWidget {
  const TuniModeDrawer({super.key});

  void _goHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title bientôt disponible'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
	  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.zero, // ✅ aucun arrondi
  ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _DrawerHeader(),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Accueil'),
              onTap: () {
                Navigator.of(context).pop();
                _goHome(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('À propos'),
              onTap: () => _showComingSoon(context, 'À propos'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text("Conditions d'utilisation"),
              onTap: () => _showComingSoon(context, "Conditions d'utilisation"),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Contact'),
              onTap: () => _showComingSoon(context, 'Contact'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: const Color(0xFFF7F9FC),
      alignment: Alignment.centerLeft,
      child: Row(
        children: const [
          Icon(Icons.menu_outlined, size: 28),
          SizedBox(width: 12),
          Text(
            'Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

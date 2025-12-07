import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../screens/account_settings_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/login_screen.dart';
import '../screens/my_listings_screen.dart';
import '../screens/order_requests_screen.dart';
import '../screens/profile_screen.dart';

class AccountMenuButton extends StatefulWidget {
  const AccountMenuButton({super.key, this.onAuthChanged});

  final VoidCallback? onAuthChanged;

  @override
  State<AccountMenuButton> createState() => _AccountMenuButtonState();
}

class _AccountMenuButtonState extends State<AccountMenuButton> {
  bool get _isAuthenticated => ApiService.authToken != null;

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return TextButton.icon(
        onPressed: _openLogin,
        icon: const Icon(
          Icons.login,
          color: Color(0xFF1E5B96),
          size: 16,
        ),
        label: const Text(
          'SE CONNECTER',
          style: TextStyle(
            color: Color(0xFF1E5B96),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            fontSize: 12,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      );
    }

    final isPro = ApiService.currentUser?.role == 'pro';
    final isAdmin = ApiService.currentUser?.role == 'admin';
    final canSeeListings = isPro || isAdmin;
    const ordersLabel = 'Mes commandes';

    return PopupMenuButton<String>(
      tooltip: 'Menu du compte',
      icon: const Icon(Icons.menu, color: Color(0xFF0F172A)),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            _openProfile();
            break;
          case 'my_listings':
            _openMyListings();
            break;
          case 'orders':
            _openOrders(buyerOnly: !canSeeListings);
            break;
          case 'favorites':
            _openFavorites();
            break;
          case 'account_settings':
            _openAccountSettings();
            break;
          case 'logout':
            _handleLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Text('Mon profil'),
        ),
        const PopupMenuItem(
          value: 'favorites',
          child: Text('Mes favoris'),
        ),
        if (canSeeListings)
          const PopupMenuItem(
            value: 'my_listings',
            child: Text('Mes annonces'),
          ),
        PopupMenuItem(
          value: 'orders',
          child: Text(ordersLabel),
        ),
        const PopupMenuItem(
          value: 'account_settings',
          child: Text('Paramètres de compte'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Text('Se déconnecter'),
        ),
      ],
    );
  }

  Future<void> _openLogin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (!mounted) return;
    setState(() {});
    widget.onAuthChanged?.call();
  }

  void _openProfile() {
    final userId = ApiService.currentUser?.id;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
    );
  }

  void _openOrders({bool buyerOnly = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderRequestsScreen(buyerOnly: buyerOnly),
      ),
    );
  }

  void _openFavorites() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
    );
  }

  void _openAccountSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
    );
  }

  void _openMyListings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyListingsScreen()),
    );
  }

  void _handleLogout() {
    ApiService.logout();
    setState(() {});
    widget.onAuthChanged?.call();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}


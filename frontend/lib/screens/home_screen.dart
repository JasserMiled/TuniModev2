import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/api_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primaryBlue = Color(0xFF0B6EFE);
  static const Color _lightBackground = Color(0xFFF6F3EE);
  static const Color _accentGreen = Color(0xFF2FB280);

  late Future<List<Listing>> _futureListings;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = const [
    'Nouveautés',
    'Casual',
    'Sport',
    'Traditionnel',
    'Luxueux',
    'Enfant',
  ];

  @override
  void initState() {
    super.initState();
    _futureListings = ApiService.fetchListings();
  }

  void _reload() {
    setState(() {
      final query = _searchController.text.trim();
      _futureListings = ApiService.fetchListings(
        query: query.isEmpty ? null : query,
      );
    });
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    setState(() {
      _futureListings = ApiService.fetchListings(
        query: query.isEmpty ? null : query,
      );
    });
  }

  void _selectCategory(String category) {
    _searchController.text = category;
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openDashboard() {
    Navigator.of(context).pushNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBackground,
      appBar: AppBar(
        title: const Text('TuniMode'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _primaryBlue),
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(Icons.person, color: _primaryBlue),
            onPressed: _openLogin,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openDashboard,
        icon: const Icon(Icons.store),
        label: const Text('Espace Pro'),
        backgroundColor: _primaryBlue,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildCategoryChips(),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Listing>>(
                  future: _futureListings,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Erreur : ${snapshot.error}'),
                      );
                    }
                    final listings = snapshot.data ?? [];
                    if (listings.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucune annonce pour le moment. Découvrons les premières tendances TuniMode !',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: listings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final listing = listings[index];
                        return ListingCard(
                          listing: listing,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ListingDetailScreen(listingId: listing.id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F5F0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7DFD4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildHeroText()),
                    const SizedBox(width: 18),
                    _buildHeroImage(height: 260),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroImage(height: 220),
                    const SizedBox(height: 16),
                    _buildHeroText(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.shopping_bag, color: _primaryBlue),
            ),
            SizedBox(width: 10),
            Text(
              'Bienvenue sur TuniMode',
              style: TextStyle(
                color: Color(0xFF3D3D3D),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Prêt à faire du tri dans tes placards ?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D2A26),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Donne une seconde vie à tes pièces, vends en sécurité et inspire les passionnés de mode en Tunisie.',
          style: TextStyle(
            color: Color(0xFF4D4A45),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: _openDashboard,
              icon: const Icon(Icons.upload_rounded),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: const Text(
                'Commencer à vendre',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton(
              onPressed: _openLogin,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                side: const BorderSide(color: Color(0xFFCBC3B3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Découvrir comment ça marche',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: const [
            Icon(Icons.location_on_outlined, color: Color(0xFF7D7668)),
            SizedBox(width: 6),
            Text(
              'Explorer des articles proches de chez toi',
              style: TextStyle(
                color: Color(0xFF6A6359),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroImage({required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9E1D8)),
        ),
        child: Image.network(
          'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?auto=format&fit=crop&w=900&q=80',
          height: height,
          width: height * 0.82,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, color: _primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Rechercher des vêtements ou marques...',
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
              ),
            ),
            TextButton(
              onPressed: _performSearch,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Chercher'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _searchController.text.trim().toLowerCase() ==
              category.toLowerCase();
          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => _selectCategory(category),
            selectedColor: _primaryBlue.withOpacity(0.12),
            checkmarkColor: _primaryBlue,
            labelStyle: TextStyle(
              color: isSelected ? _primaryBlue : Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: isSelected ? _primaryBlue : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}

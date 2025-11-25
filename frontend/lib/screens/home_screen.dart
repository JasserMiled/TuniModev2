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
  static const Color _lightBackground = Color(0xFFF7F9FC);
  static const Color _accentGreen = Color(0xFF24B072);
  static const Color _lavender = Color(0xFFF1EDFD);
  static const Color _peach = Color(0xFFFFF4EC);

  late Future<List<Listing>> _futureListings;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = const [
    'Femmes',
    'Hommes',
    'Enfants',
    'Chaussures',
    'Accessoires',
  ];

  @override
  void initState() {
    super.initState();
    _futureListings = ApiService.fetchListings();
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
        titleSpacing: 16,
        toolbarHeight: 86,
        backgroundColor: _lightBackground,
        surfaceTintColor: _lightBackground,
        elevation: 0.3,
        shadowColor: Colors.black12,
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: _primaryBlue),
            const SizedBox(width: 8),
            const Text(
              'TuniMode',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(child: _buildSearchBar()),
            TextButton(
              onPressed: _openLogin,
              child: const Text('Se connecter'),
            ),
            const SizedBox(width: 6),
            const SizedBox(width: 12),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openDashboard,
        icon: const Icon(Icons.store),
        label: const Text('Espace Pro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryChips(),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 7,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=1400&q=80',
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, _, __) {
                            return Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported, size: 40),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Style, seconde main et coups de cœur',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Parcourez les annonces inspirantes près de chez vous.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Listing>>(
                future: _futureListings,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Erreur : ${snapshot.error}'),
                      ),
                    );
                  }
                  final listings = snapshot.data ?? [];
                  if (listings.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Aucune annonce pour le moment.')),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Derniers articles mis en ligne',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choisis tes prochaines trouvailles parmi des milliers de vêtements et accessoires.',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 280,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: listings.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final listing = listings[index];
                            return SizedBox(
                              width: 170,
                              child: ListingCard(
                                listing: listing,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ListingDetailScreen(
                                        listingId: listing.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.search, color: _primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Rechercher une marque, une tendance ou une taille...',
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: _lavender,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: const [
                  Icon(Icons.filter_alt_outlined, color: _primaryBlue, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Filtres rapides',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: _performSearch,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  Widget _buildHighlights() {
    final cards = [
      _Highlight(
        icon: Icons.new_releases_rounded,
        label: 'Nouveautés quotidiennes',
        color: _lavender,
      ),
      _Highlight(
        icon: Icons.favorite_border,
        label: 'Coups de cœur de la communauté',
        color: _peach,
      ),
      _Highlight(
        icon: Icons.verified_user_outlined,
        label: 'Transactions sécurisées',
        color: Colors.white,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cards
            .map(
              (card) => Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: card.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(card.icon, color: _primaryBlue, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      card.label,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Derniers articles mis en ligne',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          'Mis à jour en temps réel',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Highlight {
  final IconData icon;
  final String label;
  final Color color;

  const _Highlight({
    required this.icon,
    required this.label,
    required this.color,
  });
}

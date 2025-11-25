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
  late Future<List<Listing>> _futureListings;
  final TextEditingController _searchController = TextEditingController();

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
      appBar: AppBar(
        title: const Text('TuniMode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _openLogin,
          ),
        ],
      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openDashboard,
          icon: const Icon(Icons.store),
          label: const Text('Espace Pro'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Débarrasse-toi du superflu, inspire la communauté,\n'
                'et trouve les bonnes affaires près de chez toi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Rechercher une annonce',
                  suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
            ),
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
                    return const Center(child: Text('Aucune annonce pour le moment.'));
                  }
                  return ListView.builder(
                    itemCount: listings.length,
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
    );
  }
}

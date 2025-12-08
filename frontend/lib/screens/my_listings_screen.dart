import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/api_service.dart';
import '../services/search_navigation_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/tunimode_app_bar.dart';
import '../widgets/tunimode_drawer.dart';
import '../widgets/auth_guard.dart';
import '../widgets/quick_filters_launcher.dart';

import '../widgets/quick_filters_launcher.dart';
class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late Future<List<Listing>> _listingsFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listingsFuture = ApiService.fetchMyListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    SearchNavigationService.openSearchResults(
      context: context,
      query: query,
    );
  }

  Future<void> _refresh() async {
    final next = ApiService.fetchMyListings();
    setState(() {
      _listingsFuture = next;
    });
    await next;
  }

  void _openListing(Listing listing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(listingId: listing.id),
      ),
    ).then((updated) {
      if (updated == true) {
        _refresh();
      }
    });
  }

  Widget _buildListingsGrid(List<Listing> listings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1100, // 👈 identique à SearchResultsScreen
            ),
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // 👈 même grille fixée
                crossAxisSpacing: 24,
                mainAxisSpacing: 32,
                childAspectRatio: 0.70, // 👈 même ratio que Search
              ),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                return ListingCard(
                  listing: listing,
                  onTap: () => _openListing(listing),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<Listing>>(
      future: _listingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Une erreur est survenue lors du chargement de vos annonces.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Réessayer'),
                  )
                ],
              ),
            ),
          );
        }

        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "Vous n'avez pas encore publié d'annonce. Vos annonces apparaîtront ici.",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final onlineListings =
            listings.where((listing) => !listing.isDeleted).toList();
        final deletedListings =
            listings.where((listing) => listing.isDeleted).toList();

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'En ligne'),
                  Tab(text: 'Supprimée'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    RefreshIndicator(
                      onRefresh: _refresh,
                      child: onlineListings.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Aucune annonce en ligne pour le moment.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : _buildListingsGrid(onlineListings),
                    ),
                    RefreshIndicator(
                      onRefresh: _refresh,
                      child: deletedListings.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Aucune annonce supprimée.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : _buildListingsGrid(deletedListings),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      builder: (context) => Scaffold(
        drawer: const TuniModeDrawer(),
        appBar: TuniModeAppBar(
          showSearchBar: true,
          searchController: _searchController,
          onSearch: _handleSearch,
          onQuickFilters: () => openQuickFiltersAndNavigate(
            context: context,
            searchQuery: _searchController.text,
            primaryColor: const Color(0xFF0B6EFE),
          ),
          actions: const [
            AccountMenuButton(),
            SizedBox(width: 8),
          ],
        ),

        body: _buildBody(),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/listing.dart';
import '../services/api_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late Future<List<Listing>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = ApiService.fetchMyListings();
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

        return RefreshIndicator(
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columnCount = width >= 1400
                  ? 5
                  : width >= 1100
                      ? 4
                      : width >= 800
                          ? 3
                          : width >= 520
                              ? 2
                              : 1;

              return MasonryGridView.count(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                crossAxisCount: columnCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: listings.length,
                itemBuilder: (context, index) => ListingCard(
                  listing: listings[index],
                  onTap: () => _openListing(listings[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes annonces')),
      body: _buildBody(),
    );
  }
}

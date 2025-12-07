import 'package:flutter/material.dart';

import '../screens/search_results_screen.dart';

class SearchNavigationService {
  static void openSearchResults({
    required BuildContext context,
    required String query,
  }) {
    final trimmedQuery = query.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(initialQuery: trimmedQuery),
      ),
    );
  }
}

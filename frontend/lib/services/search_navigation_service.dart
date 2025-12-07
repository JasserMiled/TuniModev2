import 'package:flutter/material.dart';

import '../screens/search_results_screen.dart';

class SearchNavigationService {
  static void openSearchResults({
    required BuildContext context,
    required String query,
  }) {
    final trimmedQuery = query.trim();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            SearchResultsScreen(initialQuery: trimmedQuery),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

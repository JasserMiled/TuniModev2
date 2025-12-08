import 'package:flutter/material.dart';

import '../models/category.dart';
import '../screens/search_results_screen.dart';
import '../services/api_service.dart';
import 'quick_filters_dialog.dart';

Future<void> openQuickFiltersAndNavigate({
  required BuildContext context,
  required String searchQuery,
  String? initialCity,
  double? initialMinPrice,
  double? initialMaxPrice,
  int? initialCategoryId,
  List<String>? initialSizes,
  List<String>? initialColors,
  bool? initialDeliveryAvailable,
  Color primaryColor = const Color(0xFF0B6EFE),
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _QuickFiltersDialogWrapper(
      searchQuery: searchQuery,
      initialCity: initialCity,
      initialMinPrice: initialMinPrice,
      initialMaxPrice: initialMaxPrice,
      initialCategoryId: initialCategoryId,
      initialSizes: initialSizes ?? const [],
      initialColors: initialColors ?? const [],
      initialDeliveryAvailable: initialDeliveryAvailable,
      primaryColor: primaryColor,
    ),
  );
}

class _QuickFiltersDialogWrapper extends StatefulWidget {
  final String searchQuery;
  final String? initialCity;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final int? initialCategoryId;
  final List<String> initialSizes;
  final List<String> initialColors;
  final bool? initialDeliveryAvailable;
  final Color primaryColor;

  const _QuickFiltersDialogWrapper({
    required this.searchQuery,
    required this.initialCity,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.initialCategoryId,
    required this.initialSizes,
    required this.initialColors,
    required this.initialDeliveryAvailable,
    required this.primaryColor,
  });

  @override
  State<_QuickFiltersDialogWrapper> createState() =>
      _QuickFiltersDialogWrapperState();
}

class _QuickFiltersDialogWrapperState
    extends State<_QuickFiltersDialogWrapper> {
  List<Category> _categoryTree = [];
  bool _isLoadingCategories = true;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.fetchCategoryTree();
      if (!mounted) return;
      setState(() {
        _categoryTree = categories;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoryError = 'Impossible de charger les catégories';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  void _goToSearchResults(QuickFiltersSelection selection) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SearchResultsScreen(
          initialQuery: widget.searchQuery.trim(),
          initialCity: selection.city,
          initialMinPrice: selection.minPrice,
          initialMaxPrice: selection.maxPrice,
          initialCategoryId: selection.categoryId,
          initialSizes: selection.sizes,
          initialColors: selection.colors,
          initialDeliveryAvailable: selection.deliveryAvailable,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCategories) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return QuickFiltersDialog(
      categoryTree: _categoryTree,
      isLoadingCategories: false,
      categoryLoadError: _categoryError,
      initialCity: widget.initialCity,
      initialMinPrice: widget.initialMinPrice,
      initialMaxPrice: widget.initialMaxPrice,
      initialCategoryId: widget.initialCategoryId,
      initialSizes: widget.initialSizes,
      initialColors: widget.initialColors,
      initialDeliveryAvailable: widget.initialDeliveryAvailable,
      primaryColor: widget.primaryColor,
      onApply: _goToSearchResults,
      onReset: () => _goToSearchResults(
        const QuickFiltersSelection(
          city: null,
          minPrice: null,
          maxPrice: null,
          categoryId: null,
          sizes: [],
          colors: [],
          deliveryAvailable: null,
        ),
      ),
    );
  }
}

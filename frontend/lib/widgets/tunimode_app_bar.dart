import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TuniModeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback? onQuickFilters;
  final String hintText;

  static const Color _primaryBlue = Color(0xFF0B6EFE);
  static const Color _lavender = Color(0xFFF1EDFD);

  const TuniModeSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onQuickFilters,
    this.hintText = 'Rechercher...',
  });

  void _handleSearch() {
    onSearch(controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
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
                controller: controller,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hintText,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _handleSearch(),
              ),
            ),
            InkWell(
              onTap: onQuickFilters,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: onQuickFilters == null ? Colors.grey.shade200 : _lavender,
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
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: _handleSearch,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
}

class TuniModeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onQuickFilters;
  final List<Widget> actions;
  final bool showSearchBar;
  final bool showBackButton;
  final String hintText;
  final Widget? customTitle;

  const TuniModeAppBar({
    super.key,
    this.searchController,
    this.onSearch,
    this.onQuickFilters,
    this.actions = const [],
    this.showSearchBar = false,
    this.showBackButton = false,
    this.hintText = 'Rechercher...',
    this.customTitle,
  }) : assert(
          showSearchBar == false ||
              (searchController != null && onSearch != null),
          'searchController and onSearch are required when showSearchBar is true',
        );

  @override
  Size get preferredSize => const Size.fromHeight(90);

  void _goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final middleContent = showSearchBar
        ? Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TuniModeSearchBar(
                controller: searchController!,
                onSearch: onSearch!,
                onQuickFilters: onQuickFilters,
                hintText: hintText,
              ),
            ),
          )
        : (customTitle != null
            ? Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: customTitle,
                  ),
                ),
              )
            : const SizedBox.shrink());

    return AppBar(
      backgroundColor: const Color(0xFFF7F9FC),
      surfaceTintColor: Colors.white,
      elevation: 0.3,
      toolbarHeight: preferredSize.height,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: showBackButton ? 180 : 140,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            if (showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            GestureDetector(
              onTap: () => _goHome(context),
              child: SizedBox(
                height: 80,
                child: SvgPicture.asset(
                  'assets/images/tunimode_logo.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          middleContent,
        ],
      ),
      actions: [
        ...actions,
        const SizedBox(width: 16),
      ],
    );
  }
}

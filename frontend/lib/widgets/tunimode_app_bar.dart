import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/home_screen.dart';
import 'tunimode_search_bar.dart';

class TuniModeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onQuickFilters;
  final List<Widget> actions;
  final bool showSearchBar;
  final bool showBackButton;
  final String hintText;
  final Widget? customTitle;
  final PreferredSizeWidget? bottom;

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
    this.bottom,
  }) : assert(
          showSearchBar == false ||
              (searchController != null && onSearch != null),
        );

  @override
  Size get preferredSize =>
      Size.fromHeight(70 + (bottom?.preferredSize.height ?? 0));

  void _goHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double searchWidth;
    if (screenWidth < 600) {
      searchWidth = screenWidth * 0.9; // mobile
    } else if (screenWidth < 1200) {
      searchWidth = 700; // tablette
    } else {
      searchWidth = 1500; // desktop
    }

    return AppBar(
      backgroundColor: const Color(0xFFF7F9FC),
      surfaceTintColor: Colors.white,
      elevation: 0.3,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      bottom: bottom,
      // ✅ ON NE UTILISE PLUS titleSpacing
      title: SizedBox(
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ✅ BARRE DE RECHERCHE VRAIMENT CENTRÉE
            if (showSearchBar)
              Center(
                child: SizedBox(
                  width: searchWidth,
                  child: TuniModeSearchBar(
                    controller: searchController!,
                    onSearch: onSearch!,
                    onQuickFilters: onQuickFilters,
                    hintText: hintText,
                  ),
                ),
              ),

            // ✅ LOGO À GAUCHE
            Positioned(
              left: 12,
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      final scaffoldState = Scaffold.maybeOf(context);
                      final hasDrawer = scaffoldState?.hasDrawer ?? false;

                      return IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed:
                            hasDrawer ? () => scaffoldState!.openDrawer() : null,
                        tooltip: 'Menu',
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  if (showBackButton)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  GestureDetector(
                    onTap: () => _goHome(context),
                    child: SizedBox(
                      width: 120,
                      height: 40,
                      child: SvgPicture.asset(
                        'assets/images/tunimode_logo.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ ACTIONS À DROITE
            Positioned(
              right: 12,
              child: Row(
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
title: LayoutBuilder(
  builder: (context, constraints) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ✅ GAUCHE : MENU + BACK
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) {
                  final scaffoldState = Scaffold.maybeOf(context);
                  final hasDrawer = scaffoldState?.hasDrawer ?? false;

                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed:
                        hasDrawer ? () => scaffoldState!.openDrawer() : null,
                  );
                },
              ),

              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
            ],
          ),
        ),

        // ✅ CENTRE : LOGO + SEARCH BAR
        if (showSearchBar)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ LOGO JUSTE AVANT LE CHAMP
                GestureDetector(
                  onTap: () => _goHome(context),
                  child: SizedBox(
                    width: 110,
                    height: 25,
                    child: SvgPicture.asset(
                      'assets/images/tunimode_logo.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ✅ SEARCH BAR (LARGEUR LIMITÉE)
                SizedBox(
                  width: 1200, // ✅ largeur contrôlée au centre
                  child: TuniModeSearchBar(
                    controller: searchController!,
                    onSearch: onSearch!,
                    onQuickFilters: onQuickFilters,
                    hintText: hintText,
                  ),
                ),
              ],
            ),
          ),

        // ✅ DROITE : ACTIONS
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: actions,
          ),
        ),
      ],
    );
  },
),

    );
  }
}

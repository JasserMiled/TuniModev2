import 'package:flutter/material.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 360;
        final isVerySmall = constraints.maxWidth < 300;

        return Center( // ✅ CENTRAGE AUTOMATIQUE
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1500, // ✅ LARGEUR MAX DU CADRE ROUGE
            ),
            child: Row(
              children: [
                // ✅ TEXTFIELD PLUS ÉTROIT
                Expanded(
                  flex: 13,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade50),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              color: _primaryBlue, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Rechercher...',
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8),
                              ),
                              onSubmitted: (_) => _handleSearch(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ✅ BOUTON PLUS LARGE
                Material(
  elevation: 2,
  borderRadius: BorderRadius.circular(10),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Row(
      mainAxisSize: MainAxisSize.min, // ✅ largeur exacte du contenu
      children: [
        if (onQuickFilters != null)
          InkWell(
            onTap: onQuickFilters,
            child: Container(
              height: 40,
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 12 : 42,
              ),
              color: _lavender,
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt_outlined,
                    size: 16,
                    color: _primaryBlue,
                  ),
                  if (!isSmall) ...[
                    const SizedBox(width: 6),
                    const Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

        Container(
          width: 1,
          height: 40,
          color: Colors.white.withOpacity(0.7),
        ),

        InkWell(
          onTap: _handleSearch,
          child: Container(
            height: 40,
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmall ? 14 : 42,
            ),
            color: _primaryBlue,
            child: Center(
              child: isVerySmall
                  ? const Icon(Icons.search,
                      color: Colors.white, size: 18)
                  : const Text(
                      'Chercher',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    ),
  ),
),

              ],
            ),
          ),
        );
      },
    );
  }
}

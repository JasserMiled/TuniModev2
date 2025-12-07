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
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 50, // ✅ hauteur parfaite pour AppBar
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.search, color: _primaryBlue, size: 20),
            const SizedBox(width: 10),

            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: hintText,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _handleSearch(),
              ),
            ),

            if (onQuickFilters != null) ...[
              const SizedBox(width: 10),

              InkWell(
                onTap: onQuickFilters,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: _lavender,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.filter_alt_outlined,
                          color: _primaryBlue, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Filtres',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(width: 10),

            SizedBox(
              height: 34,
              child: TextButton(
                onPressed: _handleSearch,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _primaryBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Chercher',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

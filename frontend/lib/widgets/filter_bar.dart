import 'package:flutter/material.dart';

class FilterDropdownConfig {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const FilterDropdownConfig({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });
}

class FilterBar extends StatelessWidget {
  final List<FilterDropdownConfig> dropdowns;
  final List<Widget> activeFilters;
  final VoidCallback onClearFilters;

  const FilterBar({
    super.key,
    required this.dropdowns,
    required this.activeFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dropdowns
                  .map(
                    (config) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          value: config.value,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: config.label,
                            prefixIcon: Icon(config.icon, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: config.options
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                ),
                              )
                              .toList(),
                          onChanged: config.onChanged,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: activeFilters.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Aucun filtre actif',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: activeFilters,
                      ),
              ),
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.close),
                label: const Text('Effacer les filtres'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

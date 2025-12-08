import 'package:flutter/material.dart';

class FilterDropdownOption {
  final String value;
  final String label;

  const FilterDropdownOption({
    required this.value,
    required this.label,
  });
}

class FilterDropdownConfig {
  final String label;
  final IconData icon;
  final String? value;
  final List<FilterDropdownOption> options;
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
  final List<Widget> customDropdowns;
  final List<Widget> activeFilters;
  final VoidCallback onClearFilters;

  const FilterBar({
    super.key,
    required this.dropdowns,
    this.customDropdowns = const [],
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...customDropdowns,
              ...dropdowns
                  .map(
                    (config) => _FilterDropdown(config: config),
                  )
                  .toList(),
            ],
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

class _FilterDropdown extends StatelessWidget {
  final FilterDropdownConfig config;

  const _FilterDropdown({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 200),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: config.value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          hint: Row(
            children: [
              Icon(config.icon, size: 18, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                config.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          selectedItemBuilder: (context) => config.options
              .map(
                (option) => Row(
                  children: [
                    Icon(config.icon, size: 18, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
          items: config.options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(option.label),
                ),
              )
              .toList(),
          onChanged: config.onChanged,
        ),
      ),
    );
  }
}

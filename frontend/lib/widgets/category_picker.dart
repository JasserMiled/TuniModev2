import 'package:flutter/material.dart';

import '../models/category.dart';

IconData _iconForCategoryName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('femme') || lower.contains('robe')) {
    return Icons.checkroom_outlined;
  }
  if (lower.contains('homme')) {
    return Icons.person_outline;
  }
  if (lower.contains('chauss')) {
    return Icons.hiking_outlined;
  }
  if (lower.contains('sac') || lower.contains('bag')) {
    return Icons.shopping_bag_outlined;
  }
  if (lower.contains('access')) {
    return Icons.watch_outlined;
  }
  if (lower.contains('enfant')) {
    return Icons.child_friendly;
  }
  return Icons.category_outlined;
}

Category? _findCategoryById(List<Category> categories, int id) {
  for (final category in categories) {
    if (category.id == id) return category;
    final child = _findCategoryById(category.children, id);
    if (child != null) return child;
  }
  return null;
}

List<Category> _pathToCategory(List<Category> categories, int id) {
  for (final category in categories) {
    if (category.id == id) return [category];
    final childPath = _pathToCategory(category.children, id);
    if (childPath.isNotEmpty) {
      return [category, ...childPath];
    }
  }
  return [];
}

String? categoryLabelForId(List<Category> categories, int id) {
  final path = _pathToCategory(categories, id);
  if (path.isEmpty) return null;
  return path.map((c) => c.name).join(' › ');
}

Future<Category?> showCategoryPickerDialog({
  required BuildContext context,
  required List<Category> categories,
  int? initialCategoryId,
}) {
  final controller = TextEditingController();
  var currentCategories = categories;
  final path = <Category>[];
  Category? selectedCategory =
      initialCategoryId == null ? null : _findCategoryById(categories, initialCategoryId);

  return showDialog<Category>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final visibleCategories = currentCategories
                .where(
                  (category) => category.name
                      .toLowerCase()
                      .contains(controller.text.toLowerCase()),
                )
                .toList();

            final pathLabel = path.isEmpty ? 'Catégories' : path.last.name;

            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Choisir une catégorie',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(selectedCategory),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (path.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              path.removeLast();
                              currentCategories =
                                  path.isEmpty ? categories : path.last.children;
                              controller.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_back),
                                const SizedBox(width: 12),
                                Text(
                                  pathLabel,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Trouver une catégorie',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (selectedCategory != null)
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Sélectionné : ${selectedCategory!.name}',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(null),
                                        child: const Text('Réinitialiser'),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                              ],
                            ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 320),
                            child: visibleCategories.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(child: Text('Aucune catégorie trouvée')),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: visibleCategories.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final category = visibleCategories[index];
                                      final hasChildren = category.children.isNotEmpty;
                                      final isSelected = selectedCategory?.id == category.id;

                                      return ListTile(
                                        leading: Icon(
                                          _iconForCategoryName(category.name),
                                          color: Colors.teal.shade600,
                                        ),
                                        title: Text(category.name),
                                        trailing: hasChildren
                                            ? const Icon(Icons.chevron_right)
                                            : (isSelected
                                                ? const Icon(Icons.check, color: Colors.green)
                                                : null),
                                        onTap: hasChildren
                                            ? () {
                                                setState(() {
                                                  path.add(category);
                                                  currentCategories = category.children;
                                                  controller.clear();
                                                });
                                              }
                                            : () =>
                                                Navigator.of(dialogContext).pop(category),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

class CategoryPickerField extends StatelessWidget {
  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<Category?> onSelected;
  final bool isLoading;
  final String hintText;
  final String? label;
  final bool showLabel;

  const CategoryPickerField({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    this.isLoading = false,
    this.hintText = 'Toutes les catégories',
    this.label,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLabel = selectedCategoryId == null
        ? null
        : categoryLabelForId(categories, selectedCategoryId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label != null) ...[
          Text(
            label!,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: isLoading
              ? null
              : () async {
                  final category = await showCategoryPickerDialog(
                    context: context,
                    categories: categories,
                    initialCategoryId: selectedCategoryId,
                  );
                  onSelected(category);
                },
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.category_outlined),
              suffixIcon: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(
                      selectedCategoryId != null
                          ? Icons.check_circle
                          : Icons.keyboard_arrow_down_rounded,
                      color: selectedCategoryId != null ? Colors.green : null,
                    ),
              hintText: hintText,
            ),
            isEmpty: selectedCategoryId == null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                selectedLabel ?? hintText,
                style: TextStyle(
                  color: selectedLabel == null ? Colors.grey.shade600 : Colors.black,
                  fontWeight:
                      selectedLabel == null ? FontWeight.w500 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

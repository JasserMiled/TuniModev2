class Category {
  final int id;
  final String name;
  final String slug;
  final int? parentId;
  final List<Category> children;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List<dynamic>?;
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      parentId: json['parent_id'] as int?,
      children: rawChildren == null
          ? const []
          : rawChildren
              .map((child) => Category.fromJson(child as Map<String, dynamic>))
              .toList(),
    );
  }
}

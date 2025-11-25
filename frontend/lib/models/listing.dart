class Listing {
  final int id;
  final String title;
  final String? description;
  final double price;
  final List<String> sizes;
  final List<String> colors;
  final String? gender;
  final String? condition;
  final String? city;
  final String? categoryName;
  final String? sellerName;
  final List<String> imageUrls;

  Listing({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.sizes = const [],
    this.colors = const [],
    this.gender,
    this.condition,
    this.city,
    this.categoryName,
    this.sellerName,
    this.imageUrls = const [],
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    final rawPrice = json["price"];

    double parsedPrice;

    if (rawPrice is num) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice is String) {
      parsedPrice = double.tryParse(rawPrice) ?? 0.0;
    } else {
      parsedPrice = 0.0;
    }

    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      if (value is String) {
        return value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    List<String> parseImages(dynamic value) {
      if (value is List) {
        final parsed = value
            .map((item) {
              if (item is String) {
                return {'url': item, 'order': 0};
              }
              if (item is Map<String, dynamic>) {
                final url = item["url"];
                final sortOrder = item["sort_order"] ?? item["sortOrder"];

                if (url != null) {
                  return {
                    'url': url.toString(),
                    'order': sortOrder is num ? sortOrder.toInt() : 0,
                  };
                }
              }
              return null;
            })
            .whereType<Map<String, dynamic>>()
            .where((item) => (item['url'] as String).trim().isNotEmpty)
            .toList();

        parsed.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
        return parsed.map((item) => item['url'] as String).toList();
      }
      return [];
    }

    return Listing(
      id: json["id"] as int,
      title: json["title"] as String,
      description: json["description"] as String?,
      price: parsedPrice,
      sizes: parseStringList(json["sizes"]),
      colors: parseStringList(json["colors"]),
      gender: json["gender"] as String?,
      condition: json["condition"] as String?,
      city: json["city"] as String?,
      categoryName: json["category_name"] as String?,
      sellerName: json["seller_name"] as String?,
      imageUrls: parseImages(json["images"] ?? json["imageUrls"]),
    );
  }
}

class Listing {
  final int id;
  final String title;
  final String? description;
  final double price;
  final String? size;
  final String? color;
  final String? condition;
  final String? city;
  final String? categoryName;
  final String? sellerName;

  Listing({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.size,
    this.color,
    this.condition,
    this.city,
    this.categoryName,
    this.sellerName,
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

  return Listing(
    id: json["id"] as int,
    title: json["title"] as String,
    description: json["description"] as String?,
    price: parsedPrice,
    size: json["size"] as String?,
    color: json["color"] as String?,
    condition: json["condition"] as String?,
    city: json["city"] as String?,
    categoryName: json["category_name"] as String?,
    sellerName: json["seller_name"] as String?,
  );
  }
}

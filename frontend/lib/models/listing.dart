import 'dart:convert';

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
  final bool deliveryAvailable;
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
    this.deliveryAvailable = false,
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
      List<dynamic> rawList;

      if (value is String && value.trim().isNotEmpty) {
        // Accept either a comma-separated list of URLs or a serialized JSON array
        // so we can keep showing images even if the API shape drifts.
        if (value.trim().startsWith('[')) {
          rawList = (jsonDecode(value) as List<dynamic>);
        } else {
          rawList = value
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } else if (value is List) {
        rawList = value;
      } else {
        return [];
      }

      final parsed = <Map<String, dynamic>>[];

      for (var i = 0; i < rawList.length; i++) {
        final item = rawList[i];

        if (item is String) {
          parsed.add({
            'url': item,
            'order': i,
            'index': i,
          });
          continue;
        }

        if (item is Map<String, dynamic>) {
          final url = item["url"] ?? item["image"] ?? item["path"];
          final sortOrder = item["sort_order"] ?? item["sortOrder"] ?? item["order"];

          if (url != null) {
            final parsedOrder = sortOrder is num
                ? sortOrder.toInt()
                : int.tryParse(sortOrder?.toString() ?? "");

            parsed.add({
              'url': url.toString(),
              'order': parsedOrder ?? i,
              'index': i,
            });
          }
        }
      }

      parsed.retainWhere((item) => (item['url'] as String).trim().isNotEmpty);

      parsed.sort((a, b) {
        final orderCompare = (a['order'] as int).compareTo(b['order'] as int);
        if (orderCompare != 0) return orderCompare;
        return (a['index'] as int).compareTo(b['index'] as int);
      });

      return parsed.map((item) => item['url'] as String).toList();
    }

    bool parseDeliveryAvailable(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }
      return false;
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
      deliveryAvailable: parseDeliveryAvailable(json["delivery_available"]),
      categoryName: json["category_name"] as String?,
      sellerName: json["seller_name"] as String?,
      imageUrls: parseImages(json["images"] ?? json["imageUrls"]),
    );
  }
}

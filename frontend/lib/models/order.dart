class Order {
  final int id;
  final int listingId;
  final String listingTitle;
  final int quantity;
  final double totalAmount;
  final String status;
  final String receptionMode;
  final DateTime createdAt;
  final int? sellerId;
  final String? sellerName;
  final int? buyerId;
  final String? buyerName;
  final String? color;
  final String? size;
  final String? shippingAddress;
  final String? phone;
  final String? buyerNote;

  Order({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.quantity,
    required this.totalAmount,
    required this.status,
    required this.receptionMode,
    required this.createdAt,
    this.sellerId,
    this.sellerName,
    this.buyerId,
    this.buyerName,
    this.color,
    this.size,
    this.shippingAddress,
    this.phone,
    this.buyerNote,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    double _parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '0') ?? 0;
    }

    int _parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '0') ?? 0;
    }

    int? _parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return Order(
      id: _parseInt(json['id']),
      listingId: _parseInt(json['listing_id']),
      listingTitle: json['listing_title']?.toString() ?? 'Annonce',
      quantity: _parseInt(json['quantity']),
      totalAmount: _parseAmount(json['total_amount']),
      status: json['status']?.toString() ?? 'pending',
      receptionMode: json['reception_mode']?.toString() ?? 'retrait',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      sellerId: _parseNullableInt(json['seller_id'] ?? json['sellerId']),
      sellerName: json['seller_name']?.toString(),
      buyerId: _parseNullableInt(json['buyer_id'] ?? json['buyerId']),
      buyerName: json['buyer_name']?.toString(),
      color: json['color']?.toString(),
      size: json['size']?.toString(),
      shippingAddress: json['shipping_address']?.toString(),
      phone: json['phone']?.toString(),
      buyerNote: json['buyer_note']?.toString(),
    );
  }
}

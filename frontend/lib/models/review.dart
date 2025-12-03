class Review {
  final int id;
  final int orderId;
  final int reviewerId;
  final int revieweeId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? reviewerName;

  Review({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewerName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '0') ?? 0;
    }

    return Review(
      id: _parseInt(json['id']),
      orderId: _parseInt(json['order_id']),
      reviewerId: _parseInt(json['reviewer_id']),
      revieweeId: _parseInt(json['reviewee_id']),
      rating: _parseInt(json['rating']),
      comment: json['comment']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      reviewerName: json['reviewer_name']?.toString(),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/favorites.dart';
import '../models/listing.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:4000';

  static String? resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final normalized = url.startsWith('/') ? url : '/$url';
    return '$baseUrl$normalized';
  }

  static String? authToken;
  static User? currentUser;

  static Map<String, String> _headers({bool withAuth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (withAuth && authToken != null) {
      headers['Authorization'] = 'Bearer ${authToken!}';
    }
    return headers;
  }

  static Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? address,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'address': address,
        'role': role,
      }),
    );

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      currentUser = User.fromJson(data['user']);
      authToken = data['token'];
      return true;
    }
    return false;
  }

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      currentUser = User.fromJson(data['user']);
      authToken = data['token'];
      return true;
    }
    return false;
  }

  static void logout() {
    authToken = null;
    currentUser = null;
  }

  static Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$baseUrl/api/upload/image');
    final request = http.MultipartRequest('POST', uri);
    if (authToken != null) {
      request.headers['Authorization'] = 'Bearer ${authToken!}';
    }
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['url'] as String;
    }

    throw Exception('Échec du téléchargement de la photo de profil');
  }

  static Future<User> updateProfile({
    String? name,
    String? address,
    String? email,
    String? phone,
    String? currentPassword,
    String? newPassword,
    String? avatarUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/me');
    final payload = <String, dynamic>{};

    if (name != null) payload['name'] = name;
    if (address != null) payload['address'] = address;
    if (email != null) payload['email'] = email;
    if (phone != null) payload['phone'] = phone;
    if (currentPassword != null) payload['current_password'] = currentPassword;
    if (newPassword != null) payload['new_password'] = newPassword;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;

    final res = await http.put(
      uri,
      headers: _headers(withAuth: true),
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final updatedUser =
          User.fromJson(data['user'] != null ? data['user'] as Map<String, dynamic> : data);
      currentUser = updatedUser;
      return updatedUser;
    }

    final message = jsonDecode(res.body)['message'] ?? 'Mise à jour impossible';
    throw Exception(message);
  }

  static Future<FavoriteCollections> fetchFavorites() async {
    final uri = Uri.parse('$baseUrl/api/favorites/me');
    final res = await http.get(uri, headers: _headers(withAuth: true));

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger vos favoris');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return FavoriteCollections.fromJson(data);
  }

  static Future<bool> addFavoriteListing(int listingId) async {
    final uri = Uri.parse('$baseUrl/api/favorites/listings/$listingId');
    final res = await http.post(uri, headers: _headers(withAuth: true));
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  static Future<bool> removeFavoriteListing(int listingId) async {
    final uri = Uri.parse('$baseUrl/api/favorites/listings/$listingId');
    final res = await http.delete(uri, headers: _headers(withAuth: true));
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  static Future<bool> addFavoriteSeller(int sellerId) async {
    final uri = Uri.parse('$baseUrl/api/favorites/sellers/$sellerId');
    final res = await http.post(uri, headers: _headers(withAuth: true));
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  static Future<bool> removeFavoriteSeller(int sellerId) async {
    final uri = Uri.parse('$baseUrl/api/favorites/sellers/$sellerId');
    final res = await http.delete(uri, headers: _headers(withAuth: true));
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  static Future<User> fetchUserProfile(int userId) async {
    final uri = Uri.parse('$baseUrl/api/auth/user/$userId');
    final res = await http.get(uri, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger le profil utilisateur');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  static Future<List<Listing>> fetchListings({
    String? query,
    String? gender,
    String? city,
    double? minPrice,
    double? maxPrice,
    int? categoryId,
    List<String>? sizes,
    List<String>? colors,
    bool? deliveryAvailable,
  }) async {
    final queryParams = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }
    if (gender != null && gender.trim().isNotEmpty) {
      queryParams['gender'] = gender.trim().toLowerCase();
    }
    if (city != null && city.trim().isNotEmpty) {
      queryParams['city'] = city.trim();
    }
    if (minPrice != null) {
      queryParams['min_price'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParams['max_price'] = maxPrice.toString();
    }
    if (categoryId != null) {
      queryParams['category_id'] = categoryId.toString();
    }
    if (sizes != null && sizes.isNotEmpty) {
      queryParams['sizes'] = sizes.join(',');
    }
    if (colors != null && colors.isNotEmpty) {
      queryParams['colors'] = colors.join(',');
    }
    if (deliveryAvailable != null) {
      queryParams['delivery_available'] = deliveryAvailable.toString();
    }

    final uri = queryParams.isEmpty
        ? Uri.parse('$baseUrl/api/listings')
        : Uri.parse('$baseUrl/api/listings').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Erreur lors du chargement des annonces');
    }
  }

  static Future<List<Listing>> fetchMyListings() async {
    final uri = Uri.parse('$baseUrl/api/listings/me/mine');
    final res = await http.get(uri, headers: _headers(withAuth: true));

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger vos annonces');
    }

    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Listing> fetchListingDetail(int id) async {
    final uri = Uri.parse('$baseUrl/api/listings/$id');
    final res = await http.get(
      uri,
      headers: _headers(withAuth: authToken != null),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Listing.fromJson(data);
    } else {
      throw Exception('Annonce introuvable');
    }
  }

  static Future<List<Listing>> fetchUserListings(int userId) async {
    final uri = Uri.parse('$baseUrl/api/listings/user/$userId');
    final res = await http.get(uri, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger les annonces de cet utilisateur');
    }

    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> updateListing({
    required int id,
    String? title,
    String? description,
    double? price,
    List<String>? sizes,
    List<String>? colors,
    String? condition,
    int? categoryId,
    String? city,
    bool? deliveryAvailable,
    String? status,
    int? stock,
  }) async {
    final uri = Uri.parse('$baseUrl/api/listings/$id');
    final res = await http.put(
      uri,
      headers: _headers(withAuth: true),
      body: jsonEncode({
        'title': title,
        'description': description,
        'price': price,
        'sizes': sizes,
        'colors': colors,
        'condition': condition,
        'category_id': categoryId,
        'city': city,
        'delivery_available': deliveryAvailable,
        'status': status,
        'stock': stock,
      }),
    );

    return res.statusCode == 200;
  }

  static Future<bool> deleteListing(int id) async {
    final uri = Uri.parse('$baseUrl/api/listings/$id');
    final res = await http.delete(uri, headers: _headers(withAuth: true));

    return res.statusCode == 200;
  }

  static Future<bool> createListing({
    required String title,
    required String description,
    required double price,
    List<String>? sizes,
    List<String>? colors,
    String? condition,
    int? categoryId,
    String? city,
    List<String>? images,
    bool deliveryAvailable = false,
  }) async {
    final uri = Uri.parse('$baseUrl/api/listings');
    final res = await http.post(
      uri,
      headers: _headers(withAuth: true),
      body: jsonEncode({
        'title': title,
        'description': description,
        'price': price,
        'sizes': sizes ?? [],
        'colors': colors ?? [],
        'condition': condition,
        'category_id': categoryId,
        'city': city,
        'delivery_available': deliveryAvailable,
        'images': images ?? [],
      }),
    );

    return res.statusCode == 201;
  }

  static Future<List<Category>> fetchCategoryTree() async {
    final uri = Uri.parse('$baseUrl/api/categories/tree');
    final res = await http.get(uri, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger les catégories');
    }

    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((node) => Category.fromJson(node as Map<String, dynamic>))
        .toList();
  }

  static Future<List<String>> fetchSizesForCategory(int categoryId) async {
    final uri = Uri.parse('$baseUrl/api/sizes?category_id=$categoryId');
    final res = await http.get(uri, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger les tailles');
    }

    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => (e as Map<String, dynamic>)['label']?.toString() ?? '')
        .where((label) => label.isNotEmpty)
        .toList();
  }

  static Future<String?> uploadImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$baseUrl/api/upload/image');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(withAuth: true))
      ..files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: filename),
      );

    // Content-Type is managed by MultipartRequest; remove the JSON header if set.
    request.headers.remove('Content-Type');

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 201) {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      return data['url'] as String?;
    }

    return null;
  }

  static Future<Map<String, dynamic>> createOrder({
    required int listingId,
    required int quantity,
    required String receptionMode,
    String? color,
    String? size,
    String? shippingAddress,
    String? phone,
    String? buyerNote,
  }) async {
    final uri = Uri.parse('$baseUrl/api/orders');
    final res = await http.post(
      uri,
      headers: _headers(withAuth: true),
      body: jsonEncode({
        'listing_id': listingId,
        'quantity': quantity,
        'reception_mode': receptionMode,
        'color': color,
        'size': size,
        'shipping_address': shippingAddress,
        'phone': phone,
        'buyer_note': buyerNote,
      }),
    );

    if (res.statusCode != 201) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Commande impossible';
      throw Exception(errorMessage);
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<Order>> fetchBuyerOrders() async {
    final uri = Uri.parse('$baseUrl/api/orders/me/buyer');
    final res = await http.get(uri, headers: _headers(withAuth: true));

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger vos commandes');
    }

    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Order>> fetchSellerOrders() async {
    final uri = Uri.parse('$baseUrl/api/orders/me/seller');
    final res = await http.get(uri, headers: _headers(withAuth: true));

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger vos demandes de commandes');
    }

    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Order> updateSellerOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final uri = Uri.parse('$baseUrl/api/orders/$orderId/status');
    final res = await http.patch(
      uri,
      headers: _headers(withAuth: true),
      body: jsonEncode({'status': status}),
    );

    if (res.statusCode != 200) {
      final message = jsonDecode(res.body)['message'] ?? 'Mise à jour impossible';
      throw Exception(message);
    }

    return Order.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Order> cancelOrder(int orderId) async {
    final uri = Uri.parse('$baseUrl/api/orders/$orderId/status');
    final res = await http.patch(
      uri,
      headers: _headers(withAuth: true),
      body: jsonEncode({'status': 'cancelled'}),
    );

    if (res.statusCode != 200) {
      final message = jsonDecode(res.body)['message'] ?? 'Impossible d\'annuler la commande';
      throw Exception(message);
    }

    return Order.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Order> confirmOrderReception(int orderId) async {
    final uri = Uri.parse('$baseUrl/api/orders/$orderId/status');
    final res = await http.patch(
      uri,
      headers: _headers(withAuth: true),
      body: jsonEncode({'status': 'received'}),
    );

    if (res.statusCode != 200) {
      final message = jsonDecode(res.body)['message'] ?? 'Impossible de confirmer la réception';
      throw Exception(message);
    }

    return Order.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Order> refuseOrderReception(int orderId) async {
    final uri = Uri.parse('$baseUrl/api/orders/$orderId/status');
    final res = await http.patch(
      uri,
      headers: _headers(withAuth: true),
      body: jsonEncode({'status': 'reception_refused'}),
    );

    if (res.statusCode != 200) {
      final message = jsonDecode(res.body)['message'] ?? 'Impossible de refuser la réception';
      throw Exception(message);
    }

    return Order.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<List<Review>> fetchUserReviews(int userId) async {
    final uri = Uri.parse('$baseUrl/api/reviews/user/$userId');
    final res = await http.get(uri, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger les avis de cet utilisateur');
    }

    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((item) => Review.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Review>> fetchOrderReviews(int orderId) async {
    final uri = Uri.parse('$baseUrl/api/reviews/order/$orderId');
    final res = await http.get(uri, headers: _headers(withAuth: true));

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger les avis de cette commande');
    }

    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((item) => Review.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Review> submitReview({
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    final uri = Uri.parse('$baseUrl/api/reviews');
    final res = await http.post(
      uri,
      headers: _headers(withAuth: true),
      body: jsonEncode({
        'order_id': orderId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (res.statusCode != 201) {
      final message = jsonDecode(res.body)['message'] ??
          'Impossible d\'enregistrer votre avis pour cette commande';
      throw Exception(message);
    }

    return Review.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}

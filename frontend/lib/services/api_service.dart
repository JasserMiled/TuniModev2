import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/listing.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:4000';

  static String? authToken;

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
        'role': role,
      }),
    );

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
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
      authToken = data['token'];
      return true;
    }
    return false;
  }

  static Future<List<Listing>> fetchListings({
    String? query,
    String? gender,
    String? city,
    double? minPrice,
    double? maxPrice,
    int? categoryId,
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

  static Future<Listing> fetchListingDetail(int id) async {
    final uri = Uri.parse('$baseUrl/api/listings/$id');
    final res = await http.get(uri, headers: _headers());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Listing.fromJson(data);
    } else {
      throw Exception('Annonce introuvable');
    }
  }

  static Future<bool> createListing({
    required String title,
    required String description,
    required double price,
    List<String>? sizes,
    List<String>? colors,
    String? gender,
    String? condition,
    int? categoryId,
    String? city,
    List<String>? images,
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
        'gender': gender,
        'condition': condition,
        'category_id': categoryId,
        'city': city,
        'images': images ?? [],
      }),
    );

    return res.statusCode == 201;
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
}

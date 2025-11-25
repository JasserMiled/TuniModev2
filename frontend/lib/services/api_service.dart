import 'dart:convert';
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

  static Future<List<Listing>> fetchListings({String? query}) async {
    final queryParams = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
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
        'images': [],
      }),
    );

    return res.statusCode == 201;
  }
}

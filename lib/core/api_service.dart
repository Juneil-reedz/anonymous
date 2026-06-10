import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String baseUrl = 'https://anonymous-backend-0nnv.onrender.com';

  static String? _token;

  static void setToken(String? token) => _token = token;
  static String? get token => _token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));
      final data = json.decode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) throw data['error'] ?? 'Request failed';
      return data;
    } catch (e) {
      debugPrint('POST $path error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      final data = json.decode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) throw data['error'] ?? 'Request failed';
      return data;
    } catch (e) {
      debugPrint('GET $path error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));
      final data = json.decode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) throw data['error'] ?? 'Request failed';
      return data;
    } catch (e) {
      debugPrint('PUT $path error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      final data = json.decode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) throw data['error'] ?? 'Request failed';
      return data;
    } catch (e) {
      debugPrint('DELETE $path error: $e');
      rethrow;
    }
  }
}

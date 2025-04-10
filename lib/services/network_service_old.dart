import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NetworkService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String?> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url');
  }

  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await _getToken();
    final baseUrl = await _getBaseUrl();

    if (token == null || baseUrl == null) {
      throw Exception('Missing token or base URL');
    }

    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode >= 400) {
      throw Exception('Request failed: ${response.body}');
    }

    return response;
  }
}

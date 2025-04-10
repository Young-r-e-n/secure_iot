import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NetworkService {
  final String baseUrl;
  final String token;

  NetworkService._internal({required this.baseUrl, required this.token});

  /// Use this to create an instance after loading values from SharedPreferences
  static Future<NetworkService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('base_url') ?? '';
    final token = prefs.getString('access_token') ?? '';

    if (baseUrl.isEmpty || token.isEmpty) {
      throw Exception('Missing baseUrl or access token in SharedPreferences');
    }

    return NetworkService._internal(baseUrl: baseUrl, token: token);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> sendControlCommand(String action,
      [Map<String, dynamic>? parameters]) async {
    final response = await http.post(
      Uri.parse('$baseUrl/control'),
      headers: _headers,
      body: jsonEncode({
        'action': action,
        if (parameters != null) 'parameters': parameters,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendAlert(String message,
      {String? videoUrl}) async {
    final body = {
      'message': message,
      if (videoUrl != null) 'video_url': videoUrl,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/alert'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed with status: ${response.statusCode}, body: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getDetailedStatus() async {
  final response = await http.get(
    Uri.parse('$baseUrl/status'),
    headers: _headers,
  );
  return _handleResponse(response);
}

Future<Map<String, dynamic>> getStatus() => getDetailedStatus();


Future<List<Map<String, dynamic>>> getLogs() async {
  final response = await http.get(
    Uri.parse('$baseUrl/logs'),

    headers: _headers,
  );

  if (response.statusCode == 200) {
    print('Raw response body: ${response.body}');

    final decoded = json.decode(response.body);

    if (decoded is Map<String, dynamic> && decoded['logs'] is List) {
      final logsList = decoded['logs'] as List;

      return logsList.map<Map<String, dynamic>>((log) {
        return Map<String, dynamic>.from(log);
      }).toList();
    } else {
      throw Exception('Unexpected response format: Missing "logs" key or incorrect type');
    }
  } else {
    throw Exception('Failed to load logs: ${response.statusCode}');
  }
}


}

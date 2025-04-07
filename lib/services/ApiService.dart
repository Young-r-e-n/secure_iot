import 'dart:convert';
import 'dart:io'; // For HttpStatus
import 'package:http/http.dart' as http;
import '../config.dart'; // Import config

// Removed unused model imports

class ApiService {
  // Use URLs from AppConfig
  final String _serverBaseUrl = AppConfig.serverBaseUrl;
  final String _piBaseUrl = AppConfig.raspberryPiBaseUrl;

  String? _authToken; // Store the auth token

  void setAuthToken(String? token) {
    _authToken = token;
  }

  // --- Helper Methods ---
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken'; // Common practice
    }
    return headers;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return {}; // Return empty map for successful responses with no body (e.g., 204 No Content)
    } else if (response.statusCode == HttpStatus.unauthorized) {
      // Handle unauthorized access, maybe trigger logout
      throw ApiException('Unauthorized', response.statusCode);
    } else {
      // Handle other errors
      String errorMessage = 'API Error';
      if (response.body.isNotEmpty) {
        try {
          final errorBody = json.decode(response.body) as Map<String, dynamic>;
          errorMessage = errorBody['detail'] ?? errorBody['error'] ?? response.body;
        } catch (e) {
          errorMessage = response.body; // Fallback to raw body
        }
      }
      throw ApiException(errorMessage, response.statusCode);
    }
  }

  Future<List<dynamic>> _handleListResponse(http.Response response) async {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          return json.decode(response.body) as List<dynamic>;
        }
        return []; // Return empty list for successful responses with no body
      } else if (response.statusCode == HttpStatus.unauthorized) {
        throw ApiException('Unauthorized', response.statusCode);
      } else {
        String errorMessage = 'API Error';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = json.decode(response.body) as Map<String, dynamic>;
            errorMessage = errorBody['detail'] ?? errorBody['error'] ?? response.body;
          } catch (e) {
            errorMessage = response.body;
          }
        }
        throw ApiException(errorMessage, response.statusCode);
      }
    }

  // --- Server API Methods (Examples) ---

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_serverBaseUrl/auth/login'), // Adjust endpoint as needed
      headers: _getHeaders(),
      body: json.encode({'username': username, 'password': password}),
    );
    // Returns the raw map for AppState to process (extract token, user info)
    return _handleResponse(response);
  }

  Future<List<dynamic>> fetchLogs() async {
    final response = await http.get(
      Uri.parse('$_serverBaseUrl/events'), // Adjust endpoint
      headers: _getHeaders(),
    );
    // Returns list of raw maps for AppState to parse into LogEntry models
    return _handleListResponse(response);
  }

  Future<Map<String, dynamic>> fetchSystemStatus() async {
     final response = await http.get(
       Uri.parse('$_serverBaseUrl/status/system'), // Adjust endpoint
       headers: _getHeaders(),
     );
     // Returns raw map for AppState to parse into SystemStatus model
     return _handleResponse(response);
   }

  // --- NEW: Server API Methods Stubs ---

  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$_serverBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json; charset=UTF-8', 'Accept': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        // Assuming backend derives username or uses email
      }),
    );
    return _handleResponse(response);
  }

  Future<void> postManualAlert(String message) async {
    final response = await http.post(
      Uri.parse('$_serverBaseUrl/events'),
      headers: _getHeaders(), // Requires auth
      body: json.encode({
        'event_type': 'manual_alert',
        'details': { 'message': message },
        'severity': 'warning', // Default severity, backend might adjust
        'source': 'app_manual'
      }),
    );
    _handleResponse(response);
  }

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(
      Uri.parse('$_serverBaseUrl/users'),
      headers: _getHeaders(), // Requires auth (Admin?)
    );
    return _handleListResponse(response);
  }

  Future<void> createUser(String name, String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$_serverBaseUrl/users'),
      headers: _getHeaders(), // Requires auth (Admin?)
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        // Assuming backend derives username or uses email
      }),
    );
    _handleResponse(response); // Check for success/failure
  }

  Future<void> updateUser(int id, String name, String email, String role) async {
    final response = await http.put( // Or PATCH
      Uri.parse('$_serverBaseUrl/users/$id'), // Assuming endpoint format
      headers: _getHeaders(), // Requires auth (Admin?)
      body: json.encode({
        'name': name,
        'email': email,
        'role': role,
      }),
    );
    _handleResponse(response); // Check for success/failure
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$_serverBaseUrl/users/$id'), // Assuming endpoint format
      headers: _getHeaders(), // Requires auth (Admin?)
    );
    _handleResponse(response); // Check for success/failure
  }

  // --- Raspberry Pi API Methods (Examples) ---

  Future<void> sendPiCommand(String command, [Map<String, dynamic>? data]) async {
    // Adjusted to handle more commands and use POST for simplicity
    final String endpoint;
    switch (command.toLowerCase()) {
      case 'lock':
        endpoint = '/lock';
        break;
      case 'unlock':
        endpoint = '/unlock';
        break;
      case 'test_sensors': // Example for a potential command
        endpoint = '/test-sensors';
        break;
      case 'restart_system': // Example for a potential command
        endpoint = '/restart';
        break;
      default:
        print("Warning: Unknown Pi command '$command' in ApiService");
        throw ApiException('Invalid Pi command: $command');
    }

    // Always use POST for commands to Pi API for consistency?
    final response = await http.post(
      Uri.parse('$_piBaseUrl$endpoint'),
      headers: _getHeaders(), // Send auth token to Pi API as well?
      body: data != null ? json.encode(data) : null,
    );
    _handleResponse(response); // Use handler to check status code
  }

   Future<Map<String, dynamic>> fetchPiStatus() async {
     final response = await http.get(
       Uri.parse('$_piBaseUrl/status'), // Assuming this endpoint exists
       headers: _getHeaders(), // Send auth token?
     );
     return _handleResponse(response);
   }

  // TODO: Add methods for register, fetching sensor data, video URLs, etc.
}

// Custom Exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() {
    return "ApiException: $message (Status Code: ${statusCode ?? 'N/A'})";
  }
} 
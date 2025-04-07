import 'dart:async'; // For Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage
import '../models/LogEntry.dart'; // Import LogEntry
import '../models/User.dart'; // Import User
import '../models/system_status.dart'; // Import SystemStatus models
import '../services/ApiService.dart'; // Import ApiService

class AppState with ChangeNotifier {
  final ApiService _apiService = ApiService(); // Instantiate ApiService
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(); // Instantiate secure storage
  static const String _tokenKey = 'auth_token'; // Key for storing token
  static const String _userKey = 'auth_user'; // Key for storing user info

  // State Variables
  bool _isLoading = false;
  bool _isInitializing = true; // Flag for initial auto-login check
  String? _error;
  bool _isAuthenticated = false;
  User? _currentUser;
  SystemStatus? _currentStatus; // Store the detailed system status
  List<LogEntry> _logs = []; // Use typed LogEntry list
  Timer? _statusPollingTimer; // Timer for polling

  // --- User Management State ---
  List<User> _managedUsers = [];
  bool _isLoadingUsers = false;
  String? _userManagementError;

  List<User> get managedUsers => _managedUsers;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get userManagementError => _userManagementError;

  // --- Getters ---
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing; // Expose initialization status
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  SystemStatus? get currentStatus => _currentStatus;
  List<LogEntry> get logs => _logs;
  // Provide specific status parts via getters for easier consumption
  bool get doorLocked => _currentStatus?.sensors['door']?.data?['locked'] ?? false; // Example path
  String get systemStatus => _currentStatus?.status ?? "unknown";
  List<String> get alerts => _currentStatus?.errors ?? []; // Example mapping

  // --- Authentication Methods ---

  // Try to log in automatically using stored token
  Future<void> tryAutoLogin() async {
    _isInitializing = true;
    notifyListeners();
    final storedToken = await _secureStorage.read(key: _tokenKey);
    final storedUserJson = await _secureStorage.read(key: _userKey); // Read user data if stored

    if (storedToken != null && storedUserJson != null) {
      print("Found stored token and user data, attempting auto-login...");
      try {
          _currentUser = User.fromJson(json.decode(storedUserJson)); // Decode stored user data
          _apiService.setAuthToken(storedToken);
          _isAuthenticated = true;
          // Optional: Verify token with a lightweight API call here if needed
          // Example: await _apiService.verifyToken();
          await fetchInitialData();
          startPolling();
          print("Auto-login successful.");
      } catch (e) {
         print("Auto-login failed (error parsing user or verifying token): $e");
         // Clear invalid stored data if verification fails
         await logout(); // Logout will clear storage
      }
    } else {
       print("No stored token/user found for auto-login.");
    }
    _isInitializing = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final responseData = await _apiService.login(username, password);
      _currentUser = User.fromJson(responseData['user']);
      final token = responseData['access_token'] as String?;

      if (token != null && _currentUser != null) {
        _apiService.setAuthToken(token);
        await _secureStorage.write(key: _tokenKey, value: token); // Save token
        await _secureStorage.write(key: _userKey, value: json.encode(_currentUser!.toJson())); // Save user data
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        await fetchInitialData();
        startPolling();
        return true;
      } else {
        throw ApiException('Login failed: Missing token or user data in response');
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      _isAuthenticated = false;
      _currentUser = null;
      _apiService.setAuthToken(null);
      await _secureStorage.delete(key: _tokenKey); // Clear token on failure
      await _secureStorage.delete(key: _userKey); // Clear user data on failure
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    stopPolling();
    _currentUser = null;
    _isAuthenticated = false;
    _apiService.setAuthToken(null);
    _currentStatus = null;
    _logs = [];
    _error = null;
    await _secureStorage.delete(key: _tokenKey); // Clear token on logout
    await _secureStorage.delete(key: _userKey); // Clear user data on logout
    notifyListeners();
    // Optional: Call a server logout endpoint if implemented
    // Example: await _apiService.logout();
  }

  // Method to clear the current error message
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // --- Data Fetching Methods ---
  Future<void> fetchInitialData() async {
    if (!_isAuthenticated) return; // Don't fetch if not logged in
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([
        fetchSystemStatus(),
        fetchLogs(),
      ]);
      _error = null; // Clear error on successful fetch
    } catch (e) {
      _error = 'Failed to load initial data: ${e.toString()}';
      // Decide if partial data is acceptable or clear everything
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSystemStatus() async {
    if (!_isAuthenticated) return;
    try {
      final statusData = await _apiService.fetchSystemStatus();
      _currentStatus = SystemStatus.fromJson(statusData);
      // Potentially update derived state like doorLocked here if needed
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load system status: ${e.toString()}';
      // Consider clearing status on error: _currentStatus = null;
      notifyListeners();
      rethrow; // Re-throw for fetchInitialData to catch
    }
  }

  Future<void> fetchLogs() async {
    if (!_isAuthenticated) return;
    try {
      final logListData = await _apiService.fetchLogs();
      _logs = logListData.map((logJson) => LogEntry.fromJson(logJson as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load logs: ${e.toString()}';
       // Consider clearing logs on error: _logs = [];
      notifyListeners();
      rethrow; // Re-throw for fetchInitialData to catch
    }
  }

  // --- Control Methods ---
  Future<void> executeControlCommand(String piCommand, [Map<String, dynamic>? data]) async {
    if (!_isAuthenticated) return;

    _isLoading = true; // Indicate loading during command execution
    _error = null;
    notifyListeners();

    try {
      await _apiService.sendPiCommand(piCommand, data);
      // Command sent successfully, now refresh status to confirm
      await fetchSystemStatus();
    } catch (e) {
      _error = 'Failed to execute command \'$piCommand\': ${e.toString()}';
      // Consider fetching status again to ensure consistency after error
      await fetchSystemStatus();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Polling for Real-time Updates ---
  void startPolling({Duration interval = const Duration(seconds: 15)}) {
    stopPolling(); // Ensure no duplicate timers run concurrently
    if (!_isAuthenticated) return; // Only poll if logged in

    print("Starting status polling (interval: ${interval.inSeconds} seconds)");
    _statusPollingTimer = Timer.periodic(interval, (timer) {
      print("Polling tick: Fetching system status and logs..."); // Debug log
      // Fetch data without showing global loading indicator or overwriting major errors
      _fetchStatusAndLogsSilently();
    });

     // Fetch immediately on start as well
     _fetchStatusAndLogsSilently();
  }

  // Internal method to fetch data silently without setting isLoading/major error
  Future<void> _fetchStatusAndLogsSilently() async {
    if (!_isAuthenticated) return;
    try {
      // Fetch status and logs concurrently
      await Future.wait([
         _apiService.fetchSystemStatus().then((statusData) {
           if (statusData != null && _statusPollingTimer != null) { // Check if polling is still active
              _currentStatus = SystemStatus.fromJson(statusData);
           }
         }),
         _apiService.fetchLogs().then((logListData) {
           if (logListData != null && _statusPollingTimer != null) { // Check if polling is still active
             _logs = logListData.map((logJson) => LogEntry.fromJson(logJson as Map<String, dynamic>)).toList();
           }
         }),
      ]);
      // Only notify if polling is still active
      if (_statusPollingTimer != null) {
        notifyListeners();
      }
    } catch (e) {
      // Log polling errors but don't necessarily show them prominently
      // unless it's a persistent issue.
      print("Polling Error: Failed to fetch status/logs: ${e.toString()}");
      // Optionally: Implement logic to stop polling after several consecutive errors.
    }
  }

  void stopPolling() {
    if (_statusPollingTimer != null) {
       print("Stopping status polling.");
       _statusPollingTimer?.cancel();
       _statusPollingTimer = null;
    }
  }

  @override
  void dispose() {
    stopPolling(); // Ensure timer is cancelled when AppState is disposed
    super.dispose();
  }

  // --- NEW: Placeholder Methods for AppState ---

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // TODO: Call ApiService.register
      final response = await _apiService.register(name, email, password, role);
      _isLoading = false;
      _error = null;
      // Maybe automatically log in user after successful registration?
      // Or display success message (e.g., store in a temporary state variable)
       _error = response['message'] ?? "Registration Successful!"; // Temporary use error field for success message
      notifyListeners();
      return true; // Assuming API call indicates success
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> postManualAlert(String message) async {
     _isLoading = true; // Consider a separate loading flag for alerts? _isPostingAlert
     _error = null;
     notifyListeners();
     try {
       // TODO: Call ApiService.postManualAlert
       await _apiService.postManualAlert(message);
       _isLoading = false;
       // Maybe refresh status or logs afterwards?
       // await fetchSystemStatus(); 
        _error = "Manual alert posted successfully (simulated)"; // Temp message
       notifyListeners();
     } catch (e) {
       _error = 'Failed to post manual alert: ${e.toString()}';
       _isLoading = false;
       notifyListeners();
     }
  }

  // --- User Management Methods ---
  Future<void> fetchManagedUsers({bool forceRefresh = false}) async {
    // Avoid unnecessary fetches unless forced
    if (_managedUsers.isNotEmpty && !forceRefresh) return;

    _isLoadingUsers = true;
    _userManagementError = null;
    // Use notifyListeners sparingly, only when state actually changes visually
    // notifyListeners(); // Might cause unnecessary rebuilds if called too early
    try {
      final usersData = await _apiService.fetchUsers(); // Call the ApiService method
      _managedUsers = usersData.map((data) => User.fromJson(data as Map<String, dynamic>)).toList();
       _userManagementError = null; // Clear error on success
    } catch (e) {
      _userManagementError = "Failed to fetch users: ${e.toString()}";
      _managedUsers = []; // Clear users on error?
    } finally {
      _isLoadingUsers = false;
      notifyListeners(); // Notify after state changes and loading completes
    }
  }

  Future<bool> createManagedUser({
     required String name,
     required String email,
     required String password,
     required String role,
  }) async {
      _isLoadingUsers = true; // Indicate loading for user list potentially
      _userManagementError = null;
      notifyListeners();
      try {
         await _apiService.createUser(name, email, password, role);
         await fetchManagedUsers(forceRefresh: true); // Refresh list after creating
         return true; // Indicate success
      } catch (e) {
         _userManagementError = "Failed to create user: ${e.toString()}";
         _isLoadingUsers = false;
         notifyListeners();
         return false; // Indicate failure
      }
       // Loading state is handled by fetchManagedUsers finally block
  }

  Future<bool> updateManagedUser({
     required int id,
     required String name,
     required String email,
     required String role,
  }) async {
      _isLoadingUsers = true; 
      _userManagementError = null;
      notifyListeners();
      try {
         await _apiService.updateUser(id, name, email, role);
         await fetchManagedUsers(forceRefresh: true); // Refresh list after updating
         return true;
      } catch (e) {
         _userManagementError = "Failed to update user: ${e.toString()}";
         _isLoadingUsers = false;
         notifyListeners();
         return false;
      }
  }

  Future<bool> deleteManagedUser(int id) async {
     _isLoadingUsers = true; 
     _userManagementError = null;
     notifyListeners();
     try {
        await _apiService.deleteUser(id);
        await fetchManagedUsers(forceRefresh: true); // Refresh list after deleting
        return true;
     } catch (e) {
        _userManagementError = "Failed to delete user: ${e.toString()}";
        _isLoadingUsers = false;
        notifyListeners();
        return false;
     }
  }

  void clearUserManagementError() {
    if (_userManagementError != null) {
      _userManagementError = null;
      notifyListeners();
    }
  }

  // --- Old Mock Methods (Remove or Comment Out) ---
  /*
  Future<void> loadFromJson() async { ... }
  Future<void> loadLogsFromJson() async { ... }
  Future<void> executeControlCommand(String action) async { ... }
  Future<void> postAlert({required String message}) async { ... }
  */
}

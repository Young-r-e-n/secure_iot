import 'dart:convert';
import 'package:flutter/material.dart';

class AppState with ChangeNotifier {
  bool isLoading = true;
  String? error;
  bool doorLocked = false;
  String systemStatus = "unknown";
  List<String> alerts = [];

  // 🚀 Raw logs stored as a list of dynamic maps
  List<Map<String, dynamic>> logs = [];

  Future<void> loadFromJson() async {
    try {
      isLoading = true;
      notifyListeners();

      await Future.delayed(Duration(seconds: 2));
      String jsonResponse = '''{
        "isLoading": false,
        "error": null,
        "controls": {
          "doorLocked": true,
          "systemStatus": "online",
          "alerts": ["Sensor malfunction"]
        }
      }''';

      final data = json.decode(jsonResponse);

      isLoading = data["isLoading"];
      error = data["error"];
      doorLocked = data["controls"]["doorLocked"];
      systemStatus = data["controls"]["systemStatus"];
      alerts = List<String>.from(data["controls"]["alerts"]);

      notifyListeners();
    } catch (e) {
      error = 'Failed to load app state: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLogsFromJson() async {
    try {
      isLoading = true;
      notifyListeners();

      await Future.delayed(Duration(seconds: 1));
      String logsJson = '''[
        {
          "id": 1,
          "event_type": "door_locked",
          "timestamp": "2025-04-05T10:15:00Z",
          "details": {"method": "remote"},
          "user_id": 101,
          "video_url": null,
          "severity": "info",
          "source": "system"
        },
        {
          "id": 2,
          "event_type": "camera_detected_motion",
          "timestamp": "2025-04-05T10:17:30Z",
          "details": {"zone": "front door"},
          "user_id": null,
          "video_url": "http://example.com/video.mp4",
          "severity": "warning",
          "source": "camera"
        }
      ]''';

      final List<dynamic> logList = json.decode(logsJson);
      logs = logList.cast<Map<String, dynamic>>();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = 'Failed to load logs: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> executeControlCommand(String action) async {
    await Future.delayed(Duration(milliseconds: 800));
    switch (action) {
      case 'lock':
        doorLocked = true;
        break;
      case 'unlock':
        doorLocked = false;
        break;
      case 'restart_system':
        systemStatus = "restarting...";
        notifyListeners();
        await Future.delayed(Duration(seconds: 2));
        systemStatus = "online";
        break;
      case 'test_sensors':
        alerts.add("Sensor test triggered at ${DateTime.now()}");
        break;
    }
    notifyListeners();
  }

  Future<void> postAlert({required String message}) async {
    await Future.delayed(Duration(milliseconds: 500));
    alerts.add(message);
    notifyListeners();
  }
}

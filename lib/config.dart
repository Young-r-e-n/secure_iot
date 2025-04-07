// lib/config.dart

class AppConfig {
  // Server API Configuration
  static const String serverScheme = "http";
  static const String serverHost = "localhost"; // Replace with your server's IP/hostname if not localhost
  static const int serverPort = 8000;
  static const String serverApiBasePath = "/api/v1";

  static String get serverBaseUrl => "$serverScheme://$serverHost:$serverPort$serverApiBasePath";

  // Raspberry Pi API Configuration
  static const String raspberryPiScheme = "http";
  // ⬇️ *** IMPORTANT: Replace with your Raspberry Pi's actual IP address ***
  static const String raspberryPiIp = "192.168.100.31"; // <--- REPLACE THIS
  static const int raspberryPiPort = 5000;

  static String get raspberryPiBaseUrl => "$raspberryPiScheme://$raspberryPiIp:$raspberryPiPort";
} 
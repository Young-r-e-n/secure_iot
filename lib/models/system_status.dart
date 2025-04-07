import 'dart:convert'; // Add necessary import

// Removed generator comments

class SensorStatus {
  final String name;
  final bool isActive;
  final DateTime lastCheck;
  final String? error;
  final Map<String, dynamic>? data;
  final String? location;
  final String? type;
  final String? firmwareVersion;
  final DateTime? lastEvent;
  final int eventCount;

  SensorStatus({
    required this.name,
    required this.isActive,
    required this.lastCheck,
    this.error,
    this.data,
    this.location,
    this.type,
    this.firmwareVersion,
    this.lastEvent,
    this.eventCount = 0,
  });

  // Manual fromJson implementation
  factory SensorStatus.fromJson(Map<String, dynamic> json) {
    return SensorStatus(
      name: json['name'] as String,
      isActive: json['isActive'] as bool,
      lastCheck: DateTime.parse(json['last_check'] as String),
      error: json['error'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      location: json['location'] as String?,
      type: json['type'] as String?,
      firmwareVersion: json['firmware_version'] as String?,
      lastEvent: json['last_event'] != null ? DateTime.parse(json['last_event'] as String) : null,
      eventCount: json['event_count'] as int? ?? 0,
    );
  }
}

class RaspberryPiStatus {
  final bool isOnline;
  final DateTime lastHeartbeat;
  final String firmwareVersion;
  final List<String> sensorTypes;
  final int totalEvents;

  RaspberryPiStatus({
    required this.isOnline,
    required this.lastHeartbeat,
    required this.firmwareVersion,
    required this.sensorTypes,
    required this.totalEvents,
  });

  // Manual fromJson implementation
  factory RaspberryPiStatus.fromJson(Map<String, dynamic> json) {
    return RaspberryPiStatus(
      isOnline: json['is_online'] as bool,
      lastHeartbeat: DateTime.parse(json['last_heartbeat'] as String),
      firmwareVersion: json['firmware_version'] as String,
      sensorTypes: (json['sensor_types'] as List<dynamic>).cast<String>(),
      totalEvents: json['total_events'] as int,
    );
  }
}

class SystemStatus {
  final String status;
  final Map<String, SensorStatus> sensors;
  final Map<String, dynamic> storage; // Keeping storage as dynamic map for now
  final String uptime;
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final List<String>? errors;
  final RaspberryPiStatus raspberryPi;

  SystemStatus({
    required this.status,
    required this.sensors,
    required this.storage,
    required this.uptime,
    this.lastMaintenance,
    this.nextMaintenance,
    this.errors,
    required this.raspberryPi,
  });

  // Manual fromJson implementation
  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      status: json['status'] as String,
      sensors: (json['sensors'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, SensorStatus.fromJson(value as Map<String, dynamic>)),
      ),
      storage: json['storage'] as Map<String, dynamic>,
      uptime: json['uptime'] as String,
      lastMaintenance: json['last_maintenance'] != null ? DateTime.parse(json['last_maintenance'] as String) : null,
      nextMaintenance: json['next_maintenance'] != null ? DateTime.parse(json['next_maintenance'] as String) : null,
      errors: (json['errors'] as List<dynamic>?)?.cast<String>(),
      raspberryPi: RaspberryPiStatus.fromJson(json['raspberry_pi'] as Map<String, dynamic>),
    );
  }

  bool get hasErrors => errors != null && errors!.isNotEmpty;
  bool get isHealthy => status == 'healthy'; // Assuming 'healthy' status string
  bool get isDegraded => status == 'degraded'; // Assuming 'degraded' status string
  bool get hasLowStorage => storage['low_space'] == true;
} 
class LogEntry {
  final int id;
  final String eventType;
  final DateTime timestamp;
  final Map<String, dynamic>? details; // Can be nullable or more specific
  final int? userId; // User associated with the event, if any
  final String? videoUrl; // Optional URL for related video
  final String severity; // e.g., info, warning, error, critical
  final String source; // e.g., system, camera, sensor_motion, rfid

  LogEntry({
    required this.id,
    required this.eventType,
    required this.timestamp,
    this.details,
    this.userId,
    this.videoUrl,
    required this.severity,
    required this.source,
  });

  // Manual fromJson based on the example log in AppState
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] as int,
      eventType: json['event_type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      details: json['details'] as Map<String, dynamic>?,
      userId: json['user_id'] as int?,
      videoUrl: json['video_url'] as String?,
      severity: json['severity'] as String? ?? 'info', // Default severity if missing
      source: json['source'] as String? ?? 'unknown', // Default source if missing
    );
  }

  // Optional: toJson if needed
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_type': eventType,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
      'user_id': userId,
      'video_url': videoUrl,
      'severity': severity,
      'source': source,
    };
  }
} 
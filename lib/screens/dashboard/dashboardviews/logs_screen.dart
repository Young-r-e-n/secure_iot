import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart'; // Adjusted import path
import '../../../models/LogEntry.dart'; // ✅ Import LogEntry model

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  // Date formatter
  final DateFormat _logTimestampFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) { // Use toLowerCase for safety
      case 'critical':
        return Colors.red[700]!;
      case 'error':
        return Colors.redAccent;
      case 'warning':
        return Colors.orange[600]!;
      case 'info':
      default:
        // Use a less prominent color for info logs
        return Colors.blueGrey[600]!;
    }
  }

  IconData _sourceIcon(String source) {
    switch (source.toLowerCase()) { // Use toLowerCase for safety
      case 'camera':
        return Icons.videocam_outlined;
      case 'sensor_motion':
        return Icons.directions_run;
       case 'sensor_door':
         return Icons.door_front_door_outlined;
       case 'sensor_window':
         return Icons.window_outlined;
      case 'rfid':
        return Icons.nfc; // More specific than rss_feed
      case 'user':
        return Icons.person_outline;
      case 'system':
      default:
        return Icons.dns; // More representative of system/server
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final List<LogEntry> logs = appState.logs; // ✅ Use typed logs
    final isLoading = appState.isLoading && logs.isEmpty; // Show loading only if logs are empty
    final error = appState.error;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Consistent background
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null && logs.isEmpty // Show error only if logs are empty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error loading logs: $error', 
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => Provider.of<AppState>(context, listen: false).fetchLogs(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ))
              : RefreshIndicator( // ✅ Add RefreshIndicator
                  onRefresh: () => context.read<AppState>().fetchLogs(),
                  child: logs.isEmpty
                      ? Center(
                          child: Text(
                            "No logs available.", 
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          )
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(), // Needed for RefreshIndicator
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index]; // ✅ Already typed LogEntry
                            final hasVideo = log.videoUrl != null && log.videoUrl!.isNotEmpty;

                            return Card(
                              elevation: 1.5,
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                leading: Tooltip(
                                   message: "Severity: ${log.severity}",
                                   child: Icon(
                                    _sourceIcon(log.source),
                                    color: _severityColor(log.severity),
                                    size: 28, // Slightly larger icon
                                  ),
                                ), 
                                title: Text(log.eventType.replaceAll('_', ' ').capitalize(), style: const TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Source: ${log.source}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                    Text("Time: ${_logTimestampFormatter.format(log.timestamp)}", style: TextStyle(fontSize: 12, color: Colors.grey[700])), // ✅ Format DateTime
                                    if (hasVideo)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                             Icon(Icons.video_camera_back_outlined, size: 14, color: Colors.blue[600]),
                                             const SizedBox(width: 4),
                                             Text("Video available", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.blue[600])),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Tooltip(
                                   message: "Severity: ${log.severity}",
                                   child: Icon(
                                     log.severity == 'critical' ? Icons.error : 
                                     log.severity == 'error' ? Icons.cancel : 
                                     log.severity == 'warning' ? Icons.warning_amber_rounded : 
                                     Icons.info_outline,
                                     color: _severityColor(log.severity),
                                   ),
                                ),
                                onTap: () {
                                   // TODO: Implement log detail view or action
                                   print("Tapped log: ${log.id}");
                                   if (hasVideo) {
                                     // TODO: Handle video playback (e.g., open URL)
                                      print("Video URL: ${log.videoUrl}");
                                   }
                                },
                              ),
                            );
                          },
                        ),
                ),
      // Remove FAB using old mock method
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     context.read<AppState>().loadLogsFromJson(); // <-- Incorrect call
      //   },
      //   tooltip: 'Refresh Logs',
      //   child: const Icon(Icons.refresh),
      // ),
    );
  }
}

// Helper extension for capitalizing strings
extension StringExtension on String {
    String capitalize() {
      if (this.isEmpty) return "";
      return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
    }
}

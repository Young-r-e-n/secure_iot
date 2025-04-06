import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_iot/providers/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red.shade700;
      case 'error':
        return Colors.redAccent;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _sourceIcon(String source) {
    switch (source) {
      case 'camera':
        return Icons.videocam;
      case 'sensor':
        return Icons.sensors;
      case 'rfid':
        return Icons.rss_feed;
      case 'user':
        return Icons.person;
      case 'system':
      default:
        return Icons.memory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final logs = appState.logs;

    return Scaffold(
      body: appState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : logs.isEmpty
              ? const Center(child: Text("No logs available."))
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final severity = log['severity'] ?? 'info';
                    final source = log['source'] ?? 'system';
                    final timestamp = log['timestamp'] ?? '';
                    final eventType = log['event_type'] ?? 'Event';
                    final hasVideo = log['video_url'] != null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          _sourceIcon(source),
                          color: _severityColor(severity),
                        ),
                        title: Text(eventType),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Source: $source"),
                            Text("Time: $timestamp"),
                            if (hasVideo)
                              const Text("🎥 Video attached", style: TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                        trailing: Text(
                          severity.toUpperCase(),
                          style: TextStyle(
                            color: _severityColor(severity),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<AppState>().loadLogsFromJson();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

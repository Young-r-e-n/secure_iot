import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_iot/providers/app_state.dart';
import '../../../models/system_status.dart';

class ControlsScreen extends StatelessWidget {
  const ControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final systemStatus = appState.currentStatus;
          final isLoading = appState.isLoading && systemStatus == null;
          final error = appState.error;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (error != null && systemStatus == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error loading controls status: $error', 
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => Provider.of<AppState>(context, listen: false).fetchSystemStatus(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (systemStatus == null) {
             return const Center(child: Text("Control status not available."));
          }

          final List<String> alerts = systemStatus.errors ?? [];

          return RefreshIndicator(
             onRefresh: () => Provider.of<AppState>(context, listen: false).fetchSystemStatus(),
             child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatusCard(context, systemStatus),
                const SizedBox(height: 16),
                _buildControlCard(
                  context,
                  'Door Control',
                  'Lock or unlock the server room door',
                  [
                    _buildControlButton(
                      context,
                      'Lock Door',
                      Icons.lock_outline,
                      Colors.redAccent,
                      (appState.isLoading || _isDoorLocked(systemStatus))
                       ? null 
                       : () => _executeCommand(context, 'lock'),
                    ),
                    _buildControlButton(
                      context,
                      'Unlock Door',
                      Icons.lock_open_outlined,
                      Colors.green,
                      (appState.isLoading || !_isDoorLocked(systemStatus))
                        ? null 
                        : () => _executeCommand(context, 'unlock'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildControlCard(
                  context,
                  'System Control',
                  'Manage server room system functions',
                  [
                    _buildControlButton(
                      context,
                      'Test Sensors',
                      Icons.rule,
                      Colors.blueAccent,
                      appState.isLoading ? null : () => _executeCommand(context, 'test_sensors'),
                    ),
                    _buildControlButton(
                      context,
                      'Restart System',
                      Icons.restart_alt,
                      Colors.orangeAccent,
                      appState.isLoading ? null : () => _showConfirmationDialog(
                        context,
                        'Restart System',
                        'Are you sure you want to restart the Pi system?',
                        () => _executeCommand(context, 'restart_system'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildControlCard(
                  context,
                  'Manual Alert',
                  'Trigger a manual alert for the server room',
                  [
                    _buildControlButton(
                      context,
                      'Create Alert',
                      Icons.add_alert_outlined,
                      Colors.red,
                      appState.isLoading ? null : () => _showManualAlertDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (alerts.isNotEmpty)
                  _buildAlertsCard(context, alerts),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isDoorLocked(SystemStatus status) {
    return status.sensors['door']?.data?['locked'] ?? false;
  }

  Widget _buildStatusCard(BuildContext context, SystemStatus status) {
    bool isLocked = _isDoorLocked(status);
    String systemHealth = status.status;

    return Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildStatusRow(
              icon: isLocked ? Icons.lock : Icons.lock_open,
              label: 'Door',
              value: isLocked ? 'Locked' : 'Unlocked',
              color: isLocked ? Colors.red[400]! : Colors.green[400]!,
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              icon: Icons.monitor_heart_outlined,
              label: 'System Health',
              value: systemHealth,
              color: _getStatusColor(context, systemHealth),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'online':
        return Colors.green[400]!;
      case 'degraded':
      case 'warning':
        return Colors.orange[400]!;
      case 'error':
      case 'offline':
        return Colors.red[400]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
              overflow: TextOverflow.ellipsis,
            )
        ),
      ],
    );
  }

  Widget _buildAlertsCard(BuildContext context, List<String> alerts) {
    return Card(
      color: Colors.orange[50],
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'System Alerts (${alerts.length})', 
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.orange[800])
            ),
            const SizedBox(height: 10),
            if (alerts.isEmpty)
              const Text("No active alerts.")
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 18),
                         const SizedBox(width: 8),
                         Expanded(child: Text(alert, style: const TextStyle(fontSize: 13))),
                       ],
                     );
                },
                separatorBuilder: (context, index) => const Divider(height: 10),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard(
    BuildContext context,
    String title,
    String description,
    List<Widget> buttons,
  ) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, children: buttons),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withOpacity(0.5),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _executeCommand(BuildContext context, String command) async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.executeControlCommand(command);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Command "$command" sent successfully'),
             backgroundColor: Colors.green,
             duration: const Duration(seconds: 2),
           ),
         );
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Failed to execute "$command": ${appState.error ?? e.toString()}'),
             backgroundColor: Colors.red,
             duration: const Duration(seconds: 3),
           ),
         );
       }
    }
  }

  Future<void> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(title)),
        ],
      ),
    );
    if (confirmed == true) {
      onConfirm();
    }
  }

  Future<void> _showManualAlertDialog(BuildContext context) async {
    final TextEditingController alertController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Manual Alert'),
        content: TextField(
          controller: alertController,
          decoration: const InputDecoration(hintText: 'Enter alert message', border: OutlineInputBorder()),
          autofocus: true,
          minLines: 1,
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
             onPressed: () {
               if (alertController.text.trim().isNotEmpty) {
                 Navigator.of(context).pop(true);
               } else {
                 // Optional: Show feedback inline? Or just prevent closing.
               }
             },
             child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirmed == true && alertController.text.trim().isNotEmpty) {
       final message = alertController.text.trim();
       // ✅ Call AppState method
       await Provider.of<AppState>(context, listen: false).postManualAlert(message);
       // Display feedback based on AppState.error (set in postManualAlert)
       if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(appState.error ?? 'Alert posted!'), // Use error as potential success/fail message
               backgroundColor: appState.error != null && !appState.error!.contains('success') ? Colors.red : Colors.green,
             ),
          );
          // Clear error state after showing message
          appState.clearError(); 
       }
    }
     alertController.dispose();
  }
}

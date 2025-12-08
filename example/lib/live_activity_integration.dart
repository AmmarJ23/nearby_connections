import 'package:flutter/material.dart';
import 'package:live_activities/live_activities.dart';
// import 'package:nearby_connections/nearby_connections.dart'; // Commented out - kept for reference

/// Example controller that integrates Live Activities with Nearby Connections
class LiveActivityController {
  final LiveActivities _liveActivitiesPlugin = LiveActivities();
  String? _currentActivityId;
  
  /// Start a live activity for nearby connection
  Future<void> startConnectionActivity({
    required String deviceName,
    required String connectionStatus,
  }) async {
    try {
      final activityId = await _liveActivitiesPlugin.createActivity(
        'nearby_connection',
        <String, dynamic>{
          'deviceName': deviceName,
          'connectionStatus': connectionStatus,
          'dataReceived': 'No data yet',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      _currentActivityId = activityId;
      debugPrint('Live Activity started: $activityId');
    } catch (e) {
      debugPrint('Error starting live activity: $e');
    }
  }

  /// Update the live activity with new connection information
  Future<void> updateConnectionActivity({
    required String deviceName,
    required String connectionStatus,
    String? dataReceived,
  }) async {
    if (_currentActivityId == null) return;

    try {
      await _liveActivitiesPlugin.updateActivity(
        _currentActivityId!,
        <String, dynamic>{
          'deviceName': deviceName,
          'connectionStatus': connectionStatus,
          'dataReceived': dataReceived ?? 'No data',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('Live Activity updated');
    } catch (e) {
      debugPrint('Error updating live activity: $e');
    }
  }

  /// End the current live activity
  Future<void> endConnectionActivity() async {
    if (_currentActivityId == null) return;

    try {
      await _liveActivitiesPlugin.endActivity(_currentActivityId!);
      debugPrint('Live Activity ended');
      _currentActivityId = null;
    } catch (e) {
      debugPrint('Error ending live activity: $e');
    }
  }

  /// Check if there's an active live activity
  bool get hasActiveActivity => _currentActivityId != null;
}

/// Widget that demonstrates Live Activities integration with Nearby Connections
class LiveActivityExample extends StatefulWidget {
  const LiveActivityExample({Key? key}) : super(key: key);

  @override
  State<LiveActivityExample> createState() => _LiveActivityExampleState();
}

class _LiveActivityExampleState extends State<LiveActivityExample> {
  final LiveActivityController _activityController = LiveActivityController();
  String _connectionStatus = 'Disconnected';
  String _connectedDevice = 'None';
  String _lastDataReceived = 'No data';

  @override
  void dispose() {
    _activityController.endConnectionActivity();
    super.dispose();
  }

  // Example callback methods for Nearby Connections integration
  // These are kept as reference but not currently wired up
  
  // void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
  //   setState(() {
  //     _connectedDevice = info.endpointName;
  //     _connectionStatus = 'Connecting...';
  //   });
  //   
  //   _activityController.startConnectionActivity(
  //     deviceName: info.endpointName,
  //     connectionStatus: 'Connecting...',
  //   );
  // }

  // void _onConnectionResult(String endpointId, Status status) {
  //   setState(() {
  //     _connectionStatus = status == Status.CONNECTED 
  //         ? 'Connected' 
  //         : 'Disconnected';
  //   });

  //   _activityController.updateConnectionActivity(
  //     deviceName: _connectedDevice,
  //     connectionStatus: _connectionStatus,
  //   );
  // }

  // void _onDisconnected(String endpointId) {
  //   setState(() {
  //     _connectionStatus = 'Disconnected';
  //     _connectedDevice = 'None';
  //     _lastDataReceived = 'No data';
  //   });

  //   _activityController.endConnectionActivity();
  // }

  // void _onPayloadReceived(String endpointId, Payload payload) {
  //   if (payload.type == PayloadType.BYTES) {
  //     final data = String.fromCharCodes(payload.bytes!);
  //     setState(() {
  //       _lastDataReceived = data;
  //     });

  //     _activityController.updateConnectionActivity(
  //       deviceName: _connectedDevice,
  //       connectionStatus: _connectionStatus,
  //       dataReceived: 'Received: ${data.substring(0, data.length > 20 ? 20 : data.length)}...',
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Activity + Nearby Connections'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Activity Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Device: $_connectedDevice'),
                    Text('Status: $_connectionStatus'),
                    Text('Last Data: $_lastDataReceived'),
                    const SizedBox(height: 8),
                    Text(
                      _activityController.hasActiveActivity
                          ? '✓ Live Activity Running'
                          : '✗ No Active Live Activity',
                      style: TextStyle(
                        color: _activityController.hasActiveActivity
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Integration Info:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Live Activities show persistent notifications\n'
              '• Updates automatically when connection status changes\n'
              '• Shows real-time data received from nearby devices\n'
              '• Ends when connection is terminated',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: avoid_print, prefer_const_constructors

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

// Import the Sample App Navigation file
import 'sample_app_navigation.dart';
import 'models/connection_status_live_activity_model.dart';
import 'tcp_connection_simulator.dart';

// Activity log entry model
class ActivityLogEntry {
  final String userName;
  final String activity;
  final DateTime timestamp;

  ActivityLogEntry({
    required this.userName,
    required this.activity,
    required this.timestamp,
  });
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nearby Connections example app'),
        ),
        body: const Body(),
      ),
    );
  }
}

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _MyBodyState();
}

class _MyBodyState extends State<Body> {
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  Map<String, ConnectionInfo> endpointMap = {};

  // TCP mode toggle
  bool _useTcpMode = false;
  final TcpConnectionSimulator _tcpSimulator = TcpConnectionSimulator();
  final TextEditingController _serverAddressController = TextEditingController(text: '10.0.2.2'); // Default for emulator to host

  String? tempFileUri; //reference to the file currently being transferred
  Map<int, String> map = {}; //store filename mapped to corresponding payloadId
  Map<String, String> endpointActivities = {}; //store activity status for each endpoint
  List<ActivityLogEntry> activityLog = []; //store activity log entries

  // Add a variable to track the current activity of the user
  String currentActivity = "Idle"; // Default activity

  // Notification Channel
  static const platform = MethodChannel('com.pkmnapps.nearby_connections/notification');
  bool _liveActivityEnabled = true; // Track if live activity is enabled (default: true)

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            // Add TCP Mode Toggle at the top
            Card(
              color: _useTcpMode ? Colors.blue.shade50 : Colors.grey.shade50,
              child: SwitchListTile(
                title: const Text('TCP Testing Mode'),
                subtitle: Text(_useTcpMode 
                  ? 'Using TCP sockets for testing' 
                  : 'Using Nearby Connections'),
                value: _useTcpMode,
                onChanged: (value) {
                  setState(() {
                    _useTcpMode = value;
                  });
                },
              ),
            ),
            if (_useTcpMode)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _serverAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Server IP Address',
                    hintText: '10.0.2.2 (emulator) or device IP',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            const Text(
              "Permissions",
            ),
            Wrap(
              children: <Widget>[
                ElevatedButton(
                  child: const Text("checkLocationPermission (<= Android 12)"),
                  onPressed: () async {
                    if (await Permission.locationWhenInUse.isGranted) {
                      showSnackbar("Location permissions granted :)");
                    } else {
                      showSnackbar("Location permissions not granted :(");
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("askLocationPermission"),
                  onPressed: () async {
                    if (await Permission.locationWhenInUse
                        .request()
                        .isGranted) {
                      showSnackbar("Location permissions granted :)");
                    } else {
                      showSnackbar("Location permissions not granted :(");
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("checkExternalStoragePermission"),
                  onPressed: () async {
                    if (await Permission.storage.isGranted) {
                      showSnackbar("External Storage permissions granted :)");
                    } else {
                      showSnackbar(
                          "External Storage permissions not granted :(");
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("askExternalStoragePermission"),
                  onPressed: () {
                    Permission.storage.request();
                  },
                ),
                ElevatedButton(
                  child: const Text("checkBluetoothPermission (>= Android 12)"),
                  onPressed: () async {
                    if (!(await Future.wait([
                      Permission.bluetooth.isGranted,
                      Permission.bluetoothAdvertise.isGranted,
                      Permission.bluetoothConnect.isGranted,
                      Permission.bluetoothScan.isGranted,
                    ]))
                        .any((element) => false)) {
                      showSnackbar("Bluetooth permissions granted :)");
                    } else {
                      showSnackbar("Bluetooth permissions not granted :(");
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("askBluetoothPermission (Android 12+)"),
                  onPressed: () async {
                    await [
                      Permission.bluetooth,
                      Permission.bluetoothAdvertise,
                      Permission.bluetoothConnect,
                      Permission.bluetoothScan
                    ].request();
                  },
                ),
                ElevatedButton(
                  child: const Text(
                      "checkNearbyWifiDevicesPermission (>= Android 12)"),
                  onPressed: () async {
                    if (await Permission.nearbyWifiDevices.isGranted) {
                      showSnackbar("NearbyWifiDevices permissions granted :)");
                    } else {
                      showSnackbar(
                          "NearbyWifiDevices permissions not granted :(");
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text(
                      "askNearbyWifiDevicesPermission (Android 12+)"),
                  onPressed: () {
                    Permission.nearbyWifiDevices.request();
                  },
                ),
                ElevatedButton(
                  child: const Text("checkNotificationPermission"),
                  onPressed: () async {
                    if (await Permission.notification.isGranted) {
                      showSnackbar("Notification permissions granted :)");
                    } else {
                      showSnackbar("Notification permissions not granted :(");
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("askNotificationPermission"),
                  onPressed: () async {
                    if (await Permission.notification.request().isGranted) {
                      showSnackbar("Notification permissions granted :)");
                    } else {
                      showSnackbar("Notification permissions not granted :(");
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            const Text("Location Enabled"),
            Wrap(
              children: <Widget>[
                ElevatedButton(
                  child: const Text("checkLocationEnabled"),
                  onPressed: () async {
                    if (await Location.instance.serviceEnabled()) {
                      showSnackbar("Location is ON :)");
                    } else {
                      showSnackbar("Location is OFF :(");
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("enableLocationServices"),
                  onPressed: () async {
                    if (await Location.instance.requestService()) {
                      showSnackbar("Location Service Enabled :)");
                    } else {
                      showSnackbar("Location Service not Enabled :(");
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            Text("User Name: $userName"),
            Wrap(
              children: <Widget>[
                ElevatedButton(
                  child: const Text("Start Advertising"),
                  onPressed: () async {
                    try {
                      bool a;
                      if (_useTcpMode) {
                        a = await _tcpSimulator.startAdvertising(
                          userName: userName,
                          onConnectionInit: (id, name, token) {
                            onConnectionInit(id, name);
                          },
                          onConnectionResult: (id) {
                            showSnackbar("TCP Connection: $id");
                          },
                          onDisconnected: (id) {
                            showSnackbar("TCP Disconnected: $id");
                            setState(() {
                              endpointMap.remove(id);
                              endpointActivities.remove(id);
                            });
                            _updateLiveActivity();
                          },
                        );
                      } else {
                        a = await Nearby().startAdvertising(
                          userName,
                          strategy,
                          onConnectionInitiated: onConnectionInit,
                          onConnectionResult: (id, status) {
                            showSnackbar(status);
                          },
                          onDisconnected: (id) {
                            showSnackbar(
                                "Disconnected: ${endpointMap[id]!.endpointName}, id $id");
                            setState(() {
                              endpointMap.remove(id);
                              endpointActivities.remove(id);
                            });
                            _updateLiveActivity(); // Update live activity on disconnect
                          },
                        );
                      }
                      showSnackbar("ADVERTISING: $a");
                    } catch (exception) {
                      showSnackbar(exception);
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("Stop Advertising"),
                  onPressed: () async {
                    if (_useTcpMode) {
                      await _tcpSimulator.stopAdvertising();
                    } else {
                      await Nearby().stopAdvertising();
                    }
                  },
                ),
              ],
            ),
            Wrap(
              children: <Widget>[
                ElevatedButton(
                  child: const Text("Start Discovery"),
                  onPressed: () async {
                    try {
                      bool a;
                      if (_useTcpMode) {
                        a = await _tcpSimulator.startDiscovery(
                          userName: userName,
                          onEndpointFound: (id, name, serviceId) {
                            showModalBottomSheet(
                              context: context,
                              builder: (builder) {
                                return Center(
                                  child: Column(
                                    children: <Widget>[
                                      Text("id: $id"),
                                      Text("Name: $name"),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        child: const Text("Request Connection"),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _tcpSimulator.requestConnection(
                                            userName: userName,
                                            endpointId: id,
                                            serverAddress: _serverAddressController.text,
                                            onConnectionInit: (id, name, token) {
                                              onConnectionInit(id, name);
                                            },
                                            onConnectionResult: (id) {
                                              showSnackbar("TCP Connected: $id");
                                            },
                                            onDisconnected: (id) {
                                              setState(() {
                                                endpointMap.remove(id);
                                                endpointActivities.remove(id);
                                              });
                                              _updateLiveActivity();
                                              showSnackbar("TCP Disconnected: $id");
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          onEndpointLost: (id) {
                            showSnackbar("Lost endpoint: $id");
                          },
                        );
                      } else {
                        a = await Nearby().startDiscovery(
                          userName,
                          strategy,
                          onEndpointFound: (id, name, serviceId) {
                          // show sheet automatically to request connection
                          showModalBottomSheet(
                            context: context,
                            builder: (builder) {
                              return Center(
                                child: Column(
                                  children: <Widget>[
                                    Text("id: $id"),
                                    Text("Name: $name"),
                                    Text("ServiceId: $serviceId"),
                                    ElevatedButton(
                                      child: const Text("Request Connection"),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Nearby().requestConnection(
                                          userName,
                                          id,
                                          onConnectionInitiated: (id, info) {
                                            onConnectionInit(id, info);
                                          },
                                          onConnectionResult: (id, status) {
                                            showSnackbar(status);
                                          },
                                          onDisconnected: (id) {
                                            setState(() {
                                              endpointMap.remove(id);
                                              endpointActivities.remove(id);
                                            });
                                            _updateLiveActivity(); // Update live activity on disconnect
                                            showSnackbar(
                                                "Disconnected from: ${endpointMap[id]!.endpointName}, id $id");
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        onEndpointLost: (id) {
                          showSnackbar(
                              "Lost discovered Endpoint: ${endpointMap[id]?.endpointName}, id $id");
                        },
                        );
                      }
                      showSnackbar("DISCOVERING: $a");
                    } catch (e) {
                      showSnackbar(e);
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("Stop Discovery"),
                  onPressed: () async {
                    if (_useTcpMode) {
                      await _tcpSimulator.stopDiscovery();
                    } else {
                      await Nearby().stopDiscovery();
                    }
                  },
                ),
              ],
            ),
            Text("Number of connected devices: ${endpointMap.length}"),
            ElevatedButton(
              child: const Text("Print Live Activity Status"),
              onPressed: () {
                print("\n========== LIVE ACTIVITY STATUS ==========");
                print("Enabled: $_liveActivityEnabled");
                print("Platform: ${Platform.operatingSystem}");
                print("User Name: $userName");
                print("Current Activity: $currentActivity");
                print("Connected Devices: ${endpointMap.length}");
                print("\nConnected Users:");
                if (endpointMap.isEmpty) {
                  print("  (None)");
                } else {
                  endpointMap.forEach((key, value) {
                    final activity = endpointActivities[key] ?? "Idle";
                    print("  - ${value.endpointName} ($key): $activity");
                  });
                }
                
                // Show what data would be sent
                final connectedUsers = endpointMap.entries.map((entry) {
                  final activity = endpointActivities[entry.key] ?? "Idle";
                  return ConnectedUser(
                    name: entry.value.endpointName,
                    activity: activity,
                  );
                }).toList();
                final model = ConnectionStatusLiveActivityModel(
                  selfName: userName,
                  selfActivity: currentActivity,
                  connectedCount: endpointMap.length,
                  connectedUsers: connectedUsers,
                );
                print("\nData that would be sent:");
                print(model.toMap());
                print("==========================================\n");
                showSnackbar("Live Activity status printed to console");
              },
            ),
            ElevatedButton(
              child: const Text("Force Refresh Live Activity"),
              onPressed: () async {
                if (_liveActivityEnabled) {
                  await _updateLiveActivity(forceRecreate: true);
                  showSnackbar("Live Activity force refreshed");
                } else {
                  showSnackbar("Enable Live Activity first");
                }
              },
            ),
            ElevatedButton(
              child: const Text("Stop All Endpoints"),
              onPressed: () async {
                if (_useTcpMode) {
                  await _tcpSimulator.stopAllEndpoints();
                } else {
                  await Nearby().stopAllEndpoints();
                }
                setState(() {
                  endpointMap.clear();
                  endpointActivities.clear();
                });
                _updateLiveActivity(); // Update live activity when all endpoints stopped
              },
            ),
            ElevatedButton(
              child: Text(_liveActivityEnabled ? "Disable Live Activity" : "Enable Live Activity"),
              onPressed: () async {
                if (_liveActivityEnabled) {
                  // Disabling
                  print("🛑 Disabling Live Activity");
                  try {
                    await platform.invokeMethod('stopNotification');
                  } catch (e) {
                    print("⚠️ Error stopping notification: $e");
                  }
                  setState(() {
                    _liveActivityEnabled = false;
                  });
                  showSnackbar("Live Activity disabled");
                } else {
                  // Enabling
                  print("▶️ Enabling Live Activity");
                  setState(() {
                    _liveActivityEnabled = true;
                  });
                  await _updateLiveActivity(forceRecreate: true);
                  showSnackbar("Live Activity enabled");
                }
              },
            ),
            const Divider(),
            // Enhanced Connection Information Section
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "Connection Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // My Current Activity
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "My Current Activity",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentActivity,
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Connected Users Section
                    const Row(
                      children: [
                        Icon(Icons.groups, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          "Connected Users",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Users List
                    if (endpointMap.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.people_outline, 
                                size: 32, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              "No users connected",
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...endpointMap.entries.map((entry) {
                        String endpointName = entry.value.endpointName;
                        String status = endpointActivities[entry.key] ?? "Idle";
                        
                        // Activity status color and icon
                        Color statusColor;
                        IconData statusIcon;
                        
                        switch (status.toLowerCase()) {
                          case 'idle':
                            statusColor = Colors.grey;
                            statusIcon = Icons.pause_circle_outline;
                            break;
                          case 'typing':
                          case 'typing message':
                          case 'writing notes':
                            statusColor = Colors.orange;
                            statusIcon = Icons.edit;
                            break;
                          case 'browsing home':
                          case 'browsing photos':
                          case 'browsing':
                            statusColor = Colors.blue;
                            statusIcon = Icons.explore;
                            break;
                          case 'viewing messages':
                          case 'reading messages':
                            statusColor = Colors.purple;
                            statusIcon = Icons.message;
                            break;
                          case 'taking notes':
                          case 'editing document':
                          case 'editing profile':
                            statusColor = Colors.green;
                            statusIcon = Icons.note_alt;
                            break;
                          case 'filling form':
                            statusColor = Colors.teal;
                            statusIcon = Icons.assignment;
                            break;
                          case 'viewing page':
                            statusColor = Colors.indigo;
                            statusIcon = Icons.visibility;
                            break;
                          default:
                            statusColor = Colors.grey;
                            statusIcon = Icons.help_outline;
                        }
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: statusColor.withOpacity(0.2),
                                child: Icon(
                                  statusIcon,
                                  color: statusColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      endpointName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            const Divider(),
            const Text(
              "Sending Data",
            ),
            ElevatedButton(
              child: const Text("Send Random Bytes Payload"),
              onPressed: () async {
                endpointMap.forEach((key, value) {
                  String a = Random().nextInt(100).toString();

                  showSnackbar("Sending $a to ${value.endpointName}, id: $key");
                  Nearby()
                      .sendBytesPayload(key, Uint8List.fromList(a.codeUnits));
                });
              },
            ),
            ElevatedButton(
              child: const Text("Send File Payload"),
              onPressed: () async {
                XFile? file =
                    await ImagePicker().pickImage(source: ImageSource.gallery);

                if (file == null) return;

                for (MapEntry<String, ConnectionInfo> m
                    in endpointMap.entries) {
                  int payloadId =
                      await Nearby().sendFilePayload(m.key, file.path);
                  showSnackbar("Sending file to ${m.key}");
                  Nearby().sendBytesPayload(
                      m.key,
                      Uint8List.fromList(
                          "$payloadId:${file.path.split('/').last}".codeUnits));
                }
              },
            ),
            ElevatedButton(
              child: const Text("Print file names."),
              onPressed: () async {
                final dir = (await getExternalStorageDirectory())!;
                final files = (await dir.list(recursive: true).toList())
                    .map((f) => f.path)
                    .toList()
                    .join('\n');
                showSnackbar(files);
              },
            ),
            ElevatedButton(
              child: const Text("Select Activity"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActivitySelectionScreen(
                      onActivitySelected: (activity) {
                        updateActivity(activity); // Update the activity and notify others
                      },
                    ),
                  ),
                );
              },
            ),
            ElevatedButton(
              child: const Text("Typing Activity"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TypingActivityScreen(
                      onActivityUpdate: (activity) {
                        updateActivity(activity); // Update the activity and notify others
                      },
                    ),
                  ),
                );
              },
            ),
            // Add a button to navigate to the Sample App Navigation
            ElevatedButton(
              child: const Text("Sample App Navigation"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SampleAppNavigation(
                      onActivityUpdate: (activity) {
                        updateActivity(activity); // Update the activity and notify others
                      },
                    ),
                  ),
                );
              },
            ),
            ElevatedButton(
              child: Text("View Activity Log (${activityLog.length} entries)"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActivityLogScreen(
                      activityLog: activityLog,
                      onClearLog: () {
                        setState(() {
                          activityLog.clear();
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void showSnackbar(dynamic a) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(a.toString()),
      ),
    );
  }

  Future<bool> moveFile(String uri, String fileName) async {
    String parentDir = (await getExternalStorageDirectory())!.absolute.path;
    final b =
        await Nearby().copyFileAndDeleteOriginal(uri, '$parentDir/$fileName');

    showSnackbar("Moved file:$b");
    return b;
  }

  /// Called upon Connection request (on both devices)
  /// Both need to accept connection to start sending/receiving
  void onConnectionInit(String id, dynamic info) {
    ConnectionInfo connectionInfo;
    
    if (info is ConnectionInfo) {
      connectionInfo = info;
    } else {
      // Create ConnectionInfo for TCP mode
      connectionInfo = ConnectionInfo(
        id,
        info is String ? info : 'TCP-User',
        true, // isIncomingConnection
      );
    }
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Center(
          child: Column(
            children: <Widget>[
              Text("id: $id"),
              Text("Token: ${connectionInfo.authenticationToken}"),
              Text("Name: ${connectionInfo.endpointName}"),
              Text("Incoming: ${connectionInfo.isIncomingConnection}"),
              ElevatedButton(
                child: const Text("Accept Connection"),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    endpointMap[id] = connectionInfo;
                  });
                  _updateLiveActivity(); // Update live activity when connection is accepted
                  
                  if (_useTcpMode) {
                    _tcpSimulator.acceptConnection(id);
                    _tcpSimulator.onPayloadReceived = (endid, payload) {
                      if (payload['type'] == 'BYTES') {
                        Uint8List bytes = payload['bytes'];
                        String str = String.fromCharCodes(bytes);
                        
                        if (!str.contains(':')) {
                          String endpointName = endpointMap[endid]?.endpointName ?? endid;
                          String? previousActivity = endpointActivities[endid];
                          if (previousActivity != str) {
                            _logActivity(endpointName, str);
                          }
                          setState(() {
                            endpointActivities[endid] = str;
                          });
                          _updateLiveActivity();
                        }
                      }
                    };
                  } else {
                    Nearby().acceptConnection(
                    id,
                    onPayLoadRecieved: (endid, payload) async {
                      if (payload.type == PayloadType.BYTES) {
                        String str = String.fromCharCodes(payload.bytes!);
                        // showSnackbar("$endid: $str");

                        if (str.contains(':')) {
                          // used for file payload as file payload is mapped as
                          // payloadId:filename
                          int payloadId = int.parse(str.split(':')[0]);
                          String fileName = (str.split(':')[1]);

                          if (map.containsKey(payloadId)) {
                            if (tempFileUri != null) {
                              moveFile(tempFileUri!, fileName);
                            } else {
                              showSnackbar("File doesn't exist");
                            }
                          } else {
                            //add to map if not already
                            map[payloadId] = fileName;
                          }
                        } else {
                          // Handle activity status updates
                          print("Received activity update from $endid: $str");
                          String endpointName = endpointMap[endid]?.endpointName ?? endid;
                          
                          // Only log if activity has changed
                          String? previousActivity = endpointActivities[endid];
                          if (previousActivity != str) {
                            _logActivity(endpointName, str);
                          }
                          
                          setState(() {
                            endpointActivities[endid] = str;
                          });
                          _updateLiveActivity(); // Update live activity when remote status changes
                        }
                      } else if (payload.type == PayloadType.FILE) {
                        showSnackbar("$endid: File transfer started");
                        tempFileUri = payload.uri;
                      }
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      if (payloadTransferUpdate.status ==
                          PayloadStatus.IN_PROGRESS) {
                        print(payloadTransferUpdate.bytesTransferred);
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.FAILURE) {
                        print("failed");
                        showSnackbar("$endid: FAILED to transfer file");
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.SUCCESS) {
                        // showSnackbar(
                        //     "$endid success, total bytes = ${payloadTransferUpdate.totalBytes}");

                        if (map.containsKey(payloadTransferUpdate.id)) {
                          //rename the file now
                          String name = map[payloadTransferUpdate.id]!;
                          moveFile(tempFileUri!, name);
                        } else {
                          //bytes not received till yet
                          map[payloadTransferUpdate.id] = "";
                        }
                      }
                    },
                  );
                  }
                },
              ),
              ElevatedButton(
                child: const Text("Reject Connection"),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    if (_useTcpMode) {
                      // For TCP mode, just don't accept
                      showSnackbar("Connection rejected");
                    } else {
                      await Nearby().rejectConnection(id);
                    }
                  } catch (e) {
                    showSnackbar(e);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to log activity with timestamp
  void _logActivity(String userName, String activity) {
    final logEntry = ActivityLogEntry(
      userName: userName,
      activity: activity,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      activityLog.add(logEntry);
    });
    
    print("Auto-logged: $userName - $activity");
  }

  // Function to update the user's activity and notify connected devices
  void updateActivity(String activity) {
    // Only log if activity has changed
    if (currentActivity != activity) {
      _logActivity(userName, activity);
    }
    
    setState(() {
      currentActivity = activity;
    });

    print("Current Activity: $activity");
    print("Sending activity to ${endpointMap.length} connected devices");

    // Send the activity update to all connected devices
    endpointMap.forEach((key, value) {
      print("Sending '$activity' to ${value.endpointName} (ID: $key)");
      if (_useTcpMode) {
        _tcpSimulator.sendBytesPayload(key, Uint8List.fromList(activity.codeUnits));
      } else {
        Nearby().sendBytesPayload(key, Uint8List.fromList(activity.codeUnits));
      }
    });

    // Update live activity
    _updateLiveActivity();
  }

  Future<void> _updateLiveActivity({bool forceRecreate = false}) async {
    if (!Platform.isAndroid) {
      print("⏭️ Skipping live activity - Platform: ${Platform.operatingSystem}");
      return;
    }
    
    if (!_liveActivityEnabled) {
      print("⏭️ Live activity disabled by user");
      return;
    }

    print("\n📱 ===== UPDATING NOTIFICATION =====");
    print("Self: $userName - $currentActivity");
    print("Connected: ${endpointMap.length}");
    
    // Build connected users list
    final connectedUsers = endpointMap.entries.map((entry) {
      final activity = endpointActivities[entry.key] ?? "Idle";
      print("  👤 ${entry.value.endpointName}: $activity");
      return ConnectedUser(
        name: entry.value.endpointName,
        activity: activity,
      );
    }).toList();

    // Create the model
    final model = ConnectionStatusLiveActivityModel(
      selfName: userName,
      selfActivity: currentActivity,
      connectedCount: endpointMap.length,
      connectedUsers: connectedUsers,
    );

    final data = model.toMap();
    print("📦 Data to send: $data");

    try {
      await platform.invokeMethod('updateNotification', data);
      print("✅ Updated Notification");
    } catch (e) {
      print("❌ ERROR in _updateLiveActivity: $e");
    }
  }
}

// Define a new screen for activity selection
class ActivitySelectionScreen extends StatelessWidget {
  final Function(String) onActivitySelected;

  const ActivitySelectionScreen({Key? key, required this.onActivitySelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activities = ["Idle", "Filling Form", "Viewing Page", "Editing Document", "Browsing"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Activity"),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 buttons across
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        padding: const EdgeInsets.all(16.0),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          return ElevatedButton(
            onPressed: () {
              onActivitySelected(activities[index]);
              Navigator.pop(context); // Go back to the previous screen
            },
            child: Text(activities[index]),
          );
        },
      ),
    );
  }
}

// Add a dynamic typing activity widget
class TypingActivityScreen extends StatefulWidget {
  final Function(String) onActivityUpdate;

  const TypingActivityScreen({Key? key, required this.onActivityUpdate}) : super(key: key);

  @override
  State<TypingActivityScreen> createState() => _TypingActivityScreenState();
}

class _TypingActivityScreenState extends State<TypingActivityScreen> {
  final TextEditingController _controller = TextEditingController();
  late FocusNode _focusNode;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    // Listen to focus changes to detect typing activity
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.onActivityUpdate("Typing");
        setState(() {
          _isTyping = true;
        });
      } else {
        widget.onActivityUpdate("Idle");
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Typing Activity"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: "Start typing...",
              ),
              onChanged: (text) {
                widget.onActivityUpdate("Typing");
              },
            ),
            const SizedBox(height: 16.0),
            Text(
              _isTyping ? "You are typing..." : "You are idle.",
              style: const TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}

// Activity Log Screen
class ActivityLogScreen extends StatefulWidget {
  final List<ActivityLogEntry> activityLog;
  final VoidCallback onClearLog;

  const ActivityLogScreen({
    Key? key,
    required this.activityLog,
    required this.onClearLog,
  }) : super(key: key);

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  Set<String> selectedUsers = <String>{};
  bool showAllUsers = true;

  @override
  void initState() {
    super.initState();
    // Initially show all users
    selectedUsers = widget.activityLog.map((entry) => entry.userName).toSet();
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }

  List<ActivityLogEntry> _getFilteredLogs() {
    if (showAllUsers) return widget.activityLog;
    return widget.activityLog.where((entry) => selectedUsers.contains(entry.userName)).toList();
  }

  Set<String> _getAllUsers() {
    return widget.activityLog.map((entry) => entry.userName).toSet();
  }

  void _showUserFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final allUsers = _getAllUsers().toList()..sort();
            
            return AlertDialog(
              title: const Text("Filter Users"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: const Text("Show All Users"),
                      value: showAllUsers,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          showAllUsers = value ?? true;
                          if (showAllUsers) {
                            selectedUsers = allUsers.toSet();
                          }
                        });
                      },
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: allUsers.map((user) {
                          return CheckboxListTile(
                            title: Text(user),
                            value: selectedUsers.contains(user),
                            enabled: !showAllUsers,
                            onChanged: showAllUsers ? null : (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedUsers.add(user);
                                } else {
                                  selectedUsers.remove(user);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      // Apply the filter changes
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();
    final allUsers = _getAllUsers();
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Activity Log"),
            if (!showAllUsers && allUsers.isNotEmpty)
              Text(
                "${selectedUsers.length} of ${allUsers.length} users",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (widget.activityLog.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showUserFilterDialog,
              tooltip: "Filter Users",
            ),
          if (widget.activityLog.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Clear Activity Log"),
                      content: const Text("Are you sure you want to clear all activity log entries?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            widget.onClearLog();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Activity log cleared")),
                            );
                          },
                          child: const Text("Clear"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: widget.activityLog.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No activity logged yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Activities will be logged automatically when they change",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          : filteredLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No activities match the current filter",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Try adjusting your user filter",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = filteredLogs.length - 1 - index;
                    final entry = filteredLogs[reversedIndex];
                
                Color activityColor;
                IconData activityIcon;
                
                switch (entry.activity.toLowerCase()) {
                  case 'idle':
                    activityColor = Colors.grey;
                    activityIcon = Icons.pause_circle_outline;
                    break;
                  case 'typing':
                  case 'typing message':
                  case 'writing notes':
                    activityColor = Colors.orange;
                    activityIcon = Icons.edit;
                    break;
                  case 'browsing home':
                  case 'browsing photos':
                  case 'browsing':
                    activityColor = Colors.blue;
                    activityIcon = Icons.explore;
                    break;
                  case 'viewing messages':
                  case 'reading messages':
                    activityColor = Colors.purple;
                    activityIcon = Icons.message;
                    break;
                  case 'taking notes':
                  case 'editing document':
                  case 'editing profile':
                    activityColor = Colors.green;
                    activityIcon = Icons.note_alt;
                    break;
                  case 'filling form':
                    activityColor = Colors.teal;
                    activityIcon = Icons.assignment;
                    break;
                  case 'viewing page':
                    activityColor = Colors.indigo;
                    activityIcon = Icons.visibility;
                    break;
                  default:
                    activityColor = Colors.grey;
                    activityIcon = Icons.help_outline;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: activityColor.withOpacity(0.2),
                      child: Icon(
                        activityIcon,
                        color: activityColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      entry.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.activity,
                          style: TextStyle(
                            color: activityColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(entry.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.access_time,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
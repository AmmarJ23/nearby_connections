// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class TcpConnectionSimulator {
  ServerSocket? _serverSocket;
  Socket? _clientSocket;
  final Map<String, Socket> _connections = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, _ConnectionBuffer> _buffers = {};
  
  // Callbacks
  Function(String id, String name, String authToken)? onConnectionInitiated;
  Function(String id)? onConnectionResult;
  Function(String id)? onDisconnected;
  Function(String id, Map<String, dynamic> payload)? onPayloadReceived;
  
  static const int DEFAULT_PORT = 8888;
  
  // Start as advertiser (server)
  Future<bool> startAdvertising({
    required String userName,
    required Function(String, String, String) onConnectionInit,
    required Function(String) onConnectionResult,
    required Function(String) onDisconnected,
  }) async {
    try {
      onConnectionInitiated = onConnectionInit;
      this.onConnectionResult = onConnectionResult;
      this.onDisconnected = onDisconnected;
      
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, DEFAULT_PORT);
      print('TCP Server started on port $DEFAULT_PORT');
      print('Server listening on ${_serverSocket!.address.address}:${_serverSocket!.port}');
      
      _serverSocket!.listen((Socket client) {
        final clientId = '${client.remoteAddress.address}:${client.remotePort}';
        print('Client connected: $clientId');
        
        _connections[clientId] = client;
        _buffers[clientId] = _ConnectionBuffer();
        
        _subscriptions[clientId] = client.listen(
          (data) => _handleData(clientId, data, onConnectionInit),
          onDone: () {
            print('Client disconnected: $clientId');
            _connections.remove(clientId);
            _buffers.remove(clientId);
            _subscriptions[clientId]?.cancel();
            _subscriptions.remove(clientId);
            onDisconnected(clientId);
          },
          onError: (error) {
            print('Error with client $clientId: $error');
            _connections.remove(clientId);
            _buffers.remove(clientId);
            _subscriptions[clientId]?.cancel();
            _subscriptions.remove(clientId);
            onDisconnected(clientId);
          },
        );
      });
      
      return true;
    } catch (e) {
      print('Error starting advertising: $e');
      return false;
    }
  }
  
  // Start as discoverer (client)
  Future<bool> startDiscovery({
    required String userName,
    required Function(String, String, String) onEndpointFound,
    required Function(String) onEndpointLost,
  }) async {
    // For discovery mode, we'll simulate finding the server
    Future.delayed(const Duration(milliseconds: 500), () {
      onEndpointFound('tcp-server', 'TCP-Server', 'tcp-service');
    });
    return true;
  }
  
  // Request connection to server
  Future<void> requestConnection({
    required String userName,
    required String endpointId,
    required String serverAddress,
    required Function(String, String, String) onConnectionInit,
    required Function(String) onConnectionResult,
    required Function(String) onDisconnected,
  }) async {
    try {
      onConnectionInitiated = onConnectionInit;
      this.onConnectionResult = onConnectionResult;
      this.onDisconnected = onDisconnected;
      
      print('Attempting to connect to $serverAddress:$DEFAULT_PORT');
      _clientSocket = await Socket.connect(serverAddress, DEFAULT_PORT, timeout: const Duration(seconds: 10));
      final clientId = 'tcp-connection';
      
      print('Connected to server at $serverAddress:$DEFAULT_PORT');
      _connections[clientId] = _clientSocket!;
      _buffers[clientId] = _ConnectionBuffer();
      
      // Send handshake with username
      _sendHandshake(_clientSocket!, userName);
      
      // Simulate connection initiation on client side
      onConnectionInit(clientId, 'TCP-Server', 'tcp-auth-token');
      
      _subscriptions[clientId] = _clientSocket!.listen(
        (data) => _handleData(clientId, data, null),
        onDone: () {
          print('Disconnected from server');
          _connections.remove(clientId);
          _buffers.remove(clientId);
          _subscriptions[clientId]?.cancel();
          _subscriptions.remove(clientId);
          onDisconnected(clientId);
        },
        onError: (error) {
          print('Connection error: $error');
          _connections.remove(clientId);
          _buffers.remove(clientId);
          _subscriptions[clientId]?.cancel();
          _subscriptions.remove(clientId);
          onDisconnected(clientId);
        },
      );
      
      onConnectionResult(clientId);
    } catch (e) {
      print('Error connecting: $e');
      rethrow;
    }
  }
  
  void _sendHandshake(Socket socket, String userName) {
    final handshake = {
      'type': 'HANDSHAKE',
      'userName': userName,
    };
    final jsonData = jsonEncode(handshake);
    final length = jsonData.length;
    
    final lengthBytes = Uint8List(4);
    lengthBytes.buffer.asByteData().setUint32(0, length, Endian.big);
    
    socket.add(lengthBytes);
    socket.add(utf8.encode(jsonData));
    print('Sent handshake: $userName');
  }
  
  // Accept connection
  void acceptConnection(String endpointId) {
    onConnectionResult?.call(endpointId);
    print('Connection accepted: $endpointId');
  }
  
  // Send bytes payload
  void sendBytesPayload(String endpointId, Uint8List bytes) {
    final socket = _connections[endpointId];
    if (socket != null) {
      final payload = {
        'type': 'BYTES',
        'data': base64Encode(bytes),
      };
      final jsonData = jsonEncode(payload);
      final length = jsonData.length;
      
      // Send length prefix (4 bytes) + JSON data
      final lengthBytes = Uint8List(4);
      lengthBytes.buffer.asByteData().setUint32(0, length, Endian.big);
      
      socket.add(lengthBytes);
      socket.add(utf8.encode(jsonData));
    }
  }
  
  // Handle incoming data
  void _handleData(String endpointId, List<int> data, Function(String, String, String)? serverOnConnectionInit) {
    final buffer = _buffers[endpointId];
    if (buffer == null) return;
    
    buffer.addData(data);
    
    while (true) {
      // Read length prefix if we don't have it yet
      if (buffer.expectedLength == null) {
        if (buffer.buffer.length < 4) break;
        
        final lengthBytes = Uint8List.fromList(buffer.buffer.sublist(0, 4));
        buffer.expectedLength = lengthBytes.buffer.asByteData().getUint32(0, Endian.big);
        buffer.buffer.removeRange(0, 4);
      }
      
      // Read payload if we have enough data
      if (buffer.buffer.length < buffer.expectedLength!) break;
      
      final payloadBytes = buffer.buffer.sublist(0, buffer.expectedLength!);
      buffer.buffer.removeRange(0, buffer.expectedLength!);
      buffer.expectedLength = null;
      
      try {
        final jsonData = utf8.decode(payloadBytes);
        final payload = jsonDecode(jsonData);
        
        if (payload['type'] == 'HANDSHAKE') {
          // Server receives handshake from client
          final userName = payload['userName'];
          print('Received handshake from: $userName');
          if (serverOnConnectionInit != null) {
            serverOnConnectionInit(endpointId, userName, 'tcp-auth-token');
          }
        } else if (payload['type'] == 'BYTES') {
          final bytes = base64Decode(payload['data']);
          onPayloadReceived?.call(endpointId, {
            'type': 'BYTES',
            'bytes': bytes,
          });
        }
      } catch (e) {
        print('Error parsing payload: $e');
      }
    }
  }
  
  // Stop all connections
  Future<void> stopAllEndpoints() async {
    for (var sub in _subscriptions.values) {
      await sub.cancel();
    }
    _subscriptions.clear();
    
    for (var socket in _connections.values) {
      await socket.close();
    }
    _connections.clear();
    _buffers.clear();
    
    await _serverSocket?.close();
    _serverSocket = null;
    
    await _clientSocket?.close();
    _clientSocket = null;
  }
  
  Future<void> stopAdvertising() async {
    await _serverSocket?.close();
    _serverSocket = null;
  }
  
  Future<void> stopDiscovery() async {
    // No-op for TCP mode
  }
}

// Helper class to manage per-connection buffers
class _ConnectionBuffer {
  final List<int> buffer = [];
  int? expectedLength;
  
  void addData(List<int> data) {
    buffer.addAll(data);
  }
}

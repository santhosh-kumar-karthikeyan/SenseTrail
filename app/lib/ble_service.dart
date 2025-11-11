import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static const String deviceName = 'SenseTrail';
  static const String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  StreamSubscription? _connectionSubscription;
  
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> startScanning() async {
    print('🔍 Scanning for SenseTrail device...');
    
    // Start scanning
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    
    // Listen for scan results
    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult result in results) {
        if (result.device.platformName == deviceName) {
          print('✅ Found SenseTrail device!');
          await FlutterBluePlus.stopScan();
          await _connectToDevice(result.device);
          break;
        }
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _device = device;
    
    try {
      print('🔗 Connecting to SenseTrail...');
      await device.connect(timeout: const Duration(seconds: 15));
      
      // Listen for connection state changes
      _connectionSubscription = device.connectionState.listen((state) {
        _isConnected = state == BluetoothConnectionState.connected;
        _connectionController.add(_isConnected);
        
        if (!_isConnected) {
          print('🔌 Device disconnected, attempting reconnect...');
          _reconnect();
        }
      });
      
      // Discover services
      print('🔎 Discovering services...');
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (BluetoothCharacteristic char in service.characteristics) {
            if (char.uuid.toString() == characteristicUuid) {
              _characteristic = char;
              print('✅ Connected to SenseTrail!');
              _isConnected = true;
              _connectionController.add(true);
              return;
            }
          }
        }
      }
    } catch (e) {
      print('❌ Connection error: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  Future<void> _reconnect() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!_isConnected && _device != null) {
      try {
        await _device!.connect();
      } catch (e) {
        print('❌ Reconnection failed: $e');
      }
    }
  }

  Future<void> sendCommand(String direction, double distance) async {
    if (_characteristic == null) {
      print('❌ No characteristic available');
      return;
    }

    String command = '$direction:${distance.toStringAsFixed(1)}';
    print('📤 Sending: $command');
    
    try {
      await _characteristic!.write(command.codeUnits);
    } catch (e) {
      print('❌ Send error: $e');
    }
  }

  void dispose() {
    _connectionSubscription?.cancel();
    _connectionController.close();
    _device?.disconnect();
  }
}

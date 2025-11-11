import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'ble_service.dart';
import 'speech_service.dart';
import 'navigation_service.dart';

void main() {
  runApp(const SenseTrailApp());
}

class SenseTrailApp extends StatelessWidget {
  const SenseTrailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SenseTrail',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // High contrast for accessibility
        brightness: Brightness.light,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 20),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BleService _bleService = BleService();
  final SpeechService _speechService = SpeechService();
  final NavigationService _navService = NavigationService();
  final FlutterTts _tts = FlutterTts();

  bool _isConnected = false;
  bool _isListening = false;
  bool _isNavigating = false;
  String _statusMessage = 'Connecting to device...';
  String _destination = '';
  
  List<RouteStep>? _currentRoute;
  int _currentStepIndex = 0;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Request permissions
    await _requestPermissions();
    
    // Configure TTS
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    
    // Initialize speech
    await _speechService.initialize();
    
    // Connect to BLE device
    _connectBluetooth();
    
    // Listen for connection changes
    _bleService.connectionStream.listen((connected) {
      setState(() {
        _isConnected = connected;
        _statusMessage = connected 
            ? 'Device connected' 
            : 'Device disconnected';
      });
      
      _speak(_statusMessage);
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.microphone,
    ].request();
  }

  Future<void> _connectBluetooth() async {
    setState(() => _statusMessage = 'Scanning for SenseTrail device...');
    await _bleService.startScanning();
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> _startVoiceInput() async {
    if (!_isConnected) {
      _speak('Please turn on the Bluetooth device');
      return;
    }

    setState(() {
      _isListening = true;
      _statusMessage = 'Listening... Say your destination';
    });
    
    _speak('Where would you like to go?');
    await Future.delayed(const Duration(seconds: 2));

    final destination = await _speechService.listenForDestination();
    
    setState(() => _isListening = false);

    if (destination != null && destination.isNotEmpty) {
      setState(() => _destination = destination);
      _speak('Navigating to $destination');
      await _startNavigation(destination);
    } else {
      setState(() => _statusMessage = 'No destination heard');
      _speak('I did not hear a destination. Please try again.');
    }
  }

  Future<void> _startNavigation(String destination) async {
    setState(() => _statusMessage = 'Getting your location...');
    
    // Get current location
    final position = await _navService.getCurrentLocation();
    if (position == null) {
      _speak('Cannot get your location');
      setState(() => _statusMessage = 'Location error');
      return;
    }

    setState(() => _statusMessage = 'Finding route to $destination...');
    
    // Geocode destination
    final destCoords = await _navService.geocodeDestination(destination);
    if (destCoords == null) {
      _speak('Cannot find destination');
      setState(() => _statusMessage = 'Destination not found');
      return;
    }

    // Get route
    final route = await _navService.getRoute(
      position.latitude,
      position.longitude,
      destCoords['lat']!,
      destCoords['lon']!,
    );

    if (route == null || route.isEmpty) {
      _speak('Cannot find route');
      setState(() => _statusMessage = 'Route not found');
      return;
    }

    setState(() {
      _currentRoute = route;
      _currentStepIndex = 0;
      _isNavigating = true;
      _statusMessage = 'Navigation started';
    });

    _speak('Navigation started. ${route.length} steps to destination.');
    await Future.delayed(const Duration(seconds: 2));
    
    // Start navigation guidance
    _startGuidance();
  }

  void _startGuidance() {
    if (_currentRoute == null || _currentRoute!.isEmpty) return;

    // Listen to position updates
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen(_updateNavigation);

    // Send initial instruction
    _sendCurrentInstruction();
  }

  void _updateNavigation(Position position) {
    if (_currentRoute == null || _currentStepIndex >= _currentRoute!.length) {
      _finishNavigation();
      return;
    }

    final currentStep = _currentRoute![_currentStepIndex];
    final distance = _navService.calculateDistance(
      position.latitude,
      position.longitude,
      currentStep.location[0],
      currentStep.location[1],
    );

    // Update haptic feedback based on distance
    _bleService.sendCommand(currentStep.maneuver, distance);

    // Move to next step if close enough
    if (distance < 10) {
      _currentStepIndex++;
      if (_currentStepIndex < _currentRoute!.length) {
        _sendCurrentInstruction();
      } else {
        _finishNavigation();
      }
    }

    setState(() {
      _statusMessage = '${currentStep.instruction} - ${distance.toInt()}m';
    });
  }

  void _sendCurrentInstruction() {
    if (_currentRoute == null || _currentStepIndex >= _currentRoute!.length) {
      return;
    }

    final step = _currentRoute![_currentStepIndex];
    _speak('${step.maneuver} ahead, ${step.instruction}');
    _bleService.sendCommand(step.maneuver, step.distance);
  }

  void _finishNavigation() {
    _positionSubscription?.cancel();
    _bleService.sendCommand('arrived', 0);
    _speak('You have arrived at your destination');
    
    setState(() {
      _isNavigating = false;
      _statusMessage = 'Arrived at destination';
      _currentRoute = null;
      _currentStepIndex = 0;
    });
  }

  void _stopNavigation() {
    _positionSubscription?.cancel();
    _speak('Navigation stopped');
    
    setState(() {
      _isNavigating = false;
      _statusMessage = 'Navigation stopped';
      _currentRoute = null;
      _currentStepIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SenseTrail'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isConnected ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      size: 32,
                      color: _isConnected ? Colors.green[900] : Colors.red[900],
                      semanticLabel: _isConnected ? 'Connected' : 'Disconnected',
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _isConnected ? Colors.green[900] : Colors.red[900],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Status message
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              
              if (_destination.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Destination: $_destination',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 48),
              
              // Voice input button
              if (!_isNavigating)
                ElevatedButton.icon(
                  onPressed: _isConnected && !_isListening ? _startVoiceInput : null,
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 48,
                  ),
                  label: Text(
                    _isListening ? 'Listening...' : 'Start Navigation',
                    style: const TextStyle(fontSize: 24),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    backgroundColor: _isConnected ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                  ),
                ),
              
              // Stop navigation button
              if (_isNavigating) ...[
                ElevatedButton.icon(
                  onPressed: _stopNavigation,
                  icon: const Icon(Icons.stop, size: 48),
                  label: const Text(
                    'Stop Navigation',
                    style: TextStyle(fontSize: 24),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Help text
              if (!_isConnected)
                const Text(
                  'Please ensure the SenseTrail device is powered on and nearby.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _bleService.dispose();
    _speechService.dispose();
    _tts.stop();
    super.dispose();
  }
}

# SenseTrail - Accessible Navigation App

An accessible navigation application designed for blind and visually impaired users. The app integrates with a custom ESP32 haptic feedback controller to provide tactile navigation guidance.

## Features

- **Automatic BLE Connection**: Automatically connects to the SenseTrail ESP32 device
- **Voice-Activated Navigation**: Use your voice to specify destinations
- **Haptic Feedback**: Receive directional guidance through vibration patterns
- **Turn-by-Turn Navigation**: Real-time navigation with distance-based haptic intensity
- **Accessible UI**: High-contrast, large text interface with voice feedback
- **Open Source Routing**: Uses OpenStreetMap and OSRM (no API keys required)

## Project Structure

```
sense_trail_app/
├── lib/
│   ├── main.dart              # Main app UI and navigation flow
│   ├── ble_service.dart       # Bluetooth connection to ESP32
│   ├── speech_service.dart    # Voice recognition
│   └── navigation_service.dart # Map and routing logic
└── android/
    └── app/
        └── src/
            └── main/
                └── AndroidManifest.xml # Permissions configuration
```

## How It Works

1. **Device Connection**: On startup, the app automatically scans for and connects to the "SenseTrail" ESP32 device via Bluetooth Low Energy.

2. **Voice Input**: User taps the "Start Navigation" button and speaks their destination (e.g., "Navigate to Virudhunagar").

3. **Route Calculation**: 
   - App gets current GPS location
   - Geocodes destination using Nominatim API
   - Calculates route using OSRM API
   - Breaks route into turn-by-turn steps

4. **Haptic Guidance**: 
   - Sends direction commands to ESP32 (left/right/straight)
   - Vibration intensity varies with distance to next turn
   - Updates every 5 meters as user walks

5. **Arrival**: When destination is reached, plays arrival pattern and announces completion.

## ESP32 Communication Protocol

Commands are sent to ESP32 via BLE characteristic in the format:
```
direction:distance
```

**Examples:**
- `left:50.0` - Turn left in 50 meters
- `right:120.5` - Turn right in 120.5 meters
- `straight:200.0` - Continue straight for 200 meters
- `arrived:0.0` - Destination reached

**Vibration Patterns (defined in firmware):**
- **Left**: 2 short pulses (200ms each)
- **Right**: 3 shorter pulses (180ms each)
- **Straight**: 2 long pulses (300ms each)
- **Arrived**: 4 quick celebration pulses

## Setup Instructions

### Prerequisites

- Arch Linux with Flutter installed
- Android device with Bluetooth and GPS
- SenseTrail ESP32 device (programmed with provided firmware)

### Installation

1. **Navigate to project directory:**
   ```bash
   cd /home/s4ndy/Projects/SenseTrail/sense_trail_app
   ```

2. **Verify dependencies are installed:**
   ```bash
   flutter pub get
   ```

3. **Connect Android device via USB** (enable USB debugging in Developer Options)

4. **Verify device connection:**
   ```bash
   flutter devices
   ```

5. **Run the app:**
   ```bash
   flutter run
   ```

### First Run

On first launch, the app will request the following permissions:
- **Bluetooth**: To connect to ESP32
- **Location**: Required for BLE scanning and GPS navigation
- **Microphone**: For voice input

## Usage

1. **Power on the SenseTrail ESP32 device**
   - Device will advertise as "SenseTrail"
   - Blue LED should indicate it's ready

2. **Launch the app**
   - Wait for automatic connection (status shows "Connected" in green)
   - Voice feedback will announce connection status

3. **Start navigation**
   - Tap the large "Start Navigation" button
   - Wait for "Where would you like to go?" prompt
   - Speak your destination clearly (e.g., "Navigate to city hall")
   - App confirms destination and calculates route

4. **Follow haptic guidance**
   - Feel vibration patterns for directions
   - Listen to voice announcements for upcoming turns
   - Vibration intensity increases as you approach turns

5. **Stop navigation**
   - Tap "Stop Navigation" button if needed
   - Arrival is announced automatically when reached

## Voice Commands

The app recognizes these natural language patterns:
- "Navigate to [destination]"
- "Take me to [destination]"
- "Go to [destination]"
- "Directions to [destination]"
- "Route to [destination]"
- "Find [destination]"

Or simply speak the destination name directly.

## Troubleshooting

### Device Won't Connect
- Ensure ESP32 is powered on and within range
- Check that Bluetooth is enabled on phone
- Try toggling phone's Bluetooth off/on
- Restart the app

### Voice Recognition Not Working
- Check microphone permission is granted
- Ensure you're in a quiet environment
- Speak clearly after the prompt
- Wait for "Where would you like to go?" before speaking

### GPS/Location Issues
- Enable Location Services in phone settings
- Ensure Location permission is granted to app
- Use outdoors for better GPS signal
- Wait a few seconds for GPS lock

### Route Not Found
- Check internet connection (required for routing API)
- Try a more specific destination name
- Ensure destination is a real place
- Try adding city name (e.g., "Central Station, Chennai")

## Architecture

### BLE Service (`ble_service.dart`)
- Manages Bluetooth connection lifecycle
- Handles automatic reconnection
- Sends haptic commands to ESP32
- Broadcasts connection status

### Speech Service (`speech_service.dart`)
- Initializes speech recognition
- Captures voice input
- Extracts destination from spoken text
- Handles speech errors

### Navigation Service (`navigation_service.dart`)
- Gets current GPS location
- Geocodes text addresses to coordinates
- Calculates optimal walking routes
- Provides turn-by-turn instructions
- Converts OSRM maneuvers to simple directions

### Main UI (`main.dart`)
- Coordinates all services
- Displays connection status
- Manages navigation flow
- Provides voice feedback via TTS
- Updates UI based on navigation state

## APIs Used (No Keys Required)

- **Nominatim**: OpenStreetMap geocoding service
- **OSRM**: Open Source Routing Machine for walking routes
- **Geolocator**: Device GPS access

## Accessibility Features

- ✅ High contrast color scheme
- ✅ Large, readable text (20-32pt)
- ✅ Voice feedback for all actions
- ✅ Simple, uncluttered UI
- ✅ Large tap targets (48dp+)
- ✅ Semantic labels for screen readers
- ✅ No reliance on color alone for status

## Building for Release

```bash
flutter build apk --release
```

APK will be in: `build/app/outputs/flutter-apk/app-release.apk`

## Known Limitations

- Requires internet connection for routing
- GPS accuracy depends on device and environment
- Voice recognition quality varies by device
- Nominatim has usage limits (max 1 request/second)
- OSRM provides walking routes only (no driving)

## Future Enhancements

- Offline map support
- Multiple waypoints
- Points of interest discovery
- Emergency SOS activation
- Route history
- Customizable vibration patterns
- Multiple language support

## License

MIT License

## Credits

- OpenStreetMap contributors
- OSRM Project
- Flutter and Dart teams


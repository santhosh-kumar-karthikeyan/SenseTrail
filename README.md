# SenseTrail - Accessible Navigation System

An accessible navigation application designed for blind and visually impaired users, integrating a Flutter mobile app with ESP32 haptic feedback hardware.

## Project Structure

```
SenseTrail/
├── app/                    # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart              # Main UI and navigation coordinator
│   │   ├── ble_service.dart       # Bluetooth LE connection to ESP32
│   │   ├── speech_service.dart    # Voice recognition
│   │   └── navigation_service.dart # Route calculation & GPS
│   ├── android/                   # Android platform files
│   ├── pubspec.yaml              # Flutter dependencies
│   └── README.md                 # App documentation
│
└── firmware/               # ESP32 haptic controller
    └── esp32.ino                 # Arduino firmware for haptic feedback
```

## Features

- 🔵 **Automatic Bluetooth Connection** - Auto-connects to ESP32 on startup
- 🎤 **Voice-Activated Navigation** - Speak your destination naturally
- 📍 **Free Routing** - Uses OpenStreetMap (no API keys needed)
- 📳 **Haptic Feedback** - Vibration patterns for left/right/straight
- ♿ **Fully Accessible** - High contrast UI, voice feedback, screen reader support

## Quick Start

### 1. Upload ESP32 Firmware
```bash
# Using Arduino IDE:
# - Open firmware/esp32.ino
# - Select ESP32 board
# - Upload to device

cd firmware
# The ESP32 will advertise as "SenseTrail"
```

### 2. Build & Install Flutter App
```bash
cd app

# Install dependencies
flutter pub get

# Run on connected Android device
flutter run

# Or build APK
flutter build apk --release
# APK: app/build/app/outputs/flutter-apk/app-release.apk
```

### 3. Use the App
1. Power on ESP32 device
2. Open app (auto-connects to ESP32)
3. Tap "Start Navigation"
4. Speak your destination
5. Follow haptic vibration patterns

## How It Works

```
User speaks → App calculates route → Sends commands to ESP32 → 
Vibration patterns guide user → Voice announces turns → Arrival!
```

### ESP32 Commands
| Command | Pattern | Meaning |
|---------|---------|---------|
| `left:50.0` | 2 medium pulses | Turn left in 50m |
| `right:120.0` | 3 short pulses | Turn right in 120m |
| `straight:200.0` | 2 long pulses | Continue straight |
| `arrived:0.0` | 4 celebration bursts | Destination reached |

## Requirements

### Hardware
- ESP32 development board
- Vibration motor (connected to GPIO 5)
- Android phone (5.0+)

### Software
- Flutter SDK
- Arduino IDE (for ESP32)
- Android Studio (optional)

## Documentation

- **App Documentation**: See `app/README.md`
- **Build Guide**: See `app/BUILD_GUIDE.md`
- **Development Notes**: See `app/DEVELOPMENT.md`

## APIs Used (Free, No Keys)

- **Nominatim** - Geocoding (OpenStreetMap)
- **OSRM** - Walking route calculation
- **Geolocator** - Device GPS

## Accessibility

Designed following WCAG 2.1 principles:
- ✅ High contrast colors
- ✅ Large text (20-32pt)
- ✅ Voice feedback for all actions
- ✅ Screen reader compatible
- ✅ Simple, uncluttered UI

## License

MIT License

## Safety Notice

⚠️ **This is an assistive tool, not a replacement for:**
- White canes
- Guide dogs
- Personal awareness
- Common sense

Always use in conjunction with other accessibility aids.

## Contributing

Issues and pull requests welcome! Please ensure:
- Code is accessible and well-documented
- Features are tested with real hardware
- Follows existing code style

## Credits

- OpenStreetMap contributors
- OSRM Project
- Flutter and Dart teams

---

*Built with ❤️ for accessibility*

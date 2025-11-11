#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// BLE Configuration
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define DEVICE_NAME         "SenseTrail"

// Haptic configuration - UNCHANGED
const int tapticPin = 5;
const float walkingSpeed = 0.6;   // m/s typical for visually impaired
const int tapticPower = 180;      // vibration strength (0–255)

// BLE objects
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Command buffer
String lastCommand = "";

// Demo mode (for testing without app)
bool demoMode = false;

// BLE Server Callbacks
class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("✅ Device Connected!");
    // Signal connection with pattern
    patternConnected();
  }
  
  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("🔌 Device Disconnected!");
  }
};

// BLE Characteristic Callbacks - Receive commands from app
class MyCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String value = pCharacteristic->getValue();
    
    if (value.length() > 0) {
      Serial.print("📥 Received: ");
      Serial.println(value);
      
      // Parse command format: "direction:distance"
      int colonIndex = value.indexOf(':');
      if (colonIndex > 0) {
        String direction = value.substring(0, colonIndex);
        float distance = value.substring(colonIndex + 1).toFloat();
        
        Serial.println("Direction: " + direction + ", Distance: " + String(distance) + "m");
        
        // Execute haptic pattern
        if (direction.equalsIgnoreCase("left")) {
          patternLeft();
        } else if (direction.equalsIgnoreCase("right")) {
          patternRight();
        } else if (direction.equalsIgnoreCase("straight")) {
          patternStraight();
        } else if (direction.equalsIgnoreCase("arrived")) {
          patternFinish();
        } else if (direction.equalsIgnoreCase("sos")) {
          patternSOS();
        }
      }
    }
  }
};

// Demo path (≈5 minutes total)
struct Step { String direction; float distance; };
Step route[] = {
  {"straight", 10},
  {"left", 15},
  {"straight", 20},
  {"right", 10},
  {"straight", 25},
  {"left", 10},
  {"straight", 15},
  {"right", 20}
};
int totalSteps = sizeof(route) / sizeof(route[0]);
int currentStep = 0;
unsigned long stepStart = 0;
unsigned long waitTime = 0;
bool stepActive = false;
bool demoRunning = true;

void setup() {
  Serial.begin(115200);
  pinMode(tapticPin, OUTPUT);
  analogWrite(tapticPin, 0);
  
  Serial.println("🚀 SenseTrail ESP32 Starting...");
  delay(1000);
  
  // Initialize BLE
  BLEDevice::init(DEVICE_NAME);
  
  // Create BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  // Create BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  // Create BLE Characteristic
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  
  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->addDescriptor(new BLE2902());
  
  // Start service
  pService->start();
  
  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("✅ BLE Service Started!");
  Serial.println("📡 Broadcasting as: " + String(DEVICE_NAME));
  Serial.println("⏳ Waiting for connection...");
  
  // Connection indicator pattern
  vibrate(100);
  delay(100);
  vibrate(100);
}

void loop() {
  // Handle connection state changes
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
    Serial.println("📱 App Connected!");
  }
  
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // Give BLE stack time to get ready
    pServer->startAdvertising(); // Restart advertising
    Serial.println("📡 Restarting advertising...");
    oldDeviceConnected = deviceConnected;
  }
  
  // Optional: Check serial for demo commands
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    Serial.println("🎮 Demo command: " + cmd);
    
    if (cmd.equalsIgnoreCase("left")) {
      patternLeft();
    } else if (cmd.equalsIgnoreCase("right")) {
      patternRight();
    } else if (cmd.equalsIgnoreCase("straight")) {
      patternStraight();
    } else if (cmd.equalsIgnoreCase("sos")) {
      patternSOS();
    }
  }
  
  delay(10);
}

/* ---------- Helper functions ---------- */
void vibrate(int durationMs) {
  analogWrite(tapticPin, tapticPower);
  delay(durationMs);
  analogWrite(tapticPin, 0);
}

/* ---------- Vibration patterns (UNCHANGED) ---------- */

void patternLeft() {
  Serial.println("⬅️  LEFT");
  for (int i = 0; i < 2; i++) { vibrate(200); delay(150); }
}

void patternRight() {
  Serial.println("➡️  RIGHT");
  for (int i = 0; i < 3; i++) { vibrate(180); delay(150); }
}

void patternStraight() {
  Serial.println("⬆️  STRAIGHT");
  vibrate(300); delay(150); vibrate(300);
}

void patternFinish() {
  Serial.println("🎉 ARRIVED");
  for (int i = 0; i < 4; i++) { vibrate(150); delay(100); }
}

void patternConnected() {
  Serial.println("🔗 CONNECTED");
  vibrate(150); delay(100); vibrate(150);
}

void patternSOS() {
  Serial.println("🆘 SOS");
  // S: 3 short
  for (int i = 0; i < 3; i++) { vibrate(100); delay(100); }
  delay(200);
  // O: 3 long
  for (int i = 0; i < 3; i++) { vibrate(300); delay(100); }
  delay(200);
  // S: 3 short
  for (int i = 0; i < 3; i++) { vibrate(100); delay(100); }
}
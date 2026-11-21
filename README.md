# RGBZap Flutter Console (ELK-BLEDOM Windows Desktop Controller)

A modern, sleek dark-mode Windows desktop console in Flutter (Dart) designed to control Bluetooth Low Energy (BLE) **duoCo Strip / ELK-BLEDOM** RGB LED controllers (configured for hardware target `FF:FF:10:C5:29:1F`).

---

## ⚡ Key Features

- **Native Windows BLE Engine (`universal_ble`):** WinRT scanning, direct connection without Windows OS pairing dialogs, GATT service discovery, and `writeValue(..., withoutResponse: true)`.
- **Verified Hardware & GATT Protocol:** Generates exact 9-byte payloads (`0x7E ... 0xEF`) including the mandatory `300ms` delayed `0x83` initialization handshake.
- **55ms (~18 Hz) Coalescing Throttled Queue:** Prevents controller link loss and buffer overruns during rapid slider or color-wheel dragging by automatically dropping intermediate stale frames and guaranteeing delivery of critical state commands (Power, Handshake, Modes).
- **Auto-Reconnection Resilience:** Monitors connection changes and automatically recovers links if dropped unexpectedly.
- **Desktop Console Layout (`window_manager`):** Styled title bar, custom dimensions (`940x720`, min `540x680`), drag-to-move header, and graceful shutdown hooks (`Turn off lights on close`).
- **Interactive Chromatic Wheel & Swatches (`flutter_colorpicker`):** Live glowing preview with `#RRGGBB` hex badge, copy/paste, standard presets, and user custom swatches persisted via `shared_preferences`.
- **29 Built-in Hardware Effects (`0x80` to `0x9C`):** Filterable by category (*Crossfade*, *Fade*, *Strobe*, *Jump*, *Smooth*, *Flash*) with speed control (`1..100%`).
- **Software Animation Engine:** Smooth procedural animated scenes (*Cozy Fire*, *Cyberpunk Pulse*, *Ocean Breathe*, *RGB Cycle*).
- **Live BLE GATT Telemetry Log:** Real-time monospace terminal displaying every transmitted `TX` packet and event in real time with copy-to-clipboard support.

---

## 📡 Verified Hardware Protocol & GATT Specifications

| Parameter | Specification Value |
| :--- | :--- |
| **Target MAC / Device ID** | `FF:FF:10:C5:29:1F` |
| **Advertised Name Prefix** | `ELK-BLEDOM` |
| **Primary Service UUID** | `0000fff0-0000-1000-8000-00805f9b34fb` (short: `fff0`) |
| **Write Characteristic UUID**| `0000fff3-0000-1000-8000-00805f9b34fb` (short: `fff3`) |
| **Write Property** | `BleOutputProperty.withoutResponse` |
| **Rate Throttling** | `55ms` (~18 Hz) Coalescing Queue |

### 9-Byte Command Payloads

1. **Mandatory Handshake (300ms post-connect):**
   ```text
   7E 07 83 02 01 01 01 00 EF
   ```
2. **Master Power ON:**
   ```text
   7E 04 04 F0 00 01 FF 00 EF
   ```
3. **Master Power OFF:**
   ```text
   7E 04 04 00 00 00 FF 00 EF
   ```
4. **Solid RGB Color:**
   ```text
   7E 07 05 03 [R] [G] [B] 10 EF   (R, G, B in 0..255)
   ```
5. **Brightness:**
   ```text
   7E 04 01 [LEVEL] 01 FF FF 00 EF  (LEVEL in 1..100)
   ```
6. **Built-in Hardware Effect Mode:**
   ```text
   7E 05 03 [MODE_ID] 03 FF FF 00 EF  (MODE_ID in 0x80..0x9C)
   ```
7. **Hardware Effect Speed:**
   ```text
   7E 04 02 [SPEED] 00 00 00 00 EF  (SPEED in 1..100)
   ```

---

## 📂 Project Architecture

```
lib/
├── main.dart                       # Desktop window setup, dark theme & provider root
├── protocol/
│   └── elk_protocol.dart           # Pure Dart 9-byte packet generator & effect catalog
├── services/
│   └── ble_led_service.dart        # UniversalBle central, 55ms throttled queue, state & scenes
└── ui/
    ├── console_screen.dart         # Main desktop shell, header bar, device selector & tabs
    ├── tabs/
    │   ├── light_tab.dart          # Chromatic wheel, hex badge, power pills, brightness & swatches
    │   ├── effects_tab.dart        # 29 hardware effects catalog (0x80-0x9C) & speed slider
    │   ├── scenes_tab.dart         # Software animation loops (Cozy Fire, Cyberpunk, Ocean, RGB)
    │   └── system_tab.dart         # Preferences, GATT specs, and real-time live hex log
    └── widgets/
        ├── glowing_card.dart       # Zinc-900 surface with dynamic accent color glow
        └── hex_log_viewer.dart     # Monospace real-time GATT packet terminal
test/
├── elk_protocol_test.dart          # Protocol validation & clamping unit tests
└── widget_test.dart                # Sanity test suite
```

---

## 🚀 Running the Application

### 1. Fetch Dependencies
```bash
flutter pub get
```

### 2. Run on Windows Desktop
```bash
flutter run -d windows
```

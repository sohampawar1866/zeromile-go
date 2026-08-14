# 📱 ZeroMile Go — Flutter Mobile Application (`frontend/`)

This directory contains the standalone **Flutter Mobile Application** for ZeroMile Go.

---

### 🚀 Quick Start for Mobile Developers (3 Steps)

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Connect your physical Android phone (or iOS device) via USB:**
   ```bash
   flutter devices
   ```

3. **Launch the app on your phone:**
   ```bash
   flutter run
   ```

---

### 📂 Directory Architecture

```text
frontend/
├── lib/
│   ├── config/              # AppConfig & environment management
│   ├── models/              # Typed DTO Data Models (User, Domain, Group, SOS, Broadcast, etc.)
│   ├── services/            # Supabase BaaS, Auth, Group, SOS, Telemetry & Push Services
│   ├── utils/               # DensityClusterEvaluator & Spatial Algorithms
│   ├── flutter_core.dart    # Export barrel library
│   └── main.dart            # Complete Interactive Mobile UI & Persona Switcher
├── android/                 # Android Native Runner & Manifest
├── ios/                     # iOS Xcode Runner & Entitlements
└── pubspec.yaml             # Flutter Dependencies
```

---

### 🧪 Pre-Seeded Test Personas (Fixed OTP: `123456`)

* **Participant:** `+91 98240 11111` (Priya Verma — 1-Tap Check-In / Finish / SOS)
* **Group Leader:** `+91 98230 11111` (Aniket Deshmukh — VNIT Cycling Club)
* **SuperAdmin:** `+91 98220 11111` (Rajesh Sharma — Emergency Command & Broadcasts)

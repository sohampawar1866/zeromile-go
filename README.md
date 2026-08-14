# ZeroMile Go — Multi-Rally & Event Management Platform

[![Supabase BaaS](https://img.shields.io/badge/Supabase-PostgreSQL%20%7C%20Realtime-3ECF8E?logo=supabase)](https://supabase.com)
[![Flutter](https://img.shields.io/badge/Flutter-Android%20%7C%20iOS%20%7C%20Web-02569B?logo=flutter)](https://flutter.dev)
[![OneSignal](https://img.shields.io/badge/Push-OneSignal-E54B4D?logo=onesignal)](https://onesignal.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

ZeroMile Go is an event coordination, crowd safety, and real-time telemetry management platform built for civic rallies, marathons, walkathons, and cycling events.

---

## 📁 Clean Repository Structure (Frontend / Backend Separation)

```text
.
├── frontend/                        # 📱 Complete Standalone Flutter Mobile App
│   ├── lib/
│   │   ├── config/                  # AppConfig & Environment Manager
│   │   ├── models/                  # 10 Typed DTO Models (JSON, copyWith, null-safe)
│   │   ├── services/                # 8 Supabase Services (Auth, SOS, Groups, Telemetry, Push)
│   │   ├── utils/                   # Linear Spatial Grid Clustering & Temporal Window
│   │   ├── flutter_core.dart        # Barrel Library Export
│   │   └── main.dart                # Interactive Mobile UI & Persona Switcher
│   ├── android/                     # Android Native Runner & Manifest
│   ├── ios/                         # iOS Xcode Runner & Entitlements
│   └── pubspec.yaml                 # Flutter Dependencies
│
├── backend/                         # ⚙️ Database BaaS & Verification Workbench
│   ├── supabase/
│   │   ├── migrations/              # Core Schema (10 Tables, RLS, Triggers, RPCs) & Patches
│   │   └── seed.sql                 # Pre-seeded Nagpur Rally Event Data
│   └── web_prototype/               # Interactive Multi-Role Reference Workbench (45-Rider Sim)
│
├── .env.example                     # Environment variables template
├── .gitignore                       # Git ignore definitions
├── PROJECT_PLAN.md                  # Comprehensive blueprint
└── README.md                        # Master Project Documentation
```

---

## 📱 Quickstart for Mobile Developers (`frontend/`)

1. Navigate to the `frontend/` directory:
   ```bash
   cd frontend
   ```
2. Connect your Android phone via USB debugging (or start an emulator) and verify it is connected:
   ```bash
   flutter devices
   ```
3. Run the live mobile app:
   ```bash
   flutter run
   ```

---

## ⚙️ Quickstart for Backend Workbench (`backend/`)

Launch the web testing simulation engine in your browser:
```bash
python3 -m http.server 8085 --directory backend/web_prototype
```
Open **`http://localhost:8085`** in Google Chrome or Safari to test:
* Fast persona switching across **Participant**, **Group Leader**, **SuperAdmin**, and **Developer**.
* **Live Crowd Simulator (45 Riders)** moving along Nagpur's Zero Mile loop.

---

## 🔑 Test Whitelist Personas (Fixed OTP: `123456`)

| Role | Name | Phone Number | Group Affiliation | Key Screen / Action |
|---|---|---|---|---|
| **SuperAdmin** | Rajesh Sharma | `+91 98220 11111` | Seated Admin (1/6) | Governance, Approvals & Escalated SOS Queue |
| **SuperAdmin** | Sunita Deshmukh | `+91 98220 22222` | Seated Admin (2/6) | Route & Schedule Builder |
| **Group Leader** | Aniket Deshmukh | `+91 98230 11111` | VNIT Cycling Club | Team Triage, Direct Add by Phone, Broadcast |
| **Group Leader** | Neha Verma | `+91 98230 22222` | Orange City Sprinters | Contingent Roster & Attendance Stats |
| **Participant** | Priya Verma | `+91 98240 11111` | VNIT Cycling Club | Check-in, Completed, Floating SOS FAB |
| **Participant** | Rohan Gupta | `+91 98240 22222` | VNIT Cycling Club | Active telemetry ping |
| **General Rider** | Rahul Wankhede | `+91 98240 44444` | General Group Only | Domain muster attendance |

---

## 📄 License
MIT License. Developed for the Nagpur Civic Hackathon 2026.

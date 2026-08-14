# ZeroMile Go — Multi-Rally & Event Management Platform

[![Supabase BaaS](https://img.shields.io/badge/Supabase-PostgreSQL%20%7C%20Realtime-3ECF8E?logo=supabase)](https://supabase.com)
[![Flutter](https://img.shields.io/badge/Flutter-Android%20%7C%20iOS%20%7C%20Web-02569B?logo=flutter)](https://flutter.dev)
[![OneSignal](https://img.shields.io/badge/Push-OneSignal-E54B4D?logo=onesignal)](https://onesignal.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

ZeroMile Go (Vikasit Nagpur) is an event coordination, crowd safety, and real-time telemetry management platform built for civic rallies, marathons, walkathons, and cycling events in Nagpur.

---

## 📁 Clean Repository Structure

```text
.
├── frontend/                        # 📱 Flutter Mobile Application
│   ├── lib/
│   │   ├── config/                  # Design tokens, Nike athletic theme, app configuration
│   │   ├── models/                  # 10 Strongly-typed DTO Models (JSON & null-safe)
│   │   ├── services/                # Direct Supabase BaaS Service layer (Auth, SOS, Groups, Telemetry, Broadcast)
│   │   ├── logic/view_models/       # Layered MVVM ChangeNotifier ViewModels
│   │   ├── ui/                      # Material 3 UI (Navigation shell, Dev Panel, Admin Console, Leader Hub, Home)
│   │   ├── utils/                   # Spatial Density Clustering & Temporal Window Evaluator
│   │   ├── flutter_core.dart        # Barrel library export
│   │   └── main.dart                # Application bootstrap & multi-domain controller
│   ├── test/                        # Automated unit, model serialization, logic, and widget tests
│   └── pubspec.yaml                 # Flutter 3.x dependencies
│
├── backend/                         # ⚙️ Supabase PostgreSQL BaaS & Web Workbench
│   ├── supabase/
│   │   ├── migrations/              # Core schema (10 tables, RLS, triggers, stored procedures)
│   │   └── seed.sql                 # Official Nagpur Event Domains, Routes, Checkpoints & Seed Data
│   └── web_prototype/               # Standalone multi-role reference workbench with 45-rider GPS simulator
│
├── docs/                            # Design tokens, rules, and Nike athletic system guidelines
├── PROJECT_PLAN.md                  # Comprehensive architectural blueprint
└── README.md                        # Master Project Documentation
```

---

## 📱 Quickstart for Mobile Developers (`frontend/`)

1. Navigate to the `frontend/` directory:
   ```bash
   cd frontend
   ```
2. Verify connected device or start an emulator:
   ```bash
   flutter devices
   ```
3. Run the live mobile app:
   ```bash
   flutter run
   ```

---

## ⚙️ Quickstart for Web Workbench (`backend/`)

Launch the web testing simulation engine in your browser:
```bash
python3 -m http.server 8085 --directory backend/web_prototype
```
Open **`http://localhost:8085`** in your browser to test:
* Fast persona switching across **Participant**, **Group Leader**, **SuperAdmin**, and **Developer**.
* **Live Crowd Simulator (45 Riders)** moving along Nagpur's Zero Mile loop.

---

## 🔑 Authentication & Master Access

ZeroMile Go uses **Supabase Native Phone Authentication**:
* **Developer Master Console**: `+91 8087167841` (Soham Pawar) — Configured test OTP: `123456`.
* **Domain Role Resolution**: When logged in, your role is dynamically resolved per event domain (SuperAdmin in Cycling Rally, Group Leader in Marathon, Citizen Participant in Protest Rally).
* **Domain Switcher**: Universal `[ 🔄 SWITCH EVENT DOMAIN ]` drawer action to transition between active event domains.

---

## 📄 License
MIT License. Developed for the Nagpur Civic Hackathon 2026.

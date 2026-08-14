# ZeroMile Go — Multi-Rally & Event Management Platform

[![Supabase BaaS](https://img.shields.io/badge/Supabase-PostgreSQL%20%7C%20Realtime-3ECF8E?logo=supabase)](https://supabase.com)
[![Flutter Core](https://img.shields.io/badge/Flutter-Dart%203.0%2B-02569B?logo=flutter)](https://flutter.dev)
[![OneSignal](https://img.shields.io/badge/Push-OneSignal-E54B4D?logo=onesignal)](https://onesignal.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

ZeroMile Go is an event coordination, crowd safety, and real-time telemetry management platform built for civic rallies, marathons, walkathons, and cycling events.

---

## 🌟 Key Architecture & Features

### 1. 🏢 Multi-Tenant Event Domain Segregation
* Complete logical separation of routes, muster points, contingents, and telemetry across concurrent events (e.g. *Cycling Rally 2026*, *Nagpur City Marathon*, *Walkathon*).
* Temporal window evaluator automatically gates live active telemetry vs. static pre/post event schedules.

### 2. 👥 Strict Contingent Governance (3-SubGroup Limit & 1-Active Group Invariant)
* **Max 3 Sub-Groups**: PostgreSQL trigger backed by advisory transaction locks (`pg_advisory_xact_lock`) prevents participants from joining > 3 contingents.
* **Single Active Sub-Group**: Database partial unique index and atomic `set_active_group` RPC guarantees exactly 1 active contingent per user per domain for GPS telemetry and emergency routing.
* **Auto-General Group Enrollment**: All participants joining any sub-group are automatically enrolled in the domain's root General Group.
* **Sub-Group Creation Proposals**: In-app application workflow with SuperAdmin approval triggers that auto-create contingents and promote applicants to Group Leaders.

### 3. 📍 1-Tap Presence & Completion Lifecycle
* **`[ 📍 Check-in / Present ]`**: Atomic RPC records muster arrival (`CHECKED_IN`) and activates live telemetry.
* **`[ 🏁 Mark Completed ]`**: Atomic RPC logs rally finish (`COMPLETED`) and generates participation records.

### 4. 🚨 Context-Aware Emergency SOS Triage Pipeline
```mermaid
sequenceDiagram
    autonumber
    actor Participant as Participant
    actor Leader as Group Leader
    actor Admin as SuperAdmin Command Center
    
    Participant->>Participant: Taps Floating SOS Button (Medical / Breakdown / Threat)
    Participant->>Leader: Realtime Alert in Team Hub Triage
    alt Resolved by Contingent
        Leader->>Leader: Taps "Resolve Locally"
    else Escalated to Command Center
        Leader->>Admin: Forwards with Triage Note ("Ambulance required near Samvidhan Sq")
        Admin->>Admin: Realtime Escalated Queue -> Taps "Dispatch Ambulance & Mark Resolved"
    end
```

### 5. 📣 Two-Tier High-Priority Broadcast System
* **SuperAdmins**: Dispatch alerts domain-wide (General Group) or target specific sub-groups.
* **Group Leaders**: Dispatch operational updates scoped strictly to their own contingent.
* Dual delivery via **Supabase Realtime WebSockets** (in-app banner) and **OneSignal Push Notifications** (lockscreen).

### 6. 🗺️ Real-Time GPS Telemetry & Vector Dynamic Density Shading
* Spatial clustering with linear $O(N)$ grid bucketing rendering real-time crowd volume:
  * **1 – 24 Riders**: Soft Cyan (`#51BBD6`, radius 14px)
  * **25 – 99 Riders**: Sky Blue (`#3BB2D0`, radius 20px)
  * **100 – 299 Riders**: Amber / Yellow (`#F1F075`, radius 26px)
  * **300 – 599 Riders**: Coral Red (`#E55E5E`, radius 34px)
  * **600+ Riders**: Deep Intense Purple (`#7B1FA2`, radius 44px)

### 7. 🛰️ Built-In Live Crowd Movement Simulator
* Interactive testing engine simulating 45 riders moving along Nagpur's **Zero Mile Monument $\rightarrow$ Samvidhan Sq $\rightarrow$ Shankar Nagar $\rightarrow$ Law College Sq $\rightarrow$ Deekshabhoomi** route.

---

## 📁 Repository Structure

```text
.
├── PROJECT_PLAN.md                  // Complete architectural blueprint
├── README.md                        // This file
├── .env.example                     // Environment variables template
├── .gitignore                       // Git ignore definitions
├── flutter_core/                    // Production Dart Data & Service Layer
│   ├── lib/
│   │   ├── flutter_core.dart        // Barrel export file
│   │   ├── models/                  // 10 Typed DTO Models (with copyWith & JSON)
│   │   ├── services/                // 8 Production Service Repositories
│   │   └── utils/                   // Density Clustering & Temporal Window
│   └── pubspec.yaml                 // Dart package dependencies
├── supabase/                        // Database BaaS Configurations
│   ├── migrations/
│   │   ├── 20260814_zeromilego_core_schema.sql
│   │   └── 20260814_zeromilego_security_audit_patch.sql
│   └── seed.sql                     // Pre-seeded Nagpur rally domain data
└── web_prototype/                   // Interactive Multi-Role Reference Workbench
    ├── index.html                   // HTML structure for all 5 perspectives
    ├── style.css                    // Custom CSS styling & map overrides
    └── app.js                       // Leaflet maps, Realtime client & simulator
```

---

## 🔑 Test Whitelist Personas (OTP: `123456`)

| Role | Name | Phone Number | Group Affiliation | Key Screen / Action |
|---|---|---|---|---|
| **SuperAdmin** | Rajesh Sharma | `+91 98220 11111` | Seated Admin (1/6) | Governance & Escalated SOS Queue |
| **SuperAdmin** | Sunita Deshmukh | `+91 98220 22222` | Seated Admin (2/6) | Route & Schedule Builder |
| **Group Leader** | Aniket Deshmukh | `+91 98230 11111` | VNIT Cycling Club | Team Triage, Direct Add by Phone, CSV Export |
| **Group Leader** | Neha Verma | `+91 98230 22222` | Orange City Sprinters | Contingent Roster & Team Broadcast |
| **Participant** | Priya Verma | `+91 98240 11111` | VNIT Cycling Club | Check-in, Completed, Floating SOS FAB |
| **Participant** | Rohan Gupta | `+91 98240 22222` | VNIT Cycling Club | Active telemetry ping |
| **Participant** | Sameer Khan | `+91 98240 66666` | Multi-Group Member | Sub-group switching modal |
| **General Rider** | Rahul Wankhede | `+91 98240 44444` | General Group Only | Domain muster attendance |

---

## 🚀 Quickstart & Testing

### 1. Run the Interactive Verification Prototype
```bash
python3 -m http.server 8085 --directory web_prototype
```
Open [http://localhost:8085](http://localhost:8085) in your browser:
* Click through the **Persona Pills** at the top right to switch between **Participant**, **Group Leader**, **SuperAdmin**, **Developer Panel**, and **Onboarding**.
* Click **`[ ▶️ Run Live Crowd Sim (45 Riders) ]`** to watch 45 riders animate in real time along Nagpur's Zero Mile loop.

### 2. Flutter Integration

Add `flutter_core` to your Flutter app or copy `flutter_core/lib/` directly into your project:

```dart
import 'package:flutter_core/flutter_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Supabase
  await SupabaseClientService.initialize();
  
  // 2. Initialize OneSignal Push Notifications
  await PushNotificationService.initialize(appId: 'YOUR_ONESIGNAL_APP_ID');

  runApp(const MyApp());
}

// Check-in participant at muster point:
final groupService = GroupService();
await groupService.checkInParticipant(
  domainId: activeDomainId,
  groupId: activeGroupId,
  userId: currentUserId,
);

// Stream Live SOS Queue:
final sosService = SosService();
sosService.streamSosEvents(activeDomainId).listen((sosList) {
  // Update emergency badge & alert tone
});
```

---

## 📄 License
MIT License. Developed for the Nagpur Civic Hackathon 2026.

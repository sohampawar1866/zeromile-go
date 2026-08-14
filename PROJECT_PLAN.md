# Vikasit Nagpur - Multi-Rally & Event Management Platform
## Comprehensive Project Blueprint & Technical Specification

---

## 1. Executive Summary & Core Paradigm
**Vikasit Nagpur** is a modular, multi-tenant event and rally management ecosystem designed to orchestrate large-scale public rallies, sports competitions, civic protests, and mass gatherings (e.g., **Cycling Rallies, City Marathons, Citizen Protest Rallies, Peace Marches, Environmental Walkathons**).

### Key Architectural Pillars
1. **Complete Rally-Domain Isolation (Multi-Tenancy)**:
   * Each event type operates as a strictly segregated domain/tenant.
   * Data, rosters, SuperAdmins, Group Leaders, groups, announcements, broadcasts, and feeds are 100% isolated per event domain.
   * **Contextual Role Resolution**: A single user phone profile can hold different roles across different domains (e.g., **SuperAdmin** in Cycling Rally, **Group Leader** in Marathon, and **General Member** in Protest Rally).
   * The navigation sidebar with `[ 🔄 SWITCH EVENT DOMAIN ]` is universally accessible across all user, leader, and admin interfaces, switching the user seamlessly into their appropriate domain-specific role.
2. **Hierarchical Role & Permission Architecture**:
   * **Developer / System Admin**: Seeds and provisions 5–6 SuperAdmins per domain via a dedicated Developer Panel; monitors cross-domain global analytics.
   * **SuperAdmins (5–6 per domain)**: Gatekeepers of the domain; manage the mandatory **General Group**, set the official rally route & waypoints, monitor domain-wide live participant density with group filters, approve/reject requests, broadcast alerts, and analyze domain metrics in dedicated tabs.
   * **Group Leaders**: Appointed upon SuperAdmin approval of a group creation form. Primary tools include a dedicated **Live Team Map** with dynamic density shading, member management, own-group broadcasts, first-response SOS triage, and a dedicated Team Analytics tab.
   * **General Users / Participants**: Belong to the General Group; can join at most **3 Sub-Groups** (with exactly **1 Active Group** at a time). Any user can discreetly apply to create a new group via a subtle link in the sidebar footer.
3. **Structured, Uncluttered Tab Architecture**:
   * **SuperAdmin Console**: 4 Dedicated Tabs $\rightarrow$ `[ 🛡️ Governance ]`, `[ 📍 Live Map ]`, `[ 🗺️ Route ]`, `[ 📊 Analytics ]`.
   * **Group Leader Hub**: 3 Dedicated Tabs $\rightarrow$ `[ 👥 Team Hub ]`, `[ 📍 Live Map ]`, `[ 📊 Analytics ]`.
   * **Developer Panel**: 2 Dedicated Tabs $\rightarrow$ `[ 🔑 Provisioning ]`, `[ 📊 Analytics ]`.
4. **Dynamic Density Color Shading (Live Tracking)**:
   * Real-time GPS pings are aggregated to dynamically adjust color density / intensity shading in high-concentration zones.
   * SuperAdmin can view all domain participants or filter by specific sub-groups; Group Leaders see density shading strictly for their own contingent.
5. **Context-Aware Emergency SOS Escalation**:
   * **Active Sub-Group Member**: SOS routes directly to **Group Leader**, who can resolve locally or forward to SuperAdmins with an attached note.
   * **General-Only User**: SOS routes directly to **SuperAdmins**.
6. **Event Temporal Window & Lifecycle Enforcement**:
   * **SuperAdmin Configured Timings**: SuperAdmin sets official event schedule (`event_date`, `start_time`, `end_time`).
   * **Active Event Window (`start_time` <= now <= `end_time`)**: Live map, GPS telemetry streaming, route navigation, and floating SOS button are **100% ACTIVE**.
   * **Outside Event Window (Pre-Event or Post-Event Concluded)**: Live map tracking, GPS streaming, and SOS emergency buttons are **DEACTIVATED**. Users can only perform non-event administrative actions (joining/exiting sub-groups, editing profile/emergency contacts, submitting group applications, viewing past broadcasts/static route).

---

## 2. User Hierarchy & Role Permission Matrix

```text
+--------------------------------------------------------------------------------------------------+
| LEVEL 0: DEVELOPER PANEL (Devs)                                                                  |
| • Creates & manages Event Domains (Marathons, Protest Rallies, Cycling, etc.)                    |
| • Direct provisioning of 5 to 6 SuperAdmins per Event Domain                                     |
| • 📊 DEDICATED TAB: Global Cross-Domain Analytics (Total turnout, domain health, SOS metrics)    |
+--------------------------------------------------------------------------------------------------+
                                               │
                                               ▼
+--------------------------------------------------------------------------------------------------+
| LEVEL 1: SUPERADMINS (5–6 per isolated domain)                                                   |
| • 🛡️ TAB 1: GOVERNANCE - General Group approvals, sub-group proposals, broadcast tool, SOS queue  |
| • 📍 TAB 2: LIVE MAP - Domain-wide live tracking with Dynamic Density Shading & Sub-Group filter |
| • 🗺️ TAB 3: ROUTE & SCHEDULE - Sets official route, waypoints, water/medical posts, START/END TIME|
| • 📊 TAB 4: ANALYTICS - Domain-wide participation, route traffic, incident turnaround SLA stats  |
+--------------------------------------------------------------------------------------------------+
                                               │
                                               ▼
+--------------------------------------------------------------------------------------------------+
| LEVEL 2: GROUP LEADERS                                                                           |
| • 👥 TAB 1: TEAM HUB - Member roster, direct phone add (auto-general), team broadcast, SOS triage|
| • 📍 TAB 2: LIVE MAP - Dedicated team GPS tracking with Dynamic Density Shading for own group    |
| • 📊 TAB 3: ANALYTICS - Team muster check-in %, active rider count, completion rate, export CSV  |
+--------------------------------------------------------------------------------------------------+
                                               │
                                               ▼
+--------------------------------------------------------------------------------------------------+
| LEVEL 3: USERS / PARTICIPANTS                                                                    |
| • Mandatory membership: GENERAL GROUP (domain-wide feed & broadcasts)                            |
| • Sub-Group membership cap: CAN JOIN AT MOST 3 SUB-GROUPS per domain                             |
| • Active Group constraint: CAN BE "ACTIVE" IN ONLY 1 SUB-GROUP AT A TIME                          |
| • 📝 GROUP CREATION APPLICATION: Discreet sidebar link opening multi-event org dropdown form     |
| • 🚨 SOS TRIGGER: Bottom-right FAB (routes to Group Leader if active, or SuperAdmin if general)  |
+--------------------------------------------------------------------------------------------------+
```

---

## 3. UI/UX Wireframes (ASCII Templates)

### Screen 0: User Onboarding & Identity Flow (`/onboarding`)

#### Screen 0A: Phone Number Authentication (`/onboarding/phone`)
```text
+------------------------------------------+
| 🚲 ZEROMILE GO - VIKASIT NAGPUR          |
+------------------------------------------+
| Welcome Citizen!                         |
| Enter your mobile phone number to begin: |
|                                          |
| Phone Number:                            |
| [ 🇮🇳 +91 | 98230-12345                 ] |
|                                          |
| [ 📲 SEND 6-DIGIT OTP VERIFICATION     ] |
+------------------------------------------+
| 🔒 Instant verification via SMS OTP      |
+------------------------------------------+
```

#### Screen 0B: OTP Verification & Profile Creation (`/onboarding/profile`)
```text
+------------------------------------------+
| [<] VERIFY & SETUP PROFILE               |
+------------------------------------------+
| Enter 6-digit OTP sent to +91 98230-12345|
| [ ● ] [ ● ] [ ● ] [ ● ] [ ● ] [ ● ]      |
| [ Resend OTP in 24s ]                    |
|                                          |
| ── Citizen Profile Details ────────────── |
| 1. Full Name:                            |
|    [ Rajesh Sharma                     ] |
|                                          |
| 2. Emergency Contact (Next of Kin Phone):|
|    [ +91 98221-99999                   ] |
|                                          |
| [ 🚀 COMPLETE PROFILE & CONTINUE       ] |
+------------------------------------------+
```

#### Screen 0C: Select Active Event Domain & Permissions (`/onboarding/domain-select`)
```text
+------------------------------------------+
| 🗺️ SELECT YOUR RALLY / EVENT             |
+------------------------------------------+
| Choose which event you are attending:    |
|                                          |
| +--------------------------------------+ |
| | [● SELECTED]                         | |
| | 🚲 Cycling Rally 2026                | |
| | 🕒 15-Nov-2026 (06:00 AM - 11:30 AM) | |
| | 📍 Samvidhan Sq -> Deekshabhoomi     | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | 🏃 Nagpur City Marathon 2026         | |
| | 🕒 22-Nov-2026 (05:30 AM)            | |
| +--------------------------------------+ |
|                                          |
| ── Required Event Permissions ────────── |
| 📍 Live Location Permission:             |
| Needed during event window for live      |
| tracking, safety muster & emergency SOS. |
|                                          |
| [ ✅ ENTER EVENT (Auto-join General)   ] |
+------------------------------------------+
```

---

### Screen 1: User Home Dashboard - ACTIVE EVENT WINDOW (`/home`)
```text
+------------------------------------------+
| [=] 🚲 CYCLING RALLY 2026        [🔔 (2)] |
+------------------------------------------+
| 🏁 EVENT PARTICIPATION STATUS:           |
| [ STATE: 🟡 NOT CHECKED-IN AT MUSTER   ] |
|                                          |
| Quick Actions:                           |
| [ 📍 CHECK-IN / MARK PRESENT AT MUSTER ] | <-- Tapping marks checkin_time
| [ 🏁 MARK FINISHED / COMPLETED RALLY   ] | <-- Tapping records completion_time
+------------------------------------------+
| 🗺️ INTERACTIVE LIVE RALLY ROUTE MAP       |
| +--------------------------------------+ |
| | [📍 You]      === Route ===> [🏁 Fin] | |
| | Water Point 1: Shankar Nagar Sq (2km)| |
| | Medical Post : Law College Sq  (5km) | |
| | [ 🔍 Fullscreen / Route Details ]    | |
| +--------------------------------------+ |
+------------------------------------------+
| 📢 LATEST BROADCASTS                     |
| +--------------------------------------+ |
| | 🚨 SUPERADMIN: "Flag-off at 06:00 AM | |
| |    from Zero Mile Monument."         | |
| | 📣 LEADER NOTE: "Assemble at Gate 1  | |
| |    by 05:30 AM sharp."               | |
| +--------------------------------------+ |
+------------------------------------------+
| YOUR ACTIVE SUB-GROUP:                   |
| +--------------------------------------+ |
| | 🎓 VNIT Cycling Club        [Leader] | |
| | Members: 38 | Status: Check-in Open  | |
| | [ Open Group Chat & Roster > ]       | |
| | [ 🔄 Change Active Group ]           | |
| |   ↳ (Tapping redirects to Groups tab)| |
| +--------------------------------------+ |
+------------------------------------------+
| [ 🏠 Home ]  [ 💬 Chat ]  [ 👥 Groups ]  |
|                                          |
|                                [🚨 SOS]  | <-- Floating Action Button (Live Only)
+------------------------------------------+
```

---

### Screen 1B: User Home Dashboard - PRE/POST EVENT WINDOW (`/home`)
```text
+------------------------------------------+
| [=] 🚲 CYCLING RALLY 2026        [🔔 (1)] |
+------------------------------------------+
| 🏁 EVENT STATUS: CONCLUDED / PRE-EVENT   |
| 🕒 Schedule: 15-Nov-2026 (06:00 - 11:30) |
+------------------------------------------+
| 🗺️ PUBLISHED ROUTE PREVIEW (STATIC)      |
| +--------------------------------------+ |
| | [ Zero Mile ] === Route ===> [ Finish] |
| | ℹ️ Live GPS tracking & SOS inactive.  |
| | [ 🔍 View Full Static Route Map ]     |
| +--------------------------------------+ |
+------------------------------------------+
| 📢 EVENT ANNOUNCEMENTS                   |
| +--------------------------------------+ |
| | ℹ️ "Event closed. Certificates ready | |
| |    for download in profile."         | |
| +--------------------------------------+ |
+------------------------------------------+
| YOUR SUB-GROUPS:                         |
| +--------------------------------------+ |
| | 🎓 VNIT Cycling Club        [Leader] | |
| | 38 Members enrolled                  | |
| | [ Manage / Edit Group Members > ]    | |
| | [ + Join / Exit Sub-Groups ]         | |
| +--------------------------------------+ |
+------------------------------------------+
| [ 🏠 Home ]  [ 💬 Chat ]  [ 👥 Groups ]  |
| (Note: SOS button hidden when inactive)  |
+------------------------------------------+
```

---

### Screen 2: Dedicated Groups Management Tab (`/groups`)
```text
+------------------------------------------+
| [<]  MY SUB-GROUPS (2/3 Enrolled)        |
+------------------------------------------+
| Select which group is ACTIVE for today's |
| rally tracking, muster, and SOS routing: |
|                                          |
| +--------------------------------------+ |
| | [● CURRENTLY ACTIVE]                 | |
| | 🎓 VNIT Cycling Club        [Leader] | |
| | 38 Members • Muster: Ambazari Gate   | |
| | ℹ️ SOS will route to: Rajesh (Leader)| |
| | [ Open Group Hub > ]                 | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | [○ INACTIVE]                         | |
| | ⚡ Orange City Sprinters              | |
| | Leader: Neha V. • 28 Members         | |
| | [ 👉 Set as Active Group ]           | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | [ + Join / Request 3rd Sub-Group ]   | |
| +--------------------------------------+ |
+------------------------------------------+
| [ 🏠 Home ]  [ 💬 Chat ]  [ 👥 Groups ]  |
+------------------------------------------+
```

---

### Screen 3: Navigation Sidebar (Drawer) with Universal Domain Switcher
```text
+------------------------------------------+
| 🚲 CYCLING RALLY 2026         [Close ✕]  |
+------------------------------------------+
| 👤 Rajesh Sharma                         |
| 📞 +91 98230-XXXXX                       |
| [ ✏️ Edit Profile ]                      |
+------------------------------------------+
| 🏠 Home Dashboard                        |
| 📢 General Broadcasts Feed               |
| 👥 My Sub-Groups (2/3)                   |
| 📋 My Rally Pass / QR Code               |
+------------------------------------------+
|                                          |
|                                          |
| (Discreet Footer Section)                |
| ──────────────────────────────────────── |
| Have an organization/team?               |
| [ 📋 Request to create a group > ]       |
| ──────────────────────────────────────── |
| [ 🔄 SWITCH EVENT DOMAIN               ] | <-- Fixed at very bottom
+------------------------------------------+
```

---

### Screen 4: Universal Group Creation Request Modal (`/request-group`)
```text
+------------------------------------------+
| [<]  NEW GROUP APPLICATION               |
+------------------------------------------+
| Fill details for your contingent/team:   |
|                                          |
| 1. Group / Team Name:                    |
|    [ Nagpur Citizen Front              ] |
|                                          |
| 2. Organization Category (Dropdown):     |
|    +----------------------------------+  |
|    | [v] NGO / Civil Society Org      |  |
|    |     Labor Union / Trade Assoc    |  |
|    |     College / University Union   |  |
|    |     School Contingent            |  |
|    |     Corporate / Workplace Team   |  |
|    |     Resident Welfare Assoc (RWA) |  |
|    |     Sports / Athletic Club       |  |
|    |     Grassroots / Independent     |  |
|    +----------------------------------+  |
|                                          |
| 3. Estimated Contingent Size:            |
|    [ 50 - 100 participants             ] |
|                                          |
| 4. Proposed Assembly / Muster Point:     |
|    [ Samvidhan Square, Nagpur          ] |
|                                          |
| 5. Leader Contact & Purpose Notes:       |
|    [ Peaceful civic awareness walk     ] |
+------------------------------------------+
| ℹ️ Reviewed by Domain SuperAdmins.       |
|   [ 🚀 SUBMIT APPLICATION FOR APPROVAL ] |
+------------------------------------------+
```

---

### Screen 5: Group Leader Hub - Tab 1: Team Hub (`/group-leader/hub`)
```text
+------------------------------------------+
| [<] LEADER HUB: VNIT Club                |
| Tabs: [ 👥 Team Hub*] [📍 Map] [📊 Stats]|
+------------------------------------------+
| 🚨 TEAM SOS ALERTS (1 Active):           |
| +--------------------------------------+ |
| | FROM: Priya Verma (+91 98221-XXXXX)  | |
| | TYPE: 🚑 Medical (Heat exhaustion)   | |
| | [ 📞 Call ]  [ ✓ Resolved Locally ]  | |
| | [ ↗️ Forward to Admin with Note ]     | |
| +--------------------------------------+ |
+------------------------------------------+
| ➕ DIRECT ADD MEMBERS (Auto-General):    |
| Phone: [+91 98XXXXXXXX] [ + Add Member ] |
+------------------------------------------+
| 📢 TEAM BROADCAST (Own Group Only):      |
| [ Assemble at South Gate by 05:30 AM!  ] |
| [ 📣 SEND BROADCAST TO 38 MEMBERS ]      |
+------------------------------------------+
| TEAM MEMBER ROSTER (38 Members):         |
| • Rajesh Sharma (Leader - Active)        |
| • Aniket Deshmukh (Active - In Transit)  |
| • Priya Verma (Active - SOS Flagged)     |
+------------------------------------------+
```

---

### Screen 6: Group Leader Hub - Tab 2: Live Team Map (`/group-leader/live-map`)
```text
+------------------------------------------+
| [<] LEADER HUB: VNIT Club                |
| Tabs: [ 👥 Team Hub] [📍 Map*] [📊 Stats]|
+------------------------------------------+
| 📍 LIVE TEAM GPS & DENSITY TRACKER (38)  |
| +--------------------------------------+ |
| | [📍 Leader (You)]                    | |
| |                                      | |
| |  [ 🟢 High Density Cluster (30) ]    | |
| |  📍 Ambazari Muster Point (Intense)  | |
| |                                      | |
| |  • 6 En Route Riders (Medium Density)| |
| |  • 2 Standstill / Stragglers [⚠️]    | |
| |                                      | |
| | Color Density Legend:                | |
| | [🟢 Dense Cluster] [🟡 Moderate] [🔴 SOS]|
| +--------------------------------------+ |
+------------------------------------------+
| LIVE TEAM TELEMETRY:                     |
| • Avg Speed: 19.2 km/h                   |
| • Furthest Ahead: 4.2 km from Muster     |
| • Last Heartbeat Ping: 2s ago            |
| [ 🔍 Recenter on Lead Rider ]            |
+------------------------------------------+
```

---

### Screen 7: Group Leader Hub - Tab 3: Team Analytics (`/group-leader/analytics`)
```text
+------------------------------------------+
| [<] LEADER HUB: VNIT Club                |
| Tabs: [ 👥 Team Hub] [📍 Map] [📊 Stats*]|
+------------------------------------------+
| TEAM PERFORMANCE & MUSTER METRICS        |
|                                          |
| • Total Enrolled Members : 38            |
| • Currently Active Today : 34 (89.4%)    |
| • Checked-in at Muster Pt: 32 (94.1%)    |
| • Completed Route Finish : 18 (52.9%)    |
|                                          |
| MUSTER ROLL BREAKDOWN:                   |
| [████████████████░░░░] 89% Checked-In    |
|                                          |
| INCIDENT & SAFETY LOG:                   |
| • SOS Triggered: 1 (Resolved / Escort)   |
| • Avg Speed / Pace : 18.4 km/h           |
|                                          |
| [ 📥 Export Team Attendance CSV ]        |
+------------------------------------------+
```

---

### Screen 8: SuperAdmin Console - Tab 1: Governance (`/admin/dashboard`)
```text
+------------------------------------------+
| ⚙️ SUPERADMIN: CYCLING DOMAIN            |
| Tabs: [🛡️ Gov*] [📍 Map] [🗺️ Route] [📊]  |
+------------------------------------------+
| 🚨 ESCALATED & DIRECT SOS QUEUE (2):     |
| +--------------------------------------+ |
| | 1. [FORWARDED] User: Priya (VNIT)    | |
| |    Leader Note: "Ambulance urgently" | |
| |    [ 🚑 Dispatch Ambulance ] [Resolve] |
| | 2. [DIRECT] User: Amit (General User)| |
| |    [ 🛠️ Dispatch Support Van ]       | |
| +--------------------------------------+ |
+------------------------------------------+
| 🔔 PENDING GROUP APPLICATIONS (1):       |
| • Org: "Nagpur Citizen Front" (NGO)      |
|   Leader: Anjali Deshmukh (75 members)   |
|   [ ✓ APPROVE & MAKE LEADER ] [ ✗ REJ ]  |
+------------------------------------------+
| 📢 SUPERADMIN BROADCAST TOOL:            |
| Target: (o) General Group  ( ) Sub-Group |
| [ 🚨 SEND HIGH-PRIORITY BROADCAST ]      |
+------------------------------------------+
```

---

### Screen 9: SuperAdmin Console - Tab 2: Domain Live Map (`/admin/live-map`)
```text
+------------------------------------------+
| ⚙️ SUPERADMIN: CYCLING DOMAIN            |
| Tabs: [🛡️ Gov] [📍 Map*] [🗺️ Route] [📊]  |
+------------------------------------------+
| FILTER PARTICIPANTS BY SUB-GROUP:        |
| [ All General Group (1,248 Users)    v ] |
|  ↳ Options: All General | VNIT Club | ...|
+------------------------------------------+
| 🌐 DOMAIN-WIDE LIVE DENSITY VISUALIZER   |
| +--------------------------------------+ |
| | [🚩 Zero Mile] ======> [🏁 Deekshabhoomi
| |                                      | |
| |  [🟣 High Density Crowd: 450 Pax]    | |
| |  📍 Shankar Nagar Square (Heavy)     | |
| |                                      | |
| |  [🔵 Moderate Density: 180 Pax]      | |
| |  📍 Law College Square               | |
| |                                      | |
| |  • 2 Active SOS Flags [🔴 🔴]        | |
| |                                      | |
| | Dynamic Shading:                     | |
| | [🟣 High Density] [🔵 Mid] [🟢 Sparse]|
| +--------------------------------------+ |
+------------------------------------------+
| [ 🚑 Track Medical Escorts ] [ 🔍 Zoom ] |
+------------------------------------------+
```

---

### Screen 10: SuperAdmin Console - Tab 3: Route & Schedule Builder (`/admin/route-builder`)
```text
+------------------------------------------+
| ⚙️ SUPERADMIN: CYCLING DOMAIN            |
| Tabs: [🛡️ Gov] [📍 Map] [🗺️ Route*] [📊]  |
+------------------------------------------+
| 🛠️ ROUTE & EVENT TIMING BUILDER          |
+------------------------------------------+
| 1. EVENT SCHEDULE & TIMINGS:             |
| Date      : [ 15-Nov-2026              ] |
| Start Time: [ 06:00 AM                 ] |
| End Time  : [ 11:30 AM                 ] |
| Status    : [ UPCOMING / SCHEDULED   v ] |
| (ℹ️ Live tracking & SOS active only      |
|  during these specified hours)           |
+------------------------------------------+
| 2. ROUTE GEOMETRY & CHECKPOINTS:         |
| Route Name: [ West Nagpur Loop 2026    ] |
| Distance  : 24.5 km                      |
|                                          |
| • [🚩 Start] : Zero Mile (06:00 AM)      |
| • [💧 Water] : Shankar Nagar Square      |
| • [🚑 Aid]   : Law College Square        |
| • [🏁 Finish]: Deekshabhoomi Ground      |
|                                          |
| [+ Add Water Station] [+ Add Medical Tent]
| [+ Add Diversion / Road Closure Marker]  |
+------------------------------------------+
| [ 🗺️ Draw / Edit GPX Route on Map ]      |
| [ 💾 PUBLISH ROUTE & EVENT SCHEDULE ]    |
+------------------------------------------+
```

---

### Screen 11: SuperAdmin Console - Tab 4: Domain Analytics (`/admin/analytics`)
```text
+------------------------------------------+
| ⚙️ SUPERADMIN: CYCLING DOMAIN            |
| Tabs: [🛡️ Gov] [📍 Map] [🗺️ Route] [📊*]  |
+------------------------------------------+
| DOMAIN-WIDE REAL-TIME METRICS            |
|                                          |
| 👥 PARTICIPATION SUMMARY                 |
| • Total General Participants : 1,248     |
| • Total Approved Sub-Groups  : 16        |
| • Active Sub-Group Members   : 1,020     |
| • General-Only Participants  : 228       |
|                                          |
| 🚦 ROUTE TRAFFIC & SAFETY METRICS        |
| • Total SOS Triggered Today  : 5         |
| • Avg SOS Resolution Time    : 4.2 mins  |
| • Active Medical Dispatches  : 1         |
|                                          |
| 📈 CONTINGENT BREAKDOWN (BY ORG TYPE):   |
| • Colleges/Univ : 42% (524 pax)          |
| • NGOs/Citizen  : 26% (324 pax)          |
| • Corporate/Club: 32% (400 pax)          |
|                                          |
| [ 📥 Download Complete Domain Audit Log ]|
+------------------------------------------+
```

---

### Screen 12: Developer Master Panel - Tab 1: Provisioning (`/dev-panel`)
```text
+------------------------------------------+
| 🛠️ DEVELOPER MASTER CONTROL PANEL       |
| Tabs: [ 🔑 Provisioning*] [ 📊 Analytics]|
+------------------------------------------+
| SELECT EVENT DOMAIN:                     |
| [ Cycling Rally 2026                 v ] |
+------------------------------------------+
| PROVISIONED SUPERADMINS (5/6 Allocated): |
| 1. SuperAdmin 1: +91 98220-11111 [Edit/Rev]
| 2. SuperAdmin 2: +91 98220-22222 [Edit/Rev]
| 3. SuperAdmin 3: +91 98220-33333 [Edit/Rev]
| 4. SuperAdmin 4: +91 98220-44444 [Edit/Rev]
| 5. SuperAdmin 5: +91 98220-55555 [Edit/Rev]
| [ + Provision 6th SuperAdmin ]           |
+------------------------------------------+
| DOMAIN ACTIONS:                          |
| [+ Create New Isolated Event Domain]     |
| [ Reset Domain Cache / DB Diagnostics ]  |
+------------------------------------------+
```

---

### Screen 13: Developer Master Panel - Tab 2: Global Analytics (`/dev-panel/analytics`)
```text
+------------------------------------------+
| 🛠️ DEVELOPER MASTER CONTROL PANEL       |
| Tabs: [ 🔑 Provisioning ] [ 📊 Analytics*]|
+------------------------------------------+
| GLOBAL CROSS-DOMAIN SYSTEM ANALYTICS     |
|                                          |
| 🌐 ALL EVENT DOMAINS OVERVIEW            |
| • Total Active Domains      : 3          |
| • Total Registered Users    : 5,498      |
| • Total Active Groups       : 52         |
| • Total SuperAdmins Seated  : 16         |
|                                          |
| 📊 DOMAIN-BY-DOMAIN BREAKDOWN:           |
| 1. 🚲 Cycling Rally 2026    : 1,248 users|
| 2. 🏃 Nagpur City Marathon  : 3,400 users|
| 3. 📢 Citizen Protest Rally : 850 users  |
|                                          |
| ⚙️ INFRASTRUCTURE HEALTH & LOAD          |
| • WebSocket Connections     : 2,140 live |
| • Geolocation Ping Latency  : 48ms (Avg) |
| • DB Query Pool Utilization : 22%        |
|                                          |
| [ 🔄 Refresh Telemetry ] [ 📥 Export DB ]|
+------------------------------------------+
```

---

## 4. Technical Data Schema & Database Relationships

### Comprehensive Entity-Relationship Diagram (ERD)

```text
       ┌───────────────────────────────┐
       │             users             │
       ├───────────────────────────────┤
       │ id (UUID) PK                  │
       │ phone_number (VARCHAR, UNIQUE)│
       │ full_name (VARCHAR)           │
       │ avatar_url (VARCHAR)          │
       │ emergency_contact (VARCHAR)   │
       │ created_at (TIMESTAMP)        │
       └──────────────┬────────────────┘
                      │
         ┌────────────┼───────────────────────────┬─────────────────────────┐
         │ 1          │ 1                         │ 1                       │ 1
         │            │                           │                         │
         ▼ *          ▼ *                         ▼ *                       ▼ *
┌────────────────┐ ┌────────────────────────┐ ┌──────────────────────┐ ┌────────────────────────┐
│ domain_admins  │ │   group_memberships    │ │group_creation_request│ │       sos_events       │
├────────────────┤ ├────────────────────────┤ ├──────────────────────┤ ├────────────────────────┤
│ id (UUID) PK   │ │ id (UUID) PK           │ │ id (UUID) PK         │ │ id (UUID) PK           │
│ domain_id (FK) │ │ domain_id (FK)         │ │ domain_id (FK)       │ │ domain_id (FK)         │
│ user_id (FK)   │ │ group_id (FK)          │ │ applicant_user_id(FK)│ │ sender_user_id (FK)    │
│ role:SUPERADMIN│ │ user_id (FK)           │ │ org_name (VARCHAR)   │ │ active_sub_group_id(FK)│
│ created_by_dev │ │ is_active (BOOLEAN)    │ │ org_type (VARCHAR)   │ │ emergency_type (ENUM)  │
└────────────────┘ │ is_leader (BOOLEAN)    │ │ expected_count (INT) │ │ latitude, longitude    │
         ▲         │ checkin_time(TIMESTAMP)│ │ muster_point (TEXT)  │ │ status (ENUM)          │
         │ *       └───────────┬────────────┘ │ status (ENUM)        │ │ forwarded_by (FK)      │
         │                     │              │ reviewed_by_admin(FK)│ │ leader_notes (TEXT)    │
         │                     │ *            └──────────────────────┘ └────────────────────────┘
         │ 1                   │                         ▲                          ▲
┌────────┴────────┐            │ 1                       │ *                        │ *
│  event_domains  │            ▼                         │ 1                        │ 1
├─────────────────┤    ┌──────────────────────┐          │                          │
│ id (UUID) PK    │    │      sub_groups      │──────────┴──────────────────────────┘
│ name (VARCHAR)  │1  *├──────────────────────┤
│ slug (VARCHAR)  ├───►│ id (UUID) PK         │
│ type (ENUM)     │    │ domain_id (FK)       │
│ status (ACTIVE) │    │ is_general (BOOLEAN) │
│ created_at (TS) │    │ name (VARCHAR)       │
└────────┬────────┘    │ org_type (VARCHAR)   │
         │ 1           │ leader_id (FK->user) │
         │             │ approval_status(ENUM)│
         │ *           └──────────┬───────────┘
┌────────┴─────────────┐          │ 1
│      broadcasts      │          │
├──────────────────────┤          │ *
│ id (UUID) PK         │          │
│ domain_id (FK)       │          │
│ sender_id (FK)       │          │
│ sender_role (ENUM)   │          │
│ target_type (ENUM)   │          │
│ target_group_id (FK) │◄─────────┘ (Nullable: NULL if target_type = 'GENERAL')
│ message_text (TEXT)  │
│ created_at (TS)      │
└──────────────────────┘
         ▲
         │ 1
         │ *
┌────────┴─────────────┐
│  route_checkpoints   │
├──────────────────────┤
│ id (UUID) PK         │
│ domain_id (FK)       │
│ checkpoint_type(ENUM)│
│ name (VARCHAR)       │
│ latitude, longitude  │
│ sequence_order (INT) │
└──────────────────────┘
```

---

### Detailed Table Specifications

#### 1. `event_domains` (Isolated Rally Domains & Official Schedules)
| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY, DEFAULT gen_random_uuid()` | Unique domain identifier |
| `name` | `VARCHAR(100)` | `NOT NULL` | Event title (e.g. "Cycling Rally 2026", "Nagpur Marathon") |
| `slug` | `VARCHAR(50)` | `UNIQUE, NOT NULL` | URL-friendly key (e.g. `cycling-2026`) |
| `type` | `VARCHAR(50)` | `NOT NULL` | Domain genre (`CYCLING`, `MARATHON`, `PROTEST`, `WALKATHON`) |
| `status` | `VARCHAR(20)` | `DEFAULT 'UPCOMING'` | Lifecycle (`UPCOMING`, `LIVE_ACTIVE`, `CONCLUDED`, `ARCHIVED`) |
| `start_time` | `TIMESTAMPTZ` | `NOT NULL` | Official event start timestamp |
| `end_time` | `TIMESTAMPTZ` | `NOT NULL` | Official event conclusion timestamp |
| `route_geojson`| `JSONB` | `NULLABLE` | Official route line string, waypoints, water points, medical tents |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Record creation timestamp |

#### 2. `users` (Global Citizen Accounts)
| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY, DEFAULT gen_random_uuid()` | Unique user identifier |
| `phone_number` | `VARCHAR(15)` | `UNIQUE, NOT NULL` | Verified mobile number (E.164 format) |
| `full_name` | `VARCHAR(100)` | `NOT NULL` | Participant's name |
| `avatar_url` | `TEXT` | `NULLABLE` | Profile picture |
| `emergency_contact` | `VARCHAR(15)` | `NULLABLE` | Next-of-kin phone number |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Registration timestamp |

#### 3. `domain_superadmins` (Dev-Seeded Gatekeepers: 5–6 per domain)
| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY, DEFAULT gen_random_uuid()` | Admin allocation ID |
| `domain_id` | `UUID` | `REFERENCES event_domains(id) ON DELETE CASCADE` | Assigned domain |
| `user_id` | `UUID` | `REFERENCES users(id) ON DELETE CASCADE` | User account holding SuperAdmin role |
| `created_by_dev` | `VARCHAR(50)` | `NOT NULL` | Dev panel session ID/developer identifier |
| `assigned_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Role granting timestamp |

#### 4. `sub_groups` (Contingent & General Groups)
| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY, DEFAULT gen_random_uuid()` | Unique group identifier |
| `domain_id` | `UUID` | `REFERENCES event_domains(id) ON DELETE CASCADE` | Owning domain |
| `name` | `VARCHAR(120)` | `NOT NULL` | Group name (e.g. "VNIT Cycling Club", "General Group") |
| `is_general` | `BOOLEAN` | `DEFAULT FALSE` | `TRUE` for domain's single mandatory General Group |
| `org_type` | `VARCHAR(60)` | `NOT NULL` | Category (`COLLEGE`, `NGO`, `LABOR_UNION`, `CORPORATE`, etc.) |
| `leader_id` | `UUID` | `REFERENCES users(id) ON DELETE SET NULL` | Assigned Group Leader |
| `muster_point` | `TEXT` | `NULLABLE` | Designated team assembly location / GPS coordinates |
| `approval_status` | `VARCHAR(20)` | `DEFAULT 'APPROVED'` | `PENDING`, `APPROVED`, `REJECTED`, `SUSPENDED` |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Group creation timestamp |

#### 5. `group_memberships` (Roster & Active Group Constraint)
| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY, DEFAULT gen_random_uuid()` | Membership link identifier |
| `domain_id` | `UUID` | `REFERENCES event_domains(id) ON DELETE CASCADE` | Domain context |
| `group_id` | `UUID` | `REFERENCES sub_groups(id) ON DELETE CASCADE` | Enrolled sub-group |
| `user_id` | `UUID` | `REFERENCES users(id) ON DELETE CASCADE` | Enrolled participant |
| `is_active` | `BOOLEAN` | `DEFAULT FALSE` | `TRUE` if currently active for tracking & SOS |
| `is_leader` | `BOOLEAN` | `DEFAULT FALSE` | `TRUE` if user is leader of this group |
| `participation_status`| `VARCHAR(20)`| `DEFAULT 'NOT_CHECKED_IN'` | `'NOT_CHECKED_IN'`, `'CHECKED_IN'`, `'IN_TRANSIT'`, `'COMPLETED'`, `'DROPPED_OUT'` |
| `checkin_time` | `TIMESTAMPTZ` | `NULLABLE` | Muster check-in timestamp (when present) |
| `completion_time` | `TIMESTAMPTZ` | `NULLABLE` | Rally completion / finish timestamp |
| `joined_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Join timestamp |

#### 6. `group_creation_requests` (Subtle Sidebar Form Applications)
| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY, DEFAULT gen_random_uuid()` | Request ID |
| `domain_id` | `UUID` | `REFERENCES event_domains(id) ON DELETE CASCADE` | Target event domain |
| `applicant_user_id`| `UUID` | `REFERENCES users(id) ON DELETE CASCADE` | Submitting user (promoted to leader on approval)|
| `org_name` | `VARCHAR(120)` | `NOT NULL` | Proposed contingent/group name |
| `org_type` | `VARCHAR(60)` | `NOT NULL` | Selected category from `<select>` dropdown |
| `expected_count` | `INT` | `NOT NULL` | Estimated participants count |
| `muster_point` | `TEXT` | `NOT NULL` | Proposed assembly point |
| `leader_notes` | `TEXT` | `NULLABLE` | Additional remarks / justification |
| `status` | `VARCHAR(20)` | `DEFAULT 'PENDING'` | `PENDING`, `APPROVED`, `REJECTED` |
| `reviewed_by` | `UUID` | `REFERENCES users(id) ON DELETE SET NULL` | SuperAdmin who took action |
| `reviewed_at` | `TIMESTAMPTZ` | `NULLABLE` | Timestamp of approval/rejection |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Application submission timestamp |

#### 7. `broadcasts` (Two-Tier High-Priority Alerts)
| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY, DEFAULT gen_random_uuid()` | Broadcast ID |
| `domain_id` | `UUID` | `REFERENCES event_domains(id) ON DELETE CASCADE` | Domain context |
| `sender_id` | `UUID` | `REFERENCES users(id) ON DELETE CASCADE` | SuperAdmin or Group Leader ID |
| `sender_role` | `VARCHAR(20)` | `NOT NULL` | `'SUPERADMIN'` or `'GROUP_LEADER'` |
| `target_type` | `VARCHAR(20)` | `NOT NULL` | `'GENERAL'` (domain-wide) or `'SPECIFIC_GROUP'` |
| `target_group_id` | `UUID` | `REFERENCES sub_groups(id) ON DELETE CASCADE` | `NULL` if general broadcast |
| `message_text` | `TEXT` | `NOT NULL` | Alert content |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Broadcast timestamp |

#### 8. `sos_events` (Emergency Escalation & Triage Logs)
| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY, DEFAULT gen_random_uuid()` | Emergency event ID |
| `domain_id` | `UUID` | `REFERENCES event_domains(id) ON DELETE CASCADE` | Domain context |
| `sender_user_id` | `UUID` | `REFERENCES users(id) ON DELETE CASCADE` | Distressed participant |
| `active_sub_group_id`| `UUID` | `REFERENCES sub_groups(id) ON DELETE SET NULL`| User's active group at moment of trigger |
| `emergency_type` | `VARCHAR(30)` | `NOT NULL` | `'MEDICAL'`, `'BREAKDOWN'`, `'THREAT'` |
| `latitude` | `DOUBLE PRECISION`| `NOT NULL` | Live GPS latitude |
| `longitude` | `DOUBLE PRECISION`| `NOT NULL` | Live GPS longitude |
| `status` | `VARCHAR(30)` | `DEFAULT 'TRIGGERED'` | `'TRIGGERED'`, `'FORWARDED_TO_ADMIN'`, `'RESOLVED'` |
| `forwarded_by_leader_id`| `UUID`| `REFERENCES users(id) ON DELETE SET NULL` | Leader who forwarded alert |
| `leader_notes` | `TEXT` | `NULLABLE` | Triage note attached by Group Leader |
| `resolved_by` | `UUID` | `REFERENCES users(id) ON DELETE SET NULL` | Leader or SuperAdmin resolving the event |
| `resolved_at` | `TIMESTAMPTZ` | `NULLABLE` | Resolution timestamp |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Trigger timestamp |

#### 9. `user_live_locations` (Telemetry for Dynamic Density Shading Maps)
| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY, DEFAULT gen_random_uuid()` | Location ping ID |
| `domain_id` | `UUID` | `REFERENCES event_domains(id) ON DELETE CASCADE` | Domain context |
| `user_id` | `UUID` | `REFERENCES users(id) ON DELETE CASCADE` | Participant ID |
| `active_group_id` | `UUID` | `REFERENCES sub_groups(id) ON DELETE SET NULL`| Group being tracked |
| `latitude` | `DOUBLE PRECISION`| `NOT NULL` | Current latitude |
| `longitude` | `DOUBLE PRECISION`| `NOT NULL` | Current longitude |
| `speed_kmh` | `REAL` | `DEFAULT 0.0` | Live speed |
| `updated_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Heartbeat ping timestamp |

#### 10. `route_checkpoints` (Waypoints, Water Stations & Medical Posts)
| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY, DEFAULT gen_random_uuid()` | Checkpoint ID |
| `domain_id` | `UUID` | `REFERENCES event_domains(id) ON DELETE CASCADE` | Domain context |
| `checkpoint_type` | `VARCHAR(30)` | `NOT NULL` | `'START'`, `'WATER_STATION'`, `'MEDICAL_POST'`, `'DIVERSION'`, `'FINISH'` |
| `name` | `VARCHAR(100)` | `NOT NULL` | Name (e.g. "Shankar Nagar Water Station #1") |
| `latitude` | `DOUBLE PRECISION`| `NOT NULL` | Marker latitude |
| `longitude` | `DOUBLE PRECISION`| `NOT NULL` | Marker longitude |
| `sequence_order` | `INT` | `NOT NULL` | Ordering along route (1, 2, 3...) |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Creation timestamp |

---

### Critical Database Integrity Constraints & Rules

1. **Max 3 Sub-Groups Limit**:
   * A user can belong to at most $3$ sub-groups where `is_general = FALSE` within a single `domain_id`.
   ```sql
   -- Enforced via Database Trigger or Application Layer:
   SELECT COUNT(*) FROM group_memberships gm
   JOIN sub_groups sg ON gm.group_id = sg.id
   WHERE gm.user_id = NEW.user_id 
     AND gm.domain_id = NEW.domain_id 
     AND sg.is_general = FALSE;
   -- Must be <= 3
   ```
2. **Exactly 1 Active Group Rule**:
   * A user can have at most **one** membership marked `is_active = TRUE` per `(user_id, domain_id)`.
   ```sql
   CREATE UNIQUE INDEX unique_active_group_per_user_domain 
   ON group_memberships (user_id, domain_id) 
   WHERE is_active = TRUE;
   ```
3. **Auto-Cascade to General Group**:
   * When a row is inserted into `group_memberships` for a Sub-Group, a database trigger or service hook ensures the user is also enrolled in the domain's General Group if not already present.
4. **SuperAdmin Seating Limit**:
   * Each `domain_id` enforces a soft cap of **5 to 6 SuperAdmins** provisioned via the Developer Panel.

---

## 5. Phone Authentication & Push Notification Architecture

### 5.1 Supabase Phone Auth with Predefined OTPs (Zero-Cost / Hackathon Ready)
* **Free Built-in Supabase Phone Auth**: Leverages Supabase Auth test phone numbers to completely bypass third-party SMS gateway costs (Twilio/MessageBird) and eliminate network delivery latency during testing & live hackathon judging.
* **Pre-Configured Whitelist**:
  * **SuperAdmins**: `+91 98220 11111` to `+91 98220 55555` (Fixed OTP: `123456`)
  * **Group Leaders**: `+91 98230 11111` (VNIT Leader), `+91 98230 22222` (Orange City Leader) (Fixed OTP: `123456`)
  * **Participants**: `+91 98240 11111` through `+91 98240 99999` (Fixed OTP: `123456`)

### 5.2 OneSignal Push Notification Infrastructure (Official Supabase Partner)
* **Dual-Channel Delivery Pipeline**:
  1. **Foreground / Active App**: Real-time HUD banner alerts and sound effects delivered sub-50ms via **Supabase Realtime WebSockets**.
  2. **Background / Lockscreen**: Heads-up push notifications dispatched via **OneSignal REST API** (`https://onesignal.com/api/v1/notifications`).
* **Targeting & Tagging Hierarchy**:
  * Upon login, Flutter client initializes OneSignal: `OneSignal.login(user_id)`.
  * User tags updated dynamically on domain switch or active group change:
    ```json
    {
      "domain_id": "cycling-2026",
      "active_group_id": "vnit-cycling-club",
      "role": "GROUP_LEADER"
    }
    ```
* **Notification Trigger Points**:
  * 🚨 **High-Priority Broadcasts**: SuperAdmin domain-wide announcements and Group Leader team reminders.
  * 🚑 **Context-Aware SOS Alerts**: Dispatched immediately to Group Leader's device or SuperAdmins when escalated.

---

## 6. Geospatial Architecture: Route Builder & Live Density Tracking

### 6.1 SuperAdmin Route Defining Engine & Road Snapping

#### A. UI Interaction & Road Snapping
* **Engine**: Powered by `leaflet-routing-machine` (or MapLibre GL + OSRM Routing Engine).
* **Road-Snapping**: Dropping Start and Finish waypoints automatically snaps the route polyline to actual physical street networks in Nagpur using open-source OSRM routing data.
* **Interactive Waypoint Manipulation**: SuperAdmin can click and drag any point along the polyline (`routeWhileDragging: true`, `waypointMode: 'snap'`) to divert paths through specific roads (e.g. WHC Road, Shankar Nagar).
* **Marker Placement**: Using `leaflet-geoman` (`@geoman-io/leaflet-geoman-free`), SuperAdmin drops and edits custom point markers:
  * 🚩 Start & 🏁 Finish points
  * 💧 Water / Hydration Stations
  * 🚑 Medical Aid Posts & Ambulances
  * ⛔ Road Closures & Traffic Diversion Pins
* **Export & Publish**: Clicking `[ 💾 Publish Route ]` compiles the line geometry and markers into a standard GeoJSON `FeatureCollection` saved to `event_domains.route_geojson` and indexed into `route_checkpoints`.

---

### 6.2 High-Frequency Live GPS Telemetry Pipeline

```text
 [ Participant Phone GPS ]
            │ (Smart Client Throttle: Every 5-8s if moved >= 5m)
            ▼
 [ WebSocket / Supabase Realtime Gateway ]
            │
            ├──────────────────────────────────────────┐
            ▼                                          ▼
 [ Redis In-Memory Geo Cache ]             [ PostgreSQL Micro-Batch ]
 • GEOADD domain:{id}:users                • Flushed every 30s for
 • Instant Spatial Radius Queries           historical replay & stats
            │
            ├─────────────────────────┬─────────────────────────┐
            │                         │                         │
            ▼ (domain:{id}:all)       ▼ (domain:{id}:group:{id})▼
 [ SuperAdmin Live Map ]   [ Group Leader Live Map ]  [ SOS Event Handler ]
```

1. **Client-Side Smart Throttling**:
   * Pings every **5–8 seconds**, but ONLY if the participant moved $\ge 5$ meters (eliminates redundant standstill battery drain and network noise).
2. **In-Memory Streaming Ingestion**:
   * Pings stream over WebSockets into an in-memory **Redis Cache** (`GEOADD`), avoiding direct database bottleneck under high concurrency.
3. **Partitioned Realtime Channels**:
   * **SuperAdmin Channel**: Receives `domain:{domainId}:all` pings (with group filter capabilities).
   * **Group Leader Channel**: Subscribes *only* to `domain:{domainId}:group:{groupId}`, receiving only their 30–50 team members.

---

### 6.3 Dynamic Density Color Shading Engine (Non-Heatmap Point Clustering)

Instead of traditional raster heatmaps, the app uses hardware-accelerated **Vector Point Clustering with Dynamic Step Color Expressions**:

#### A. MapLibre GL JS / Mapbox GL Step Configuration
```javascript
map.addLayer({
    id: 'density-clusters',
    type: 'circle',
    source: 'participant-pings',
    filter: ['has', 'point_count'],
    paint: {
        // Dynamic Color Intensity based on crowd concentration:
        'circle-color': [
            'step',
            ['get', 'point_count'],
            '#51bbd6', // Sparse (1 - 25 participants): Soft Cyan
            25,
            '#3bb2d0', // Moderate (25 - 100 participants): Sky Blue
            100,
            '#f1f075', // High (100 - 300 participants): Amber / Yellow
            300,
            '#e55e5e', // Very High (300 - 600 participants): Coral Red
            600,
            '#7b1fa2'  // Extreme Density (600+): Deep Intense Purple
        ],
        'circle-radius': [
            'step',
            ['get', 'point_count'],
            18, 25, 26, 100, 34, 300, 44
        ],
        'circle-opacity': 0.85
    }
});
```

#### B. Clustering Engine Alternatives
* **Supercluster (`supercluster`)**: Ultra-fast spatial clustering library for calculating cluster bounding boxes at 60 FPS on client devices.
* **Leaflet + `Leaflet.markercluster`**: HTML5 CSS-based dynamic cluster circles with animated color intensity rings for lighter setups.

---

### 6.4 Geospatial Technology & Library Matrix

| Feature | Recommended Libraries & Frameworks | Role & Functionality |
|---|---|---|
| **Route Road Snapping** | `leaflet-routing-machine` + OSRM Engine | Auto-snaps drawn route to Nagpur road network; draggable waypoints. |
| **Marker & Geometry Drawing** | `leaflet-geoman` (`@geoman-io/leaflet-geoman-free`) | Interactive UI toolbar to drop water points, medical tents, closures. |
| **Real-time GPS Ingestion** | `Socket.io` / `Supabase Realtime` + Redis `GEOADD` | Sub-50ms live location ingestion without database lock. |
| **Dynamic Density Shading** | `MapLibre GL JS` (or `Supercluster` + `Leaflet.markercluster`) | 60 FPS WebGL point clustering with dynamic step color intensity shading. |


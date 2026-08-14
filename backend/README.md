# ⚙️ ZeroMile Go — Backend & Verification Workbench (`backend/`)

This directory contains the database schema migrations, security patches, seed data, and the web reference prototype.

---

### 📂 Directory Architecture

```text
backend/
├── supabase/
│   ├── migrations/          # PostgreSQL Core Schema, RLS, & Security Audit Patches
│   └── seed.sql             # Nagpur Rally Event Data & Seed Personas
└── web_prototype/           # Multi-Role Verification & Live 45-Rider Simulation Engine
```

---

### 🧪 Running the Web Prototype Workbench

To launch the multi-role simulation engine locally in your browser:
```bash
python3 -m http.server 8085 --directory backend/web_prototype
```
Open **`http://localhost:8085`** in Google Chrome / Safari.

# HyperDebloat-Agent: System Architecture

> **Document Version:** 1.0  
> **Last Updated:** 2025  
> **Audience:** Developers, Contributors, AI Agents, Security Researchers

---

## 1. The Two-Layer Product Architecture

HyperDebloat-Agent is designed as a **two-layer platform** that separates the open algorithmic engine from the proprietary consumer experience.

```
┌─────────────────────────────────────────────────────────────────────┐
│                     HyperDebloat Platform                           │
│                                                                     │
│  ┌──────────────────────────────┐  ┌──────────────────────────────┐ │
│  │  LAYER 1 (Public GitHub)     │  │  LAYER 2 (Private — External)│ │
│  │  Open-Core CLI Engine        │  │  Commercial B2C Platform      │ │
│  │                              │  │                              │ │
│  │  • Package registry          │  │  • WebUSB browser frontend   │ │
│  │  • Safety scripts            │  │  • Device Health Score™      │ │
│  │  • Agent protocol            │  │  • 1-click remediation       │ │
│  │  • JSON schema               │  │  • Battery diagnostics AI    │ │
│  │  • Audit & restore tools     │  │  • SaaS backend & billing    │ │
│  │                              │  │                              │ │
│  │  Apache 2.0 Licensed         │  │  Proprietary / Commercial    │ │
│  └──────────────┬───────────────┘  └──────────────────────────────┘ │
│                 │  reads registry, safety rules, scripts             │
│                 └──────────────────────────────────────────────────→ │
└─────────────────────────────────────────────────────────────────────┘
```

---

### Layer 1: Open-Core CLI Engine (This Repository)

**Purpose:** The algorithmic foundation. Publicly available so developers, power users, and AI agents can build trust, inspect safety logic, contribute packages, and automate device operations.

**What lives here:**
| Component | Path | Description |
|---|---|---|
| Package Registry | `data/packages.json` | 56+ curated packages with safety ratings, reversibility flags, and metadata |
| Debloat Script | `scripts/debloat.sh` | Core ADB uninstall/disable logic |
| Audit Script | `scripts/audit.sh` | Non-destructive device analysis |
| Restore Script | `scripts/restore.sh` | Full rollback to pre-operation state |
| Privacy Hardening | `scripts/harden-privacy.sh` | Telemetry kill-switches and privacy flag tuning |
| Agent Protocol | `agent/protocol.md` | Canonical execution contract for AI agents |
| JSON Schema | `agent/schema.json` | Machine-readable package and operation schema |

**Why it's public:**
- Community trust through auditability
- SEO and discoverability via GitHub
- Contributes to the global Android de-bloat knowledge commons
- Enables AI agents (Claude, Cursor, MCP tools) to operate safely on real devices

---

### Layer 2: Commercial B2C Consumer Platform (Private Repository)

**Purpose:** The proprietary consumer experience. Built on top of Layer 1's data and logic, but never exposed as open source. This is the **commercial moat**.

**What lives there (conceptually):**
- **WebUSB Browser Frontend** — connects to Android devices without any software install
- **Device Health Score™** — proprietary algorithm aggregating battery, bloat, and performance signals
- **Battery Degradation Prediction** — ML model trained on anonymized device telemetry
- **1-Click Remediation** — guided UI for non-technical users, powered by Layer 1 scripts
- **SaaS Backend** — user accounts, subscription management, device history
- **Real-Time AI Orchestration** — coordinates AI agent actions during live device sessions

**How Layer 2 consumes Layer 1:**
```
Layer 2 (private)  ──reads──→  data/packages.json      (package metadata)
Layer 2 (private)  ──reads──→  agent/protocol.md       (execution ordering)
Layer 2 (private)  ──reads──→  scripts/                (actual ADB operations)
Layer 2 (private)  ──enforces→ safety ratings/flags    (reversibility checks)
```

Layer 2 **never modifies** Layer 1 data — it is a read-only consumer of the open-core registry and scripts. This ensures community contributions to Layer 1 automatically improve the commercial product.

---

## 2. Data Flow Diagram

```
                        HyperDebloat-Agent Data Flow
                        ════════════════════════════

  ┌─────────┐    USB/ADB    ┌──────────────────────────────────────────┐
  │ Android │ ─────────────→│              Layer 1 Engine              │
  │ Device  │               │                                          │
  └─────────┘               │  1. scripts/audit.sh                     │
                            │     └─ Reads installed package list       │
                            │     └─ Compares against data/packages.json│
                            │     └─ Generates audit report             │
                            │                                          │
                            │  2. Safety Check Gate                    │
                            │     └─ safe_to_remove: true/false        │
                            │     └─ reversible: true/false            │
                            │     └─ risk_level: low/medium/high       │
                            │                                          │
                            │  3. Action Execution (if approved)       │
                            │     └─ scripts/debloat.sh                │
                            │     └─ scripts/harden-privacy.sh         │
                            │        --speed-compile --no-standby      │
                            │                                          │
                            │  4. Restore Checkpoint                   │
                            │     └─ scripts/restore.sh                │
                            │     └─ Snapshot written before actions   │
                            │                                          │
                            │  5. Sanitized Log Output                 │
                            │     └─ PII stripped (see §4)            │
                            │     └─ logs/session-{hash}.json          │
                            └──────────────────────────────────────────┘
                                          │
                                          │ reads results
                                          ↓
                            ┌──────────────────────────┐
                            │  Layer 2 (if connected)  │
                            │  Device Health Score™    │
                            │  Dashboard / Remediation │
                            └──────────────────────────┘
```

---

## 3. AI Agent Integration Architecture

HyperDebloat-Agent is designed from the ground up to be consumed by autonomous AI agents. The following describes the canonical integration contract.

### 3.1 Supported Agent Environments

| Agent | Integration Method |
|---|---|
| Claude Code | Direct shell tool + MCP (Phase 3) |
| Cursor | `scripts/` execution via terminal tool |
| GitHub Copilot Workspace | JSON schema parsing |
| Custom LLM agents | `agent/protocol.md` + REST/WebSocket (Phase 3) |

### 3.2 Agent Execution Contract

All AI agents **MUST** follow this sequence. Deviating from this order is a protocol violation:

```
Step 1: READ    data/packages.json          ← Understand what is safe
Step 2: READ    agent/protocol.md           ← Understand execution rules  
Step 3: RUN     scripts/audit.sh            ← Non-destructive scan only
Step 4: PARSE   audit output                ← Match against registry
Step 5: PROPOSE action plan to human        ← Human-in-the-loop checkpoint
Step 6: RUN     scripts/debloat.sh          ← Only after explicit approval
Step 7: RUN     scripts/harden-privacy.sh   ← Optional privacy pass
Step 8: VERIFY  restore checkpoint exists   ← Confirm rollback is possible
Step 9: LOG     sanitized session log       ← Append to logs/
```

### 3.3 Package Registry Schema (data/packages.json)

Agents should parse the following fields for decision-making:

```json
{
  "package_name": "com.miui.analytics",
  "display_name": "MIUI Analytics",
  "safe_to_remove": true,
  "reversible": true,
  "risk_level": "low",
  "category": "telemetry",
  "tags": ["analytics", "tracking", "miui"],
  "affects_function": [],
  "notes": "Pure telemetry collector. No user-facing features."
}
```

**Field semantics for agents:**
- `safe_to_remove: false` → Agent MUST skip, cannot override
- `reversible: false` → Agent MUST obtain explicit double-confirmation
- `risk_level: high` → Agent MUST surface to user before any action

### 3.4 Script Flags Reference

```bash
# Full debloat pass
scripts/debloat.sh [--dry-run] [--category=<telemetry|bloatware|adware>]

# Privacy hardening — key flags:
scripts/harden-privacy.sh \
  --speed-compile      # Enable SPEED compilation profile (reduces startup latency)
  --no-standby         # Disable standby optimizations that phone home
  [--dry-run]          # Simulate without applying changes

# Audit (always safe, read-only)
scripts/audit.sh [--output=json|text]

# Restore from checkpoint
scripts/restore.sh [--checkpoint=<session-id>]
```

### 3.5 MCP Server Integration (Phase 3 — Roadmap)

A future MCP (Model Context Protocol) server will expose Layer 1 operations as structured tool calls, enabling zero-configuration integration with any MCP-compatible AI agent:

```
Tool: hyperdebloat/audit       → Run audit, return JSON
Tool: hyperdebloat/plan        → Generate action plan from audit
Tool: hyperdebloat/execute     → Execute approved plan (requires confirm=true)
Tool: hyperdebloat/restore     → Roll back last session
Tool: hyperdebloat/registry    → Query package metadata
```

---

## 4. Privacy Architecture

HyperDebloat-Agent is a **privacy-first framework**. The following rules are enforced by design.

### 4.1 No Telemetry Policy

- The framework itself **collects zero telemetry**
- No analytics, no ping-home, no usage tracking
- All operations are fully local and offline-capable
- Layer 1 scripts contain no network calls except explicit ADB over USB

### 4.2 PII Stripping Rules

All log output is sanitized before being written to disk:

| PII Type | Rule |
|---|---|
| Device IMEI | Replaced with `[IMEI-REDACTED]` |
| Phone number | Replaced with `[PHONE-REDACTED]` |
| Android ID | Replaced with `[ANDROID-ID-REDACTED]` |
| Serial number | Replaced with `[SERIAL-REDACTED]` |
| Google Account email | Replaced with `[ACCOUNT-REDACTED]` |
| Wi-Fi SSID | Replaced with `[SSID-REDACTED]` |
| IP addresses | Replaced with `[IP-REDACTED]` |

### 4.3 Log Sanitization Pipeline

```
Raw ADB output
      │
      ↓
  PII regex filter (scripts/lib/sanitize.sh)
      │
      ↓
  Session hash assignment (no timestamps with device correlation)
      │
      ↓
  logs/session-{sha256-hash}.json
      │
      ↓
  Optional: user exports sanitized report
```

### 4.4 Audit Trail

- Every destructive operation writes a **pre-operation snapshot** to `logs/snapshots/`
- Snapshots contain only package names and states — never user data
- Snapshots are stored locally; never uploaded

---

## 5. What Is NOT in This Repository (The Commercial Moat)

The following components are **intentionally absent** from this open-source repository. They are proprietary to the Layer 2 commercial platform:

| Component | Why It's Private |
|---|---|
| **WebUSB Consumer Frontend** | Core product differentiator; requires no install on user's machine |
| **Device Health Score™ Algorithm** | Proprietary weighting model combining 12+ device signals |
| **Battery Degradation Prediction Model** | ML model trained on proprietary anonymized dataset |
| **SaaS Payment & User Management Backend** | Business infrastructure; not relevant to open-core mission |
| **Real-Time AI Orchestration Layer** | Coordinates multi-step AI agent sessions with live state management |
| **Fleet Management Console** | Multi-device B2B feature |
| **Remediation UI/UX** | Designed for non-technical users; commercial product surface |

The open-core Layer 1 is the **algorithmic foundation** — the safety rules, the package intelligence, and the scripts that do the actual work. The commercial Layer 2 is the **experience layer** that makes that power accessible to consumers without technical knowledge.

This split ensures:
1. The community benefits from and audits the core logic
2. The business retains a durable, hard-to-replicate competitive advantage
3. AI agents can fully utilize Layer 1 without needing access to Layer 2

---

## 6. Repository Structure

```
Hyper Bloat/
├── ARCHITECTURE.md          ← This document
├── ROADMAP.md               ← Public roadmap
├── README.md                ← Project overview
├── LICENSE                  ← Apache 2.0
│
├── data/
│   └── packages.json        ← Package registry (56+ packages)
│
├── scripts/
│   ├── audit.sh             ← Read-only device analysis
│   ├── debloat.sh           ← Package removal/disabling
│   ├── restore.sh           ← Full rollback
│   ├── harden-privacy.sh    ← Privacy flag tuning
│   └── lib/
│       └── sanitize.sh      ← PII stripping library
│
├── agent/
│   ├── protocol.md          ← AI agent execution contract
│   └── schema.json          ← Machine-readable operation schema
│
└── logs/                    ← Local only, git-ignored
    └── snapshots/           ← Pre-operation device state snapshots
```

---

## 7. Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines on:
- Adding new packages to the registry
- Proposing new device OEM support
- Reporting unsafe package classifications
- AI agent integration testing

All contributions to Layer 1 are subject to community review. The safety classification of any package **requires two independent approvals** before merge.

---

*HyperDebloat-Agent Layer 1 is licensed under the Apache 2.0 License. Layer 2 is a separate proprietary product and is not covered by this license.*

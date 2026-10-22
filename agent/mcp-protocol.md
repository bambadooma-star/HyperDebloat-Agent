# HyperDebloat-Agent — MCP Integration Guide

> **Model Context Protocol (MCP) integration reference for AI agents (Claude Code, Cursor, Gemini CLI, and compatible MCP hosts)**

---

## Overview

HyperDebloat-Agent exposes a structured, machine-readable interface that AI agents can consume as both a **read-only knowledge base** (the public safety registry) and an **ADB execution engine** (the scripted operation layer). This document defines how to build MCP tooling on top of both layers.

---

## Section 1: Public Registry API

### What AI Agents Get For Free

The file `data/packages.json` is the authoritative source of package safety classifications. It is publicly readable, versioned in Git, and designed to be parsed programmatically.

### JSON Schema Reference

```jsonc
{
  "packages": [
    {
      "package": "com.miui.analytics",          // Android package name (string, unique key)
      "label": "MIUI Analytics",                // Human-readable display name
      "tier": "SAFE",                           // Safety tier — see Tier Values below
      "category": "telemetry",                  // Functional category (string)
      "tags": ["telemetry", "safe-to-remove"],  // Free-form tags array
      "notes": "Sends usage stats to Xiaomi",   // Human-readable rationale
      "oem": ["xiaomi", "hyperos"]              // OEM scope (array)
    }
  ],
  "schema_version": "1.0",                      // Registry schema version
  "last_updated": "2024-01-01"                  // ISO 8601 date
}
```

#### Tier Values

| Tier | Meaning | Agent Behaviour |
|------|---------|-----------------|
| `CRITICAL` | System-essential; removal bricks the device | **BLOCKED — never execute** |
| `UNSAFE` | High-risk; may cause instability | Require explicit user override |
| `CAUTION` | Context-dependent; proceed with care | Prompt user before executing |
| `SAFE` | Safe to remove for most users | Can execute within approved scope |

### Example: Query All SAFE HyperOS Packages (Python)

```python
import json, urllib.request

REGISTRY_URL = "https://raw.githubusercontent.com/bambadooma-star/HyperDebloat-Agent/main/data/packages.json"

with urllib.request.urlopen(REGISTRY_URL) as r:
    registry = json.load(r)

safe_hyperos = [
    p for p in registry["packages"]
    if p["tier"] == "SAFE" and "hyperos" in p.get("oem", [])
]

for pkg in safe_hyperos:
    print(pkg["package"], "—", pkg["label"])
```

### Example: Safety Gate Before Removal

```python
def is_safe_to_remove(package_name: str, registry: dict) -> tuple[bool, str]:
    """
    Returns (allowed, reason).
    Always call this before any ADB uninstall/disable command.
    """
    entry = next(
        (p for p in registry["packages"] if p["package"] == package_name),
        None
    )
    if entry is None:
        return False, "Package not in registry — treat as UNKNOWN, block by default"
    if entry["tier"] == "CRITICAL":
        return False, f"CRITICAL tier — removal blocked. Reason: {entry.get('notes', 'N/A')}"
    if entry["tier"] == "UNSAFE":
        return False, f"UNSAFE tier — requires explicit user override. Reason: {entry.get('notes', 'N/A')}"
    return True, f"Tier {entry['tier']} — safe to proceed"
```

---

## Section 2: Agent Execution Protocol

> Full protocol definition lives in [`agent/protocol.md`](protocol.md). This section is an integration summary for MCP tool authors.

### The 8-Step Execution Sequence

```
1. CONNECT      — Establish ADB connection; verify device fingerprint
2. SNAPSHOT     — Create a full backup / restore point before any mutations
3. AUDIT        — Enumerate installed packages; cross-reference registry
4. CLASSIFY     — Assign tier to every package; build proposed action list
5. GATE         — Block all CRITICAL/UNSAFE; surface CAUTION for user review
6. EXECUTE      — Run approved operations (disable / uninstall / harden)
7. HEARTBEAT    — Confirm device is alive post-operation; abort chain if not
8. LOG          — Record every action with package, tier, timestamp, outcome
```

### Critical Safety Rules

1. **CRITICAL = BLOCKED, always.** No user override, no flag bypass, no exceptions.
2. **Snapshot-first invariant.** Step 2 must complete successfully before Step 6 can begin. If snapshot fails, abort.
3. **Heartbeat-after invariant.** After every batch of operations, verify device responsiveness before continuing.
4. **MSA loop prevention (500 mA sequence).** If the device reports a charging anomaly during ADB operations, execute the 500 mA MSA loop prevention sequence:
   - Suspend all ADB write operations
   - Issue `adb shell dumpsys battery` health check
   - Wait for stable current reading (< ±50 mA variance over 3 readings)
   - Resume only if health check passes; otherwise hand control back to the user

### Package Classification Priority

```
Registry CRITICAL  →  BLOCKED (no override)
Registry UNSAFE    →  User must confirm per-package
Registry CAUTION   →  User must confirm per-batch
Registry SAFE      →  Auto-approved within session scope
Not in registry    →  Treated as UNSAFE (unknown = blocked)
```

---

## Section 3: Real-Time Device Integration Architecture

### How an MCP ADB Server Combines Both Layers

```
┌─────────────────────────────────────────────────────────┐
│                    AI Agent (MCP Host)                  │
│  (Claude Code / Cursor / Gemini CLI)                    │
└──────────────────────┬──────────────────────────────────┘
                       │ MCP tool calls
          ┌────────────▼─────────────┐
          │    MCP ADB Server        │
          │  (hyperdebloat-mcp)      │
          └──┬──────────────────┬───┘
             │                  │
    ADB over USB          HTTPS / local file
             │                  │
    ┌────────▼──────┐   ┌───────▼──────────────┐
    │  Android      │   │  data/packages.json   │
    │  Device       │   │  (Public Registry)    │
    └───────────────┘   └──────────────────────┘
```

### Integration Pseudocode

```python
async def run_hyperdebloat_session(device_serial: str):
    # Step 1: Connect
    device = await adb.connect(device_serial)
    assert device.is_authorized(), "ADB auth required on device"

    # Step 2: Load registry
    registry = await fetch_registry(REGISTRY_URL)

    # Step 3: Scan device
    installed = await adb.list_packages(device)

    # Step 4: Cross-reference
    actions = []
    for pkg in installed:
        allowed, reason = is_safe_to_remove(pkg, registry)
        if allowed:
            actions.append({"package": pkg, "action": "disable", "reason": reason})
        else:
            log.info(f"SKIPPED {pkg}: {reason}")

    # Step 5: Present to user (via MCP sampling or UI)
    confirmed = await present_action_plan(actions)

    # Step 6: Execute with safety gates
    snapshot = await adb.backup(device)
    for action in confirmed:
        result = await adb.disable_package(device, action["package"])
        heartbeat = await adb.ping(device)
        if not heartbeat:
            await adb.restore(device, snapshot)
            raise DeviceUnresponsiveError("Heartbeat failed — restored from snapshot")
        log_action(action, result)
```

### MCP Tool Definitions (JSON Schema)

```json
{
  "tools": [
    {
      "name": "hyperdebloat_audit",
      "description": "Scan the connected device and return a classified list of installed packages cross-referenced with the HyperDebloat safety registry.",
      "inputSchema": {
        "type": "object",
        "properties": {
          "device_serial": { "type": "string", "description": "ADB device serial (omit for single-device)" },
          "oem_filter": { "type": "string", "description": "Filter results to a specific OEM scope, e.g. 'hyperos'" }
        }
      }
    },
    {
      "name": "hyperdebloat_check_package",
      "description": "Look up a single package name in the safety registry and return its tier, category, and notes.",
      "inputSchema": {
        "type": "object",
        "required": ["package"],
        "properties": {
          "package": { "type": "string", "description": "Android package name, e.g. com.miui.analytics" }
        }
      }
    },
    {
      "name": "hyperdebloat_execute_safe_tier",
      "description": "Disable or uninstall all SAFE-tier packages identified in the last audit. Takes a snapshot first. Blocked packages are reported but never acted upon.",
      "inputSchema": {
        "type": "object",
        "properties": {
          "device_serial": { "type": "string" },
          "dry_run": { "type": "boolean", "description": "If true, simulate actions without executing", "default": true },
          "scope": { "type": "string", "enum": ["disable", "uninstall"], "default": "disable" }
        }
      }
    },
    {
      "name": "hyperdebloat_restore",
      "description": "Restore the device to the pre-session snapshot. Requires a valid snapshot from the current session.",
      "inputSchema": {
        "type": "object",
        "required": ["device_serial"],
        "properties": {
          "device_serial": { "type": "string" },
          "snapshot_id": { "type": "string", "description": "Snapshot identifier returned by execute. Omit to use latest." }
        }
      }
    },
    {
      "name": "hyperdebloat_harden_privacy",
      "description": "Apply privacy hardening configurations (revoke dangerous permissions, disable telemetry services) for SAFE-classified packages.",
      "inputSchema": {
        "type": "object",
        "properties": {
          "device_serial": { "type": "string" },
          "dry_run": { "type": "boolean", "default": true },
          "categories": {
            "type": "array",
            "items": { "type": "string" },
            "description": "Limit to specific categories, e.g. ['telemetry', 'ads']"
          }
        }
      }
    }
  ]
}
```

---

## Section 4: Private Layer 2 Integration (Commercial Subscribers)

> This section describes the proprietary **HyperDebloat-Pro** platform that extends the open-core engine for consumer use.

### What Layer 2 Adds

Layer 2 (**HyperDebloat-Pro**, private repository) extends this open-core engine with:

- **WebUSB device connectivity** — browser-native USB protocol, zero install required on the user's machine
- **Real-time Device Health Scoring** — proprietary algorithm combining battery stats, performance counters, and bloat impact modeling into a single 0–100 score
- **Consumer Remediation UI** — visual, 1-click interface designed for non-technical users
- **SaaS backend** — user accounts, session history, multi-device management
- **Payment integration** — Stripe/Paddle subscription and one-time purchase flows
- **Fleet Management API** — enterprise/MSP multi-device operations

### How Layer 2 Reads Layer 1

Layer 2 treats `data/packages.json` from this repository as its **authoritative safety registry**. The relationship is strictly one-directional:

```
Layer 1 (this repo) ──registry read──▶ Layer 2 (HyperDebloat-Pro)
                    ◀──execution call── Layer 2 scripts invoke Layer 1 primitives
```

Layer 2 enriches package metadata (OEM-specific heuristics, device health impact scores) but **never modifies tier classifications**. If Layer 1 marks a package as `CRITICAL`, Layer 2 will display it as blocked and explain why — it cannot promote a `CRITICAL` package to a lower risk tier.

> **Invariant: Layer 1 (this repository) serves as the single source of truth for package safety classifications. Layer 2 never overrides CRITICAL designations.**

### Layer 2 AI Orchestration Flow

```
[Device via WebUSB]
        │
        ▼
[Layer 2: Live scan — what's installed]
        │
        ▼
[Layer 1: data/packages.json — is it safe?]
        │
        ▼
[AI Agent: propose actions → Layer 2 UI]
        │  (user confirms)
        ▼
[Layer 1: execute primitives (ADB scripts)]
        │
        ▼
[Layer 2: log results to private storage (PII-safe)]
```

---

## Appendix: Running a Local MCP Server

```bash
# Install (requires Node.js 18+ or Python 3.11+)
git clone https://github.com/bambadooma-star/HyperDebloat-Agent
cd HyperDebloat-Agent

# Start MCP server (ADB must be on PATH, device connected)
python agent/mcp_server.py --registry data/packages.json --port 5173

# Claude Desktop config (claude_desktop_config.json):
{
  "mcpServers": {
    "hyperdebloat": {
      "command": "python",
      "args": ["agent/mcp_server.py", "--registry", "data/packages.json"],
      "cwd": "/path/to/HyperDebloat-Agent"
    }
  }
}
```

---

*This document is maintained alongside `data/packages.json`. When the registry schema changes, update Section 1 accordingly.*

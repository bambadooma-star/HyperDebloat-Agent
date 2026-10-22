# HyperDebloat-Agent: Public Roadmap

> This roadmap covers the **Layer 1 open-core platform** only.  
> The commercial Layer 2 consumer product has a separate private roadmap.  
> Last updated: 2025

---

## Current Status

> [!NOTE]
> HyperDebloat-Agent is in active development. Phase 1 is largely complete. Phase 2 is underway. Community contributions are the primary driver of Phases 2 and 3.

---

## Phase 1 — Open-Core Foundation ✅ (Current)

*Goal: Establish a trusted, auditable base for Android debloating that AI agents and power users can rely on.*

| Status | Item |
|---|---|
| ✅ | **Xiaomi HyperOS / MIUI package registry** — 56 curated packages with safety ratings, reversibility flags, and category metadata |
| ✅ | **Core safety scripts** — `audit.sh`, `debloat.sh`, `restore.sh`, `harden-privacy.sh` |
| ✅ | **AI agent protocol** (`agent/protocol.md`) — canonical execution contract for autonomous agents |
| ✅ | **JSON schema** (`agent/schema.json`) — machine-readable package and operation schema |
| ✅ | **Restore/rollback system** — pre-operation snapshots enabling full reversal |
| ✅ | **PII sanitization** — all log output stripped of device identifiers |
| ✅ | **Privacy hardening flags** — `--speed-compile`, `--no-standby` and related tuning options |
| 🔄 | **Samsung One UI package registry** — initial research and classification in progress |

---

## Phase 2 — Community Growth 🔜 (Near-Term)

*Goal: Expand device coverage and build contributor infrastructure so the registry becomes the most comprehensive Android bloat database available.*

| Status | Item |
|---|---|
| 🔜 | **Samsung One UI full coverage** — 100+ packages across Galaxy S, A, and M series |
| 🔜 | **Google Pixel / Stock Android packages** — AOSP and GApps bloat classification |
| 🔜 | **OnePlus OxygenOS support** — package registry and OEM-specific safety rules |
| 🔜 | **Community telemetry contribution system** — standardized format for contributors to submit package behavior observations (fully anonymized, opt-in) |
| 🔜 | **Automated CI for package safety verification** — GitHub Actions pipeline that flags regressions in safety classifications |
| 🔜 | **Package dispute / review workflow** — structured process for challenging a safety rating |
| 🔜 | **Multi-language README** — Translations for Chinese, Spanish, Portuguese, German (top Android markets) |

---

## Phase 3 — Ecosystem 🔭 (Medium-Term)

*Goal: Make HyperDebloat-Agent a first-class citizen in the AI agent and developer tooling ecosystem.*

| Status | Item |
|---|---|
| 🔭 | **MCP (Model Context Protocol) server** — expose Layer 1 operations as structured tool calls for any MCP-compatible AI agent (Claude, Cursor, etc.) |
| 🔭 | **VS Code extension** — package registry browser, script runner, and audit visualizer for developers |
| 🔭 | **Cursor plugin integration** — native Cursor AI workflow for debloat-assisted development and testing |
| 🔭 | **GitHub Action: `hyperdebloat/run`** — run audits as part of Android CI/CD pipelines |
| 🔭 | **Realme / Oppo ColorOS support** — package registry for ColorOS OEM packages |
| 🔭 | **Motorola / Lenovo support** — package registry for Moto bloatware |
| 🔭 | **Sony Xperia support** — niche but technically sophisticated user base |
| 🔭 | **CLI installable via npm / pip / brew** — zero-friction installation for developers |
| 🔭 | **Agent replay logs** — structured format for sharing and replaying past agent sessions (sanitized) |

---

## Phase 4 — Commercial Consumer Platform 🚀 (Parallel Track — External)

> [!IMPORTANT]
> Phase 4 is developed in a **separate private repository** and is a distinct commercial product. It is not part of this open-source project. It is listed here for transparency about where the open-core investment is heading.

*Goal: Bring the power of Layer 1 to non-technical users via a zero-install browser experience.*

| Status | Item |
|---|---|
| 🚀 | **Browser-native consumer platform** — WebUSB-based connection to Android devices; no software install required |
| 🚀 | **Device Health Score™ dashboard** — 10-second health assessment combining battery, bloat, and performance signals |
| 🚀 | **1-click remediation** — guided experience for non-technical users powered by Layer 1 scripts |
| 🚀 | **Battery degradation diagnostics** — predictive model for battery health and lifespan estimation |
| 🚀 | **Multi-device fleet management** — for IT teams and device resellers managing many Android devices |
| 🚀 | **Real-time AI orchestration** — AI agent coordination layer for live, interactive device sessions |

---

## How to Influence the Roadmap

The community has direct influence over **Phases 1–3**. Here's how:

- **Submit a package** → Open a PR adding a new entry to `data/packages.json`
- **Report a misclassification** → Open an issue with evidence of incorrect safety rating
- **Request OEM support** → Open an issue tagged `[OEM Request]` with device model and Android version
- **Propose a new script flag** → Open a discussion in the Discussions tab
- **Integrate and share** → Share how you're using the AI agent protocol — this shapes the MCP server design

Phase 4 (commercial) is not community-directed, but Layer 1 quality directly determines Layer 2 quality — every contribution here improves the consumer product.

---

## Versioning Policy

| Version Range | Meaning |
|---|---|
| `0.x.x` | Phase 1 — pre-stable, breaking changes possible |
| `1.0.0` | Phase 2 complete — stable registry schema, no breaking changes to JSON schema |
| `2.0.0` | Phase 3 MCP server stable — MCP protocol compatibility guaranteed |

The registry schema (`agent/schema.json`) follows **semver independently** from script versions. AI agents should pin to a schema major version.

---

*This roadmap is updated quarterly. Star the repo to follow progress.*

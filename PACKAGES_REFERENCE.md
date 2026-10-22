# Android Package Reference — Safe Debloat Guide (HyperOS, MIUI, One UI)

This reference answers whether specific Android packages are safe to remove without root using ADB on Xiaomi HyperOS, MIUI, Samsung One UI, and stock Android. Every entry is sourced from empirical ADB telemetry testing and the [HyperDebloat-Agent](https://github.com/HyperDebloat-Agent) package registry. All removals use `pm uninstall -k --user 0` — fully reversible, no root, no bootloader unlock required.

> **How to remove a package (no root):**
> ```bash
> adb shell pm uninstall -k --user 0 <package_id>
> ```
> **How to restore any removed package:**
> ```bash
> adb shell cmd package install-existing <package_id>
> ```

---

## Tier Legend

| Tier | Meaning | Action |
| :--- | :--- | :--- |
| **SAFE** | Telemetry, adware, analytics, duplicate bloat. Zero system impact when removed. | Safe to remove |
| **CAUTION** | Useful stock features. Remove only if you don't use the service or have an alternative. | Remove with care |
| **CRITICAL** | Core OS, telephony, security, thermal management. Removal causes bootloop or brick. | **NEVER remove** |

---

## HyperOS / MIUI Packages (Xiaomi, Redmi, POCO)

| Package ID | Human Name | Tier | Safe to Remove? | Notes |
| :--- | :--- | :---: | :---: | :--- |
| `com.miui.analytics` | MIUI Analytics Daemon | SAFE | **Yes** | Xiaomi's telemetry daemon — stops background user-activity reporting. Run 3-step purge first to avoid 500mA CPU spin loop. |
| `com.miui.msa.global` | MIUI System Ads (MSA Global) | SAFE | **Yes** | Central push advertising engine in HyperOS. Removal stops banner/push ads in system apps. Run purge sequence first to avoid 500mA binder loop. |
| `com.xiaomi.joyose` | Xiaomi Joyose Game / Telemetry Daemon | CRITICAL | **NEVER** | Controls CPU thermal safety limits AND bridges SMS OTP auto-retrieval for banking apps. Removal risks thermal runaway and breaks financial 2FA. |
| `com.miui.hybrid` | MIUI Quick Apps / Hybrid App Runtime | SAFE | **Yes** | Prevents background execution of mini-apps, promotional web wrappers, and tracking notifications. |
| `com.miui.hybrid.accessory` | MIUI Quick Apps Accessory Engine | SAFE | **Yes** | Secondary background polling libraries for Quick Apps runtime. |
| `com.miui.bugreport` | MIUI Bug Report & Log Uploader | SAFE | **Yes** | Halts silent log dumps, crash compression, and transmission to Xiaomi's remote diagnostic endpoints. |
| `com.miui.miservice` | Mi Services & User Feedback | SAFE | **Yes** | Disables diagnostic survey prompts and background feedback transmission. |
| `com.miui.yellowpage` | MIUI Yellow Page & Caller ID Engine | SAFE | **Yes** | Eliminates commercial directory lookups, caller telemetry, and targeted marketing banners in the dialer. |
| `com.xiaomi.mipicks` | GetApps (Xiaomi App Store) | SAFE | **Yes** | Removes duplicate proprietary app store, update nag notifications, and promotional app pushes. |
| `com.xiaomi.glgm` | Xiaomi Game Center | SAFE | **Yes** | Eliminates game promotion hub, lockscreen game banners, and in-game ad overlays. |
| `com.miui.videoplayer` | Mi Video Player | SAFE | **Yes** | Adware-ridden media player. Replace with VLC or Just Player. |
| `com.miui.player` | Mi Music Player | SAFE | **Yes** | Removes streaming service with persistent promotional pushes and audio ad injections. |
| `com.xiaomi.midrop` | ShareMe (Mi Drop) | SAFE | **Yes** | Proprietary P2P file transfer tool known for push promotions. Standard Quick Share remains active. |
| `com.miui.translation.kingsoft` | Kingsoft Translation Provider | SAFE | **Yes** | Stops background queries routed through third-party Kingsoft translation APIs. |
| `com.miui.translation.xmtranslator` | Xiaomi Translator Service | SAFE | **Yes** | Terminates unnecessary translation background daemon. |
| `com.miui.compass` | MIUI Compass | SAFE | **Yes** | Removes stock compass app bundled with analytics and location-sharing probes. |
| `com.miui.calculator` | MIUI Calculator | SAFE | **Yes** | Replaces telemetry-equipped calculator with AOSP or Fossify Calculator. |
| `com.miui.weather2` | MIUI Weather | SAFE | **Yes** | Removes stock weather app notorious for feed ads and data broker geolocation pings. |
| `com.xiaomi.payment` | Xiaomi Mi Pay Framework | SAFE | **Yes** | Disables unneeded proprietary payment daemon. Google Pay / Google Wallet remain 100% functional. |
| `com.tencent.soter.soterserver` | Tencent Soter Biometric Daemon | SAFE | **Yes** | Removes biometric payment connector used exclusively for Chinese WeChat payment verification. |
| `com.miui.daemon` | MIUI System Daemon | SAFE | **Yes** | Halts persistent background telemetry aggregation service. |
| `com.miui.micloudsync` | Mi Cloud Sync Push Provider | SAFE | **Yes** | Stops background sync push requests to Xiaomi cloud servers. |
| `com.miui.phrase` | Frequent Phrases Telemetry | SAFE | **Yes** | Removes stock clipboard snippet aggregator. |
| `com.miui.cloudservice` | Xiaomi Cloud Core Framework | CAUTION | With care | Disables all Xiaomi Cloud sync (Contacts, Notes, Find Device, SMS). Only remove if not relying on Xiaomi Cloud. |
| `com.miui.cloudservice.sysbase` | Xiaomi Cloud System Base | CAUTION | With care | Low-level system integration provider for Xiaomi account sync. |
| `com.miui.cloudbackup` | Xiaomi Cloud Backup Client | CAUTION | With care | Stops automatic nightly cloud backups of app data to Xiaomi servers. |
| `com.miui.gallery` | MIUI / HyperOS Stock Gallery | CAUTION | With care | Integrated cloud backup and face recognition gallery. Requires a 3rd party gallery installed first (e.g. Google Photos, Fossify Gallery). |
| `com.miui.cleanmaster` | Tencent CleanMaster Security Module | CAUTION | With care | Deactivates third-party Tencent CleanMaster definitions inside Security app. Some HyperOS versions show a benign toast if deep cleaner is tapped. |
| `com.mi.globalbrowser` | Mi Browser / Mint Browser | CAUTION | With care | Tracking browser known for sending URLs to remote proxies. Ensure Firefox/Chrome/Brave is installed first. |
| `com.miui.screenrecorder` | MIUI Screen Recorder | CAUTION | With care | System screen recording tool. Remove only if not needed or an alternative is preferred. |
| `com.miui.notes` | MIUI Notes | CAUTION | With care | Stock notes app. Any notes not backed up will be inaccessible until restored. |
| `com.miui.voiceassist` | Xiao AI / Mi AI Voice Assistant | CAUTION | With care | Proprietary Xiaomi assistant. Remove if Google Assistant or no assistant is preferred. |
| `com.miui.mediaeditor` | Gallery Photo & Video Editor Suite | CAUTION | With care | Removes integrated gallery editing plugins. Base gallery viewing remains operational. |
| `com.xiaomi.scanner` | Mi Scanner & Camera QR Utility | CAUTION | With care | QR reading subsystem integrated into camera. Removal disables QR scanning inside native camera app. |
| `com.duokan.phone.remotecontroller` | Mi Remote (IR Controller) | CAUTION | With care | Infrared blaster remote controller app. Remove if the physical IR transmitter is not used. |
| `com.miui.securitycenter` | MIUI / HyperOS Security Center | CRITICAL | **NEVER** | Core framework holding permission management, battery settings, network firewall, and thermal dispatchers. Removal causes fatal bootloop. |
| `com.miui.home` | MIUI / HyperOS System Launcher | CRITICAL | **NEVER** | Default home screen provider. Removal without an active alternative launcher renders the device inaccessible. |
| `com.android.thememanager` | MIUI / HyperOS Theme & Lockscreen Engine | CRITICAL | **NEVER** | Core framework for lockscreen rendering, AOD assets, and system wallpapers. Removal breaks lockscreen unlocking. |
| `com.xiaomi.simactivate.service` | Xiaomi SIM Activation Service | CRITICAL | **NEVER** | Essential for carrier registration, network provisioning, and SIM security handshakes in multi-SIM / eSIM environments. |

---

## Samsung One UI Packages (Galaxy S, A, M Series)

> [!NOTE]
> Samsung One UI packages are debloatable via the same `pm uninstall -k --user 0` ADB mechanism. Knox and dm-verity remain fully intact. Google Pay and Samsung Pay continue to function normally.

| Package ID | Human Name | Tier | Safe to Remove? | Notes |
| :--- | :--- | :---: | :---: | :--- |
| `com.samsung.android.bixby.agent` | Bixby Voice Assistant | SAFE | **Yes** | Samsung's proprietary voice assistant. Removal stops persistent wake-word listener and background audio processing. Google Assistant continues to work normally. |

---

## Universal / Stock Android Packages

| Package ID | Human Name | OEM | Tier | Safe to Remove? | Notes |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `com.google.android.feedback` | Google Play Feedback Reporter | Universal | SAFE | **Yes** | Prevents automated crash log and device metric transmission to Google servers. |
| `com.facebook.katana` | Facebook Client (Pre-installed) | Universal | SAFE | **Yes** | OEM factory-installed Facebook stub app. |
| `com.facebook.system` | Facebook System Service | Universal | SAFE | **Yes** | Terminates privileged background service tracking device install events for Meta advertising. |
| `com.facebook.appmanager` | Facebook App Manager | Universal | SAFE | **Yes** | Prevents silent sideloading and background updating of Meta components outside Google Play. |
| `com.facebook.services` | Facebook Core Services | Universal | SAFE | **Yes** | Eliminates continuous Facebook analytics beacons embedded at the system partition level. |
| `com.bsp.catchlog` | Qualcomm BSP CatchLog Collector | Universal | SAFE | **Yes** | Chip-level modem and chipset event logging service. Saves storage writes and CPU cycles. |
| `com.google.android.apps.tachyon` | Google Meet | Universal | CAUTION | With care | Google video calling client. Safe to remove if not actively used. |
| `com.google.android.videos` | Google TV | Universal | CAUTION | With care | Google media store and video library client. |
| `com.google.android.apps.youtube.music` | YouTube Music | Universal | CAUTION | With care | Preloaded YouTube Music client. Remove if another music app is preferred. |
| `com.android.chrome` | Google Chrome | Universal | CAUTION | With care | Ensure another browser (Firefox, Brave) is installed before removing. |
| `com.android.incallui` | Android In-Call UI Framework | Universal | CRITICAL | **NEVER** | Active telephony display interface. Removal completely breaks voice calls. |
| `com.android.systemui` | Android System UI | Universal | CRITICAL | **NEVER** | Manages status bar, navigation bar, quick settings, notification shade, and lockscreen. Removal causes immediate crash loops. |
| `com.android.phone` | Phone Services & Telephony Base | Universal | CRITICAL | **NEVER** | Cellular radio modem integration, SIM card registration, and emergency calling. Removal breaks all cellular functionality. |
| `com.google.android.gms` | Google Play Services | Universal | CRITICAL | **NEVER** | Core Google platform runtime, FCM push notifications, location APIs, and Play Integrity. Removal breaks banking, messaging, and Google apps. |
| `com.android.settings` | Android System Settings Provider | Universal | CRITICAL | **NEVER** | Core device settings application and preferences database. Removal leaves the device unconfigurable. |
| `com.android.packageinstaller` | Android Package Installer | Universal | CRITICAL | **NEVER** | Core OS package installer and permission granting interface. Removal prevents installing or updating apps. |
| `com.android.providers.telephony` | Telephony and SMS Provider | Universal | CRITICAL | **NEVER** | SMS/MMS message database and carrier APN settings. Removal breaks messaging and mobile data. |

---

## Frequently Asked Questions

### Is com.miui.analytics safe to remove?

**Yes.** `com.miui.analytics` is classified **SAFE** in this registry. It is Xiaomi's background telemetry daemon responsible for reporting user interaction events to Xiaomi servers. Removal stops all background reporting. It is fully reversible at any time with `adb shell cmd package install-existing com.miui.analytics`. **Important:** Use the HyperDebloat 3-step purge sequence before removal to avoid the 500mA `system_server` CPU spin loop caused by hidden updates in `/data/app`.

### Is com.miui.msa.global safe to remove?

**Yes.** `com.miui.msa.global` (MIUI System Ads) is **SAFE** to remove. It is the central push advertising engine that injects sponsored content into stock system apps. Removal is reversible. Same 3-step purge applies before removal to prevent the 500mA battery drain bug.

### Should I remove com.xiaomi.joyose?

**Absolutely not.** Despite appearing on many community debloat lists, `com.xiaomi.joyose` is classified **CRITICAL** and is hard-blocked by this framework. Empirical testing confirms it controls CPU thermal regulation limits under high ambient temperatures and provides the system bridge for SMS OTP auto-fill in banking and FinTech apps. Removing it risks thermal runaway and breaks financial 2FA SMS autofill.

### Is com.samsung.android.bixby.agent safe to remove?

**Yes.** `com.samsung.android.bixby.agent` is **SAFE** to remove on Samsung One UI devices. Removal stops the persistent wake-word listener and background audio processing. Google Assistant continues to function normally. Reversible with `cmd package install-existing`.

### What is the `pm uninstall -k --user 0` command?

`pm uninstall -k --user 0 <package>` is Android's native multi-user package management command. The `-k` flag preserves the APK data directory (making restoration instant), and `--user 0` targets the primary user profile only. System partitions (`/system`, `/vendor`, `/product`) remain **read-only and untouched**. This is why Play Integrity continues to pass `MEETS_DEVICE_INTEGRITY` after debloating.

### Does debloating break Google Pay or banking apps?

No. Because `pm uninstall -k --user 0` never modifies system partitions, `dm-verity` remains intact, the bootloader stays locked, and Play Integrity attestation continues to pass. All banking apps, Google Pay, Samsung Pay, and biometric authentication work normally after debloating SAFE-tier packages.

---

*This reference is maintained by the [HyperDebloat-Agent](README.md) open-source project. Package classifications are based on 100+ hours of empirical ADB telemetry, kernel wakelock profiling, and system-state auditing on Xiaomi HyperOS (Android 14 & 15) hardware. MIT Licensed.*

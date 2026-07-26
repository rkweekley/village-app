# Village — Family Productivity App

A Flutter-based family productivity app for managing chores, tasks, shopping, meals, schoolwork, rewards, and family coordination with real-time updates.

## Tech Stack

- **Framework:** Flutter (Dart SDK ^3.12.2)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter
- **Networking:** Dio (HTTP), `web_socket_channel` / SignalR (real-time)
- **Local Storage:** Drift (SQLite), `shared_preferences`, `flutter_secure_storage`
- **Build:** `flutter build web`, code generation via `build_runner` (freezed, json_serializable, riverpod_generator)

## Features

| Feature | Description |
|---|---|
| **Hub** | Family dashboard with welcome banner, quick-access bento grid, and create FAB |
| **Chores** | Manage chores, assignments, and approvals with tabbed interface |
| **Calendar** | Monthly calendar view with event creation and day selection |
| **Tasks** | Create and track one-off tasks |
| **Shopping** | Shopping lists with item management and FAB-driven creation |
| **Meals** | Meal plans and recipe management |
| **School** | School assignments and subjects, tab-switching create FAB |
| **Rewards** | Points-based reward shop with parent-only create access |
| **Family** | Family member management and setup flow |
| **Auth** | Login, registration, and JWT-based session management |

## Getting Started

### Prerequisites

- Flutter SDK ^3.12.2
- Dart SDK ^3.12.2
- A running instance of **Village API** (see `../village-api/README.md`)

### Setup

```bash
# Clone the repo
git clone https://github.com/rkweekley/village-app.git
cd village-app

# Install dependencies
flutter pub get

# Generate models (freezed, json_serializable, riverpod)
dart run build_runner build --delete-conflicting-outputs
```

### Run (development)

```bash
flutter run -d chrome
```

The app expects the API at `http://localhost:5279` by default. Configure via `lib/core/network/dio_client.dart` or environment overrides.

### Build for production

```bash
flutter build web --no-tree-shake-icons
python3 -m http.server 5173 --directory build/web
```

## Architecture

```
lib/
├── core/              # Shared foundation
│   ├── auth/          # Auth service, secure storage
│   ├── database/      # Drift local DB
│   ├── network/       # Dio client, authenticated client
│   ├── router/        # GoRouter config
│   ├── signalr/       # SignalR connection & providers
│   └── theme/         # App theme (VillageTheme)
├── features/          # Feature modules (one per domain)
│   ├── auth/
│   ├── calendar/
│   ├── chores/
│   ├── family/
│   ├── hub/
│   ├── meals/
│   ├── notifications/
│   ├── rewards/
│   ├── school/
│   ├── shopping/
│   └── tasks/
└── shared/            # Shared widgets and utilities
    ├── utils/
    └── widgets/
```

## State Management Pattern

All pages use Riverpod `AsyncValue` patterns:
- `ref.watch(provider)` for reactive reads
- `ref.read(provider.notifier)` for mutations
- `showAdaptiveModalSheet` for create/edit forms (uniform bottom-sheet pattern)

Create actions are consistently exposed via a `FloatingActionButton` (bottom-right) across every feature page.

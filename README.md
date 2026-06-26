# Lumora Frontend

Flutter mobile app for Lumora.

## Requirements

- Flutter SDK compatible with Dart `^3.11.1`.
- iOS Simulator, Android Emulator, or a connected device.

## Setup

```bash
flutter pub get
```

## Run

```bash
flutter run
```

## Mock Mode

The app starts in mock mode by default through `appConfigProvider` in `lib/core/config/app_environment.dart`.

Default API base URL for development mode:

```text
http://127.0.0.1:8000
```

Switch to API mode without editing source:

```bash
flutter run --dart-define=LUMORA_USE_MOCK_DATA=false --dart-define=LUMORA_API_BASE_URL=http://127.0.0.1:8000
```

## Current Foundation

- App bootstrap: `lib/main.dart`
- App shell: `lib/app/app.dart`
- Routing: `lib/app/router.dart`
- Theme tokens: `lib/app/theme.dart`
- API client provider: `lib/core/network/dio_provider.dart`
- Foundation screens: `lib/features/foundation/`
- Shared widgets: `lib/shared/widgets/`

## Checks

```bash
flutter analyze
flutter test
```

## Troubleshooting

- If dependencies are missing, run `flutter pub get`.
- If a simulator cannot connect to local backend, use the platform-specific host address required by the emulator.
- Keep mock mode available so UI work can continue when the backend is unavailable.

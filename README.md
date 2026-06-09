# CyberShield

CyberShield is a Flutter security intelligence mobile app built for the Mobile Development internship project. It brings authentication, live vulnerability intelligence, password health checks, offline security guidance, push alerts, and user preferences into one GetX-based mobile experience.

## Features

### Authentication

- Email/password registration and login through Firebase Auth.
- Google sign-in support.
- Forgot-password flow with validation and Firebase reset email handling.
- Auth state tracking with GetX so signed-in users are routed into the app shell.
- Friendly error mapping for invalid credentials, disabled accounts, weak passwords, network failures, and too many attempts.
- Local secure storage flag for signed-in state cleanup.

### Main App Shell

- Bottom-navigation shell for the main CyberShield sections.
- Centralized GetX routing and feature bindings.
- Shared dark CyberShield visual system with teal primary accents, muted text, warning/danger states, and compact security-focused cards.

### Threat Feed

- Live CVE threat intelligence from the NVD API.
- Recent-window querying so the feed prioritizes current vulnerabilities instead of very old CVEs.
- Newest-first sorting by published date.
- Search by keyword and CPE-aware matching for more accurate product results.
- Severity filtering and threat detail screens.
- Cached threat pages through Hive for fallback/offline viewing.
- Pagination state handled through the API service so load-more behavior matches the filtered result set.

### Password Checker

- Local password strength analysis with levels from empty/weak through very strong.
- Entropy-aware scoring, common-pattern detection, dictionary/common-password checks, and actionable improvement tips.
- Have I Been Pwned k-anonymity range API integration for breach checks without sending the raw password.
- Offline-aware breach checking with clear feedback when the device has no connection.
- Controller state reset and loading protection to prevent duplicate checks.

### Knowledge Base

- Offline-first security education library backed by Hive.
- Built-in articles covering passwords, network safety, phishing, mobile security, and incident response.
- Category browsing, article lists, and full article reader views.
- Bookmark support for saved articles.
- Last-sync metadata and cached article storage.

### Push Notifications and Alerts

- Firebase Cloud Messaging setup for notification permissions, FCM token logging, topic subscriptions, foreground messages, background opens, and cold-start opens.
- Local notification history stored in Hive.
- Alerts tab with read/unread state, unread-count support, mark-as-read, mark-all-read, and clear history behavior.
- Notification tap routing into the Alerts tab, including cold-start handling after the app shell is ready.
- Payload normalization for common Firebase data variants such as CVE IDs, severity, title/body aliases, and CVSS score fields.
- Foreground CyberShield snackbar with severity-colored styling and a direct view action.

### Profile and Preferences

- Local user profile model with JSON serialization.
- Watchlist technologies for alert/topic personalization.
- Notification preference controls for all notifications, critical alerts, and quiet hours.
- Topic subscription sync for all alerts, critical alerts, and watchlist technology topics.
- Persistent profile preferences through Hive.

### Offline Storage

- Hive-based local storage without custom TypeAdapters.
- Map-based serialization through `toJson` / `fromJson`.
- Separate boxes for knowledge articles, bookmarks, sync metadata, threat cache, profile, and notification history.

### Testing

The project includes unit tests for:

- Auth controller/service behavior.
- Threat advisory parsing and severity mapping.
- Threat feed filtering, pagination, and ordering.
- Password analyzer and password controller behavior.
- API service CPE ranking.
- Notification preference filtering.
- User profile serialization.

It also includes an integration test for the auth navigation flow.

## Tech Stack

- Flutter and Dart.
- GetX for state management, routing, dependency injection, and app navigation.
- Firebase Auth for authentication.
- Firebase Cloud Messaging for push notifications.
- Hive for local/offline storage.
- Dio for HTTP requests.
- connectivity_plus for network-state checks.
- flutter_secure_storage for secure auth-related local state.
- crypto for SHA-1 hashing used by the HIBP k-anonymity password check.
- mockito and build_runner for tests.

## Project Structure

```text
lib/
  main.dart
  app/
    bindings/        GetX dependency bindings
    controllers/     Feature state and business flow controllers
    models/          JSON/map-backed app models
    routes/          App route names and GetPage definitions
    services/        Firebase, API, storage, and notification services
    utils/           Constants, validators, password analysis
    views/           Auth, shell, feed, password, knowledge, alerts, profile UI

test/
  controllers/
  models/
  services/
  utils/
  helpers/

integration_test/
  auth_navigation_flow_test.dart
```

## Running Locally

Install dependencies:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Run unit tests:

```bash
flutter test
```

Run the app:

```bash
flutter run
```

Firebase configuration files are local environment files and are not committed:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Make sure those files are available locally before running Firebase-dependent flows.

## Current App Sections

- Sign in
- Sign up
- Forgot password
- Home
- Threat feed
- Threat detail
- Password checker
- Knowledge library
- Category article list
- Article reader
- Alerts
- Profile

## Notes

CyberShield is focused on practical mobile security workflows: finding current vulnerabilities, checking password risk safely, learning from offline guidance, and receiving actionable alerts without losing local state.

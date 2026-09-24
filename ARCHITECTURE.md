# Tidy — Implementation architecture

## Fixed decisions and current baseline

Flutter/Dart, iOS-first (iOS 17+), Riverpod and go_router. Use feature-first organization, centralized theme tokens, and repositories backed by services for native/device functionality. Processing and user data stay on-device; no remote backend. Business logic belongs outside widgets.

`App/` contains ProviderScope, TidyApp, a Riverpod-owned GoRouter, five shell branches, bundled Nunito/DM Sans fonts and `core/design/` tokens. The shared `TidyNavigationShell` lives in `core/widgets/tidy_navigation_shell.dart`; `app.dart` only configures the app/theme/router. Group 01's approved UI is implemented. Home/scanning work is owned by the separate Group 02 checkpoint; Group 01 only navigates to the existing `/home` destination.

The prototype is the visual authority. PRODUCT's HTML/CSS/JavaScript stack describes the prototype only; Flutter is the production stack. Follow [PRD.md](PRD.md) for behavior and [AGENTS.md](AGENTS.md) for permanent rules.

## Folder structure

```text
App/
  lib/
    main.dart                     # ProviderScope and launch only
    app.dart                      # App configuration
    core/
      design/                     # Theme, fonts, colors, sizes, spacing,
                                  # radii, shadows and motion tokens
      router/                     # go_router configuration
      widgets/                    # Shared shell, navigation and reusable UI
      models/                     # Only models used by multiple features
      services/                   # Only shared device/storage adapters
    features/
      <feature>/
        presentation/pages/       # Screens; preserves existing Home placement
        widgets/                  # Meaningful feature-specific widgets
        controllers/              # Riverpod state and workflow logic
        models/                   # Feature values and state types
        repositories/             # Domain operations and data reconciliation
        services/                 # Plugin/native calls and persistence I/O
  assets/fonts/                   # Bundled fonts and licenses
  ios/Runner/                     # Small Swift integrations when needed
  test/                          # Mirrors relevant feature/core boundaries
```

Feature names: `onboarding`, `permissions`, `home`, `scan`, `photos`, `videos`, `contacts`, `cleanup`, `settings`; add `compression`, `vault`, `calendar`, `widgets`, `history` in Group 8 as needed. A group can touch several features. Create folders and abstractions only when used, not empty scaffolding for every future feature.

Every meaningful UI component must be implemented in its own `.dart` file. Screens should primarily compose imported widgets. Feature-specific widgets go directly in `features/<feature>/widgets/`; reusable app-wide widgets go in `core/widgets/`. Do not extract separate files solely for trivial Text, Padding, Row, Column or SizedBox elements.

## State and dependencies

- Use ordinary Riverpod providers for repository/service injection; use Notifier/AsyncNotifier for workflows and AsyncValue for asynchronous loading/errors. Start without code generation.
- Widgets render state and forward user intent. Keep matching, sorting policies, totals, permission reconciliation, persistence and mutation decisions in controllers/repositories/services.
- Repositories expose app-level operations and models. Services wrap native APIs/plugins and return typed outcomes. Share media access between Photos, Videos and scanning rather than duplicating libraries.
- Keep scan findings, user-selected IDs and operation outcomes separate. One cleanup controller owns cross-category media/contact selection and derived totals; calendar and vault use separate scopes. Use stable IDs and count each media asset once.
- On confirmation, freeze an operation snapshot of reviewed IDs and relevant versions. Revalidate access and records before execution; changed items return for review. Prevent duplicate submission. Do not perform mutations in provider initialization, widget build, route builders or automatic retries.
- Keep selection alive across navigation; dispose transient preview resources when unused. Permission/library changes invalidate stale data, not unrelated choices. Use bounded batches and background computation where needed to keep the UI responsive.

## Navigation and frame mapping

Keep the five existing shell roots: `/home`, `/photos`, `/videos`, `/contacts`, `/settings`. Use go_router branches to preserve tab stacks. Push detail screens with native-feeling back behavior. Keep state in Riverpod, not serialized media objects in routes. Optional tools are secondary destinations.

Group 01 starts at `/onboarding`, which reads local completion and current OS authorization before opening Welcome or the existing Home destination. `/onboarding/welcome`, `/onboarding/privacy`, and `/onboarding/photos` / `contacts` are Cupertino pages; limited, denied, restricted and granted access are states, not extra routes. The corresponding `/request` pages retain the approved handoff layout and launch real iOS requests after Continue. There are no simulation routes. Completion is saved only after finishing or skipping the Contacts step; a failed save remains retryable. Skipping never grants permission. How It Works remains an explicitly unavailable Group 07 connection.

`features/onboarding/controllers/onboarding_controller.dart` owns asynchronous authorization and completion workflows. Its repository wraps `services/onboarding_service.dart`, which uses the `tidy/onboarding` method channel and `ios/Runner/OnboardingNativeService.swift`. Refresh OS status on app resume; never persist it as authority. Serialize requests and completion writes; do not request again when status is already determined. Photos uses read/write authorization and the native limited-library picker. Contacts limited access is supported only where iOS reports it (iOS 18+); managing Contacts access opens app Settings. Restricted access cannot be overridden by Tidy. Unsupported platforms/statuses stay explicitly unsupported.

The only Group 01 persisted value is a versioned completion marker in Application Support, protected on disk and excluded from backup. No additional packages, UserDefaults, media/contact reads, or remote services are needed for this step. Real permissions must still be validated on controlled devices, especially restricted and OS-version-specific limited access.

| Frames | Screen / state / overlay mapping |
| --- | --- |
| 01–10 | Startup/onboarding and permission explanation screens. 05/09 are real OS handoffs; 06/07/10 are permission states, not separate mandatory routes. |
| 11–15 | Scan screen and Home. Scanning, clean and no-access variants are states of those screens. |
| 16–22 | Photos overview, category list, group comparison and media viewer. 19/22 are selection states of 17/21. |
| 23–25 | Video list and viewer; 25 is list selection state. |
| 26–31 | Contacts list, comparison, merge preview and deletion selection. 29 is confirmation sheet/dialog; 30 is merge outcome state. |
| 32–38 | Cleanup review, processing and result surfaces. 33 is confirmation overlay; 36 is refreshed Home; 37 is partial-result state; 38 is remaining-item review. |
| 39–53 | 39–43 are category empty states, 44 interrupted scan, 45 permission change, 48 OS Settings handoff. Settings and its subpages cover 46/47/49–53. How-it-works can also open from onboarding. |
| 54–61 | Blurry category and swipe review; compression screen with progress/result/failure/low-space states; 59 is original-removal confirmation. |
| 62–65 | Vault setup, locked/unlocked library and import; 63 is native authentication handoff. |
| 66–71 | Calendar explanation, list and review; 67 is OS handoff, 70 confirmation overlay, 71 denied state. |
| 72–73 | Widget setup/help and cleanup history screens; actual widgets live in an iOS extension. |

Do not copy prototype board controls, demo scenario menus or simulated system dialogs into the production app. Native system UI may differ from the reference; preserve the surrounding approved app design.

## Device services and local persistence

| Area | Responsibility |
| --- | --- |
| Permissions | Read current OS status, request after explanation, manage limited access and Settings return. Never persist permission flags as authoritative. |
| Media/scanning | Photos library enumeration, thumbnails, resource availability, metadata and user-approved changes; on-device duplicate/similarity analysis; real progress and cancellation. Keep exact matching distinct from similarity. |
| Storage | Public device-capacity readings and carefully labeled estimates; do not claim access to other apps' caches or full system storage categories. |
| Contacts | Native contact store read/write, matching evidence, merged preview and reviewed changes. Verify field preservation and supported records before enabling merge. |
| Compression | Native video playback/export support, space checks, cancellation, copy verification and separately approved original deletion. |
| Vault | Protected local files and metadata, encryption/key protection, native device authentication and session locking. Authentication UI alone is not storage protection. |
| Calendar | Native event access and explicit selected-occurrence deletion; honor read-only records and permission failures. |
| Widgets | WidgetKit extension with an App Group containing only the local aggregate summary needed for display; open-app navigation, no destructive actions. |

Use a small local preferences store for onboarding completion and scan preferences. Add a local database when scan checkpoints, ignored groups and cleanup history require structured records; keep this behind a storage service. Save minimal metadata rather than full contact records or duplicate media. Media previews/cache are bounded and disposable; vault copies are durable protected data. Exclude Tidy's private user data from app-managed cloud transfer and configure backup handling to uphold on-device storage.

Persist operation outcomes sufficiently to reconcile interruptions, but never treat a saved queue as renewed deletion authority. A restored selection requires revalidation and explicit confirmation. Unknown outcomes must be checked against the source before reporting success or offering retry. Actual OS stores remain authoritative.

Use native Photos, Contacts, EventKit, AVFoundation, LocalAuthentication/Keychain and WidgetKit through a maintained Flutter plugin or a small Swift service adapter, as needed by each group. Add usage descriptions and entitlements only with the corresponding feature. Do not download cloud-only assets automatically; report local unavailability. Platform capability details and preservation limits must be verified during each native integration.

## Dependencies

Foundation currently requires `flutter_riverpod` for state/dependency ownership and `go_router` for navigation, alongside Flutter SDK tooling. Fonts are bundled; no runtime font service is needed. Add native-access, persistence or playback packages only when the active group needs them, after checking current iOS support, privacy behavior and the APIs actually required. Avoid parallel dependency-injection frameworks, generic base repositories and speculative abstractions.

## Implementation workflow

**Foundation → Group 1 screens + functionality → test/review/commit → Group 2 screens + functionality → test/review/commit → continue group-by-group through Group 8.**

| Stage | Deliverable |
| --- | --- |
| Foundation | Review/refine existing app entry, Riverpod, router, shell, shared token/theme setup and fonts against these rules. |
| Group 1 | Onboarding and real permission requests/recovery. |
| Group 2 | Actual scanning, storage readings and Home states. |
| Group 3 | Photo findings, comparison, keepers and explicit selection. |
| Group 4 | Video list, real preview and selection. |
| Group 5 | Contact comparison, safe merge and deletion selection. |
| Group 6 | Consolidated review, confirmed cleanup and truthful outcomes. |
| Group 7 | Complete state coverage, recovery and settings. |
| Group 8 | Blurry/swipe tools, compression, protected vault, calendar, widgets and history. |

Each stage includes the UI and the functionality needed for its own scope. Build shared dependencies at their first use. Later-group entry points must not pretend to work: for example, Group 1's scan handoff connects when Group 2 lands, and Group 3/4 deletion connects in Group 6. Implement necessary permission/error/safety handling immediately, even if the full corresponding presentation is catalogued in Group 7. Group 5 merge confirmation must be safe before its mutation is enabled.

Before proceeding to the next group: run `flutter analyze`; run focused controller/repository/widget tests for changed behavior; review relevant iOS simulator screenshots against exports and inspect accessibility; exercise native permissions and destructive operations on controlled test data on a device when applicable. Verify cancellation, selection continuity and success/partial-failure accounting. Record scope, checks and known deferred connections in the commit. Commit only the completed stage's changes, preserving unrelated work; do not push unless requested. These checkpoints are part of implementation, not authorization to implement during a documentation-only task.

## Reference differences to preserve or resolve

- PRODUCT's web stack is prototype-specific; the production stack above resolves the documentation gap.
- Fixed frame dimensions and synthetic storage/history totals are design fixtures, not device promises.
- The prototype's final vault handler removes selected copies without a separate confirmation dialog. Apply the user's stronger permanent rule: explicit review and confirmation for vault removal too; do not modify the reference.
- Navigation-shell extraction is complete; maintain the shared widget boundary during future groups.

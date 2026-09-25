# Tidy — Implementation architecture

## Current implementation (checkpoint and working tree)

Flutter/Dart, iOS-first (iOS 17+), Riverpod and go_router. Use feature-first organization, centralized theme tokens, and repositories backed by services for native/device functionality. Processing and user data stay on-device; no remote backend. Business logic belongs outside widgets.

`App/` contains `ProviderScope`, `TidyApp`, a Riverpod-owned `GoRouter`, five shell branches, bundled Nunito/DM Sans fonts, and `core/design/` tokens. `main.dart` starts the app; `app.dart` configures theme and routing; `TidyNavigationShell` is shared UI. The Group 02–04 working implementation is preserved in checkpoint commit `80901fc` on `feature/groups-02-04-working-checkpoint`; this documentation revision is not yet committed.

Current scope: Group 01 onboarding/permissions; Group 02 Home and native scan; Group 03 Photos review/selection/deletion; Group 04 large-video review/playback/selection/deletion. Contacts review, merge, and deletion code already exists in the four local commits ahead of `origin/main`, but Group 05 is not declared complete. Blurry-photo and swipe routes exist, but do not constitute completed Group 08. The consolidated Group 06 cleanup flow and Group 07 Settings are not implemented; `/settings` is a placeholder. Compression, vault, calendar, widgets, and history are not implemented.

The prototype is the visual authority. PRODUCT's HTML/CSS/JavaScript stack describes the prototype only; Flutter is the production stack. Follow [PRD.md](PRD.md) for behavior and [AGENTS.md](AGENTS.md) for permanent rules.

## Folder structure

```text
App/
  lib/
    main.dart                     # ProviderScope and launch only
    app.dart                      # App configuration
    core/
      design/                     # Theme and visual tokens
      router/                     # go_router configuration
      widgets/                    # Shared shell and reusable UI
    features/
      <feature>/
        presentation/pages/       # Screens
        widgets/                  # Meaningful feature-specific widgets
        controllers/              # Riverpod state and workflow logic
        models/                   # Feature values and state types
        repositories/             # Feature data/domain operations
        services/                 # Native method-channel calls
  assets/fonts/                   # Bundled fonts and licenses
  ios/Runner/                     # Small Swift integrations when needed
  test/                          # Mirrors relevant feature/core boundaries
```

Existing feature folders are `onboarding`, `home`, `scan`, `photos`, `videos`, and `contacts`. There is no `cleanup`, `settings`, or Group 08 feature module yet. Add folders only when implementation needs them.

Every meaningful UI component must be implemented in its own `.dart` file. Screens should primarily compose imported widgets. Feature-specific widgets go directly in `features/<feature>/widgets/`; reusable app-wide widgets go in `core/widgets/`. Do not extract separate files solely for trivial Text, Padding, Row, Column or SizedBox elements.

## Riverpod and current data flow

- Plain `Provider`s inject services/repositories. `ScanController` is one non-auto-disposed `Notifier<ScanState>` shared by Home, Photos, Videos, and Contacts. `ScanRepository` decodes native status (off the UI isolate with `compute`) and retains the last completed result across transient scan/error states. `scanSnapshotProvider` derives Home-facing categories, storage, and progress; it does not own another scan.
- `PhotoGroupRepository` derives exact-hash and visual-similarity groups from that scan. `PhotoSelectionController` holds selected photo IDs and keeper choices separately from discovery. `VideosController` holds sorting, video selections, and deletion outcome; `VideoRepository` derives large videos from the same scan. Neither Photos nor Videos starts a scan simply by opening its page.
- `ContactsController` is an `AsyncNotifier`: after a completed scan it fetches current contact details via `ContactsRepository`/`ContactsService`, then limits review pairs to groups found by the shared scan. Ignored pairs and selected IDs are currently in memory, not persisted. Native Contacts changes reconcile contact findings independently from Photos.
- Onboarding has its own Riverpod controller/repository/service and persists only its completion marker. Photo, video, and contact operations use feature services and native revalidation. There is no cross-category cleanup controller or database yet. UI pages still coordinate some review/confirmation steps; do not describe that separation as complete.
- **DISCOVERED != SELECTED != DELETED.** Findings never authorize cleanup. Photo/video/contact selections are separate state; destructive operations require explicit review and confirmation. Native services recheck access and target records, and only reported removed media IDs are applied to the shared scan.

## Navigation now

`appRouterProvider` owns one `GoRouter`, initially at `/onboarding`. A `StatefulShellRoute.indexedStack` holds the five tab roots: `/home`, `/photos`, `/videos`, `/contacts`, and `/settings`. `/settings` currently renders a placeholder. Onboarding and the scan page are outside the shell; Photo collection/comparison/viewer/review/swipe and Video viewer routes are also top-level Cupertino pages. Routes pass stable asset IDs or small enum/query values, not media objects; Riverpod owns the data.

Group 01 starts at `/onboarding`, which reads local completion and current OS authorization before opening Welcome or the existing Home destination. `/onboarding/welcome`, `/onboarding/privacy`, and `/onboarding/photos` / `contacts` are Cupertino pages; limited, denied, restricted and granted access are states, not extra routes. The corresponding `/request` pages retain the approved handoff layout and launch real iOS requests after Continue. There are no simulation routes. Completion is saved only after finishing or skipping the Contacts step; a failed save remains retryable. Skipping never grants permission. How It Works remains an explicitly unavailable Group 07 connection.

`features/onboarding/controllers/onboarding_controller.dart` owns asynchronous authorization and completion workflows. Its repository wraps `services/onboarding_service.dart`, which uses the `tidy/onboarding` method channel and `ios/Runner/OnboardingNativeService.swift`. Refresh OS status on app resume; never persist it as authority. Serialize requests and completion writes; do not request again when status is already determined. Photos uses read/write authorization and the native limited-library picker. Contacts limited access is supported only where iOS reports it (iOS 18+); managing Contacts access opens app Settings. Restricted access cannot be overridden by Tidy. Unsupported platforms/statuses stay explicitly unsupported.

The onboarding completion marker is versioned in Application Support, protected on disk and excluded from backup. OS permission status is always read from iOS, not from that marker. Real permission behavior still needs controlled-device validation, especially restricted and OS-version-specific limited access.

The approved 73 frames remain the visual reference, **not 73 routes**. Loading, empty, permission, selection, confirmation, failure, and success are states or sheets where appropriate. Existing photo deletion uses a bottom confirmation sheet modeled on frame 33, but that is not the consolidated Group 06 cleanup flow.

Do not copy prototype board controls, demo scenario menus or simulated system dialogs into the production app. Native system UI may differ from the reference; preserve the surrounding approved app design.

## Native services, scan lifecycle, and persistence now

`AppDelegate.swift` registers small Swift integrations:

| Channel / service | Current behavior |
| --- | --- |
| `tidy/onboarding` / `OnboardingNativeService` | Reads and requests Photos/Contacts permission only after the corresponding onboarding action; manages limited Photos and opens Settings; stores onboarding completion locally. |
| `tidy/device_library` / `LibraryScanService` | Explicit full scan, status/progress/cancel, restore, domain-scoped reconciliation, and confirmed-media-ID removal. Reads PhotoKit/CNContactStore and volume capacity. |
| `tidy/photos` / `PhotoLibraryNativeService` | Current permission, offline thumbnails, and selected PhotoKit deletion after IDs/access are checked. |
| `tidy/videos` / `VideoLibraryNativeService` | Offline video preview/details, AVPlayer platform view, and selected PhotoKit deletion with metadata revalidation. |
| `tidy/contacts` / `ContactsNativeService` | Contact read, reviewed pair merge, and selected deletion; rechecks versions. Apple's protected Notes field is not fetched, and merge requires its limitation to be acknowledged. |

The **main scan** is a single shared result, not one scan per tab. The first full scan starts from the explicit onboarding scan handoff; later full scans start only from user-invoked scan/rescan controls (including category recovery controls). Opening or switching tabs only reads state. `ScanController` polls native status while active (about 1 second during a scan, 10 seconds with results), refreshes status on resume, and cancels a running full scan on pause. A scan interrupted by suspension/termination is not presumed to keep running.

Swift writes the last successful, lightweight result atomically to `Application Support/TidyScan/completed-v1.json`, with file protection and backup exclusion; an `interrupted` marker records an unfinished full-scan attempt. It stores asset IDs, metadata, measurements/hashes, similarity edges, aggregate contact-match IDs, permissions-at-scan, storage figures, and timestamps—not copies of photo/video bytes or contact records. On launch, saved findings appear first; a queued lazy check compares PhotoKit identifiers/metadata and Contacts history, reads/analyzes only new or changed assets plus affected similarity windows, and updates the relevant domain. PhotoKit and Contacts notifications schedule separate reconciliations. No automatic full scan or permission request happens on startup.

After a confirmed in-app photo/video deletion, the returned removed IDs are taken out of the shared snapshot and similarity edges, category projections recalculate, and the snapshot is saved; this does not enter the full-scan flow. External changes reconcile asynchronously. Revoked access hides that domain; limited Photos access covers only accessible assets. Failed/cancelled/incomplete scans do not overwrite the last successful snapshot. A normal relaunch restores it; iOS can stop any in-flight reconciliation, so the next launch checks again. Storage capacity/free-space readings are device readings, **not** a promise that Recently Deleted media has freed space. Contact records are fetched for review but are not persisted in the scan snapshot. Selections, ignored contact pairs, and operation queues are not durable.

The current scanner uses offline PhotoKit resource reads for bytes/content hashes, local thumbnails plus Vision feature prints for possible visual matches, and local blur scoring. Unknown/unavailable data stays unknown. There is no remote backend, cloud fetch, local database, background worker, or media duplication into app storage. No EventKit, compression/export, vault, WidgetKit extension, or history persistence is implemented yet.

## Dependencies

The only current app packages beyond Flutter are `flutter_riverpod` and `go_router`; native functionality is provided by Swift method channels and a video platform view, not an additional Flutter plugin. Fonts are bundled. No remote SDK, database package, or background-service package is installed.

## Implementation workflow

The approved delivery order remains Foundation → Group 01 → Group 02 → Group 03 → Group 04 → Group 05 → Groups 06–07 → Group 08, with test/review/commit checkpoints. The Group 02–04 working code is now in checkpoint `80901fc`. The four earlier local commits include part of Contacts work; the remaining Group 05 scope must be assessed against the PRD and device behavior rather than reimplemented blindly. Group 06 consolidated cleanup, Group 07 states/settings, and most of Group 08 remain future work.

Prepare separate branch refs for remaining work: `feature/group-05-contacts`, `feature/groups-06-07`, and `feature/group-08-bonus`, all based on the Group 02–04 checkpoint. Branch creation does not include this uncommitted documentation edit. Work on one group at a time on its own branch; do not silently carry dirty files across groups, merge, rebase, or push as part of this documentation task. Continue to run `flutter analyze`, focused tests, design review, and controlled-device checks at each later checkpoint.

## Reference differences to preserve or resolve

- PRODUCT's web stack is prototype-specific; the production stack above resolves the documentation gap.
- Fixed frame dimensions and synthetic storage/history totals are design fixtures, not device promises.
- The prototype's final vault handler removes selected copies without a separate confirmation dialog. The permanent safety rule requires explicit review and confirmation if vault removal is implemented; do not modify the reference.
- Navigation-shell extraction is complete; maintain the shared widget boundary during future groups.

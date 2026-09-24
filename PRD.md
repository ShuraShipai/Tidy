# Tidy — Product requirements

## Authority and scope

Implement the iPhone storage utility described in [Design/PRODUCT.md](Design/PRODUCT.md). [Design/tidy_design.html](Design/tidy_design.html) is the approved visual source of truth; [Design/DESIGN.md](Design/DESIGN.md) defines its design language and [Design/exports/](Design/exports/) supplies comparison images. Preserve these references. Prototype fixtures, timers and simulated native dialogs are demonstration mechanisms, not production requirements.

The app uses Flutter, targets iOS 17+ first, and keeps processing and user data on-device. No remote backend, uploads, account system, cloud processing or app-managed cloud sync. All features are free: no subscriptions, paywalls, trials, email cleaning, RAM cleaning, system-junk cleaning or other-app cache cleaning.

Implement all eight approved groups in order. Group 8 tools are optional for users and remain secondary entry points, not extra tabs. Architecture and delivery rules are in [ARCHITECTURE.md](ARCHITECTURE.md).

## Safety contract

**DISCOVERED != SELECTED != DELETED.**

The workflow is scan → discover → review → select → final review → confirm → process → result.

- Discovery and keeper recommendations never select or delete anything. Bulk selection requires a deliberate user action.
- Previewing, changing filters, switching tabs and canceling confirmation preserve available selections. Category edits affect only that category.
- Final review shows the exact selected items, category counts and estimated media size. An empty selection cannot proceed.
- Only explicit confirmation authorizes processing of the reviewed selection. Changes to that selection or source records require renewed review and confirmation.
- Deletion, contact merging, removal of an original video and removal of vault copies all require review and confirmation. Native approval prompts supplement the app's review flow.
- Results count only confirmed successful operations. Failed or unprocessed items remain reviewable; retry returns through review and confirmation. Never automatically repeat a destructive operation after interruption.
- Permission loss removes unavailable items from actionable selection while preserving accessible choices. Explain the change; permission changes never delete content.

## Requirements by design group

| Group / frames | Real app requirements |
| --- | --- |
| 1. Onboarding & permissions / 01–10 | Splash, welcome and privacy explanation; Photos and Contacts permission explanations followed by real system requests. Support skipping access, Photos limited access, denial and Settings recovery. Reflect actual OS authorization states, including restricted or limited access where available. Other accessible features remain usable. |
| 2. Scanning & Home / 11–15 | Scan accessible libraries on-device with progress, cancellation and completed results. Show storage capacity, used/free space, reviewable category totals and scan freshness. Support scanning, clean-library and no-access states. Scan Again never changes selections automatically. |
| 3. Photo cleaning / 16–22 | Photos overview; duplicate/similar groups and filters; comparison and full preview with metadata; changeable suggested keeper; explicit Select All Except Best; screenshots sorting, selection and deselection. Preview and selection controls remain distinct. |
| 4. Video cleaning / 23–25 | Large-video list sorted by largest/newest/oldest, real playback with metadata, independent selection and review action. Compression entry connects to Group 8 when available. |
| 5. Contact cleaning / 26–31 | Show possible duplicate groups and matching evidence. Compare source records, ignore/keep separate, preview merged fields and explicitly confirm merging. Preserve unique supported details; do not silently discard conflicting or unreadable fields. Contact deletion is a separate selection/review operation. Report actual merge outcomes. |
| 6. Review & clean / 32–38 | Consolidated media/contact review with category editing; destructive confirmation; progress for approved items; success, updated Home, partial failure and remaining-item review. Keep counts and estimates consistent throughout. |
| 7. States & settings / 39–53 | Category empty states; interrupted-scan resume/restart; permission-change recovery; permission management; screenshot/video scan preferences; Strict/Balanced/Broad similarity sensitivity; privacy, how-it-works and actual app version. Preferences affect discovery only. |
| 8. Bonus tools / 54–73 | Possibly blurry-photo review; swipe selection/keep with undo; compression options, progress, copy comparison, Keep Both and separately confirmed original removal; failure and temporary-space states. Private Vault setup, device authentication, separate copy selection, import, lock/unlock and reviewed removal. Calendar access requested on entry, old/repeated event review and confirmation scoped to selected occurrences. Small/medium Home Screen widgets and local cleanup history. |

## Honest native behavior

- Replace sample counts, sizes, dates and progress with measured data. Unknown sizes are unknown, not zero. Deduplicate media IDs across categories when totaling a selection.
- Distinguish estimated removable bytes from actual available storage. Explain Recently Deleted retention; never promise immediate reclamation or offer automatic permanent purging.
- Similarity and blur findings are suggestions, not guarantees. Do not label approximate matches as verified exact duplicates.
- Compression creates and verifies a separate playable copy before original removal can be offered. Cancellation, insufficient space or failure leave the original intact.
- Vault import copies items without deleting Photos originals. Keep its data and selection separate from cleanup, protect stored copies, and lock when leaving the authenticated session. Face ID/device passcode is local device authentication, not an account feature.
- Calendar confirmation identifies the selected occurrences and states that Tidy provides no undo. Do not implicitly remove an entire recurring series.
- History derives from successful operations and real dates; an empty history has no fabricated totals. Widgets show a dated local summary and open Tidy; they never initiate cleanup.
- Handle unavailable local resources without initiating cloud retrieval. Tidy controls its own data handling; do not promise control over the user's existing system-managed Photos, Contacts or Calendar sync.

## Visual and accessibility acceptance

Preserve the approved clay surfaces, Nunito/DM Sans typography, colors, spacing, hierarchy and five tabs: Home, Photos, Videos, Contacts, Settings. Bundle fonts locally. The 393 × 852 frames are comparison references; use real safe areas and adaptable layouts rather than drawing a phone/status bar or fixing the app to those dimensions. Support text scaling, VoiceOver, non-color selection indicators, Reduce Motion, Increase Contrast and at least 44pt touch targets.

The 73 frames represent screens, states and overlays—not 73 routes. Each group is complete only when its applicable permission, empty, loading, cancellation, error and success behavior works with real device services and its safety checks pass. See the group delivery gate in ARCHITECTURE.md.

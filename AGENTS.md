# Tidy implementation rules

- Read `PRD.md` and `ARCHITECTURE.md` before implementation. Product scope comes from `Design/PRODUCT.md`; `Design/tidy_design.html` is the approved visual source, supported by `Design/DESIGN.md` and `Design/exports/`. Do not edit design references unless explicitly asked. Do not redesign or invent features.
- Build in `App/` using Flutter/Dart, iOS-first, Riverpod and go_router. Follow the feature-first layout in ARCHITECTURE.md. Keep `main.dart` minimal.
- Every meaningful UI component must have its own `.dart` file. Screens should primarily compose imported widgets. Feature-specific widgets belong in `features/<feature>/widgets/`; reusable app-wide widgets belong in `core/widgets/`. Do not create separate files solely for trivial Text, Padding, Row, Column or SizedBox elements. Keep business logic outside UI widgets.
- Centralize theme, fonts, colors, sizes, spacing, radii, shadows and motion in `core/design/`. Bundle fonts locally. Adapt reference frames to real safe areas and text scaling; preserve accessibility and native navigation behavior.
- Access device functionality through repositories backed by services. Add only dependencies and abstractions required by the active work. No remote backend, cloud processing, uploads, account system or app-managed cloud sync; processing and user data stay on-device. Local vault device authentication is permitted by the approved design.
- **DISCOVERED != SELECTED != DELETED.** Never auto-select from discovery. Never delete without explicit review and confirmation. Apply the same safeguards to contact merges, original-video removal and vault-copy removal. Preserve available selections on preview/cancel; retry or restoration never grants deletion authority.
- Keep operation scope fixed to confirmed items. Revalidate changed data/access, prevent duplicate submission, and count only verified successes. Label storage estimates honestly. Never substitute demo data or simulated permissions for working device functionality.
- Treat the 73 frames as screens, states and sheets/dialogs, not 73 routes. Follow the mapping in ARCHITECTURE.md.
- Work in order: Foundation → Group 1 screens + functionality → test/review/commit → Group 2 → test/review/commit → continue through Group 8. Implement prerequisite safety/error behavior at first use; do not jump ahead to build all screens.
- At each checkpoint, run analysis and focused tests, review design fidelity and relevant native behavior, then commit only the stage's changes. Preserve unrelated user work. Do not push without a request. Report genuine blockers and source contradictions rather than silently weakening safety or scope.

### Real Data Only

- Never use dummy, mock, or hardcoded user data in the Flutter app.
- No fake photos, videos, contacts, storage values, scan results, or cleanup results.
- Until real functionality is connected, use the designed loading, empty, or permission state.
- Static design assets such as icons, illustrations, and decorative elements are allowed.
- Data-driven UI must use real device/service data.

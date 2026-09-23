# Tidy application prototype

Open `tidy_design.html` in a modern browser. No server or build step is needed. Keep the `assets` folder beside the HTML file; photos and fonts work offline.

The board contains **73 raw 393 × 852 screens** arranged horizontally in eight logical groups. The zoom control changes only the board presentation, not the frame dimensions. Use **Play prototype** to follow the interactive journey, or **Play ↗** above any frame to inspect that screen.

## Interactive demo

- Selections start empty. Discovery never selects anything.
- Use permission handoffs to choose simulated full, limited or denied access.
- Select individual items, compare previews, return to the list, and edit categories without losing other selections.
- Review and cancel freely. The red confirmation action is required before fixture items are removed.
- **Load example selection** explicitly selects the documented fixture: 42 similar photos (386 MB), 34 screenshots (182 MB), three videos (4.232 GB), and four contacts. The complete selection is 83 items and 4.8 GB, displayed consistently throughout the connected review journey.
- The demo scenario menu exercises partial cleanup, compression failure and insufficient temporary storage. Failed items stay selected and reviewable; retry operates only on the remaining selection.
- Reset demo clears local fixture state. Demo selection, cleanup state and history are retained in this browser's local storage.

## Coverage

1. Onboarding and permissions: splash, welcome, privacy, Photos and Contacts explanations, handoffs, limited access and denial.
2. Scanning and Home: initial scan, dashboard, ongoing scan, clean library and unavailable permissions.
3. Photo cleaning: overview, similar groups, comparison, selection, full preview and screenshots.
4. Video cleaning: largest-first list, preview and selection.
5. Contacts: possible duplicates, record comparison, merged preview, confirmation, result and deletion selection.
6. Review and cleanup: consolidated review, final confirmation, progress, result, updated Home, partial failure and remaining items.
7. States and settings: five individual empty states, interrupted scan, permission changes, permissions management, scan preferences, sensitivity, privacy, how-it-works and version.
8. Bonus tools: blurry photos, swipe decisions with undo, compression and original removal, private vault and authentication handoff, calendar permissions/review/confirmation, widget previews and local history.

## Exported visuals

`exports/complete-flow-board.png` shows the complete board. `exports/screens/` contains one PNG per screen, each exactly 393 × 852 with no device mockup. The HTML is the interactive source; the PNGs can be placed into Figma as raster references, not editable Figma components.

## Design system and accessibility

`DESIGN.md` records the implemented tokens and component language. `.impeccable/design.json` contains component samples and motion/elevation metadata. The board's Accessibility controls demonstrate larger text, increased contrast and reduced motion. Interactive items provide semantic buttons, focus outlines, text labels and pressed states; navigation supports keyboard and left-edge swipe back.

This is an HTML representation of an iOS application. Native Dynamic Type, VoiceOver integration, SF Symbols, Photos/Contacts/Calendar APIs, WidgetKit, haptics and LocalAuthentication must be wired in the native implementation. Browser controls demonstrate their intended behavior. Real video encoding/playback and secure vault encryption are not implemented. Permission and Face ID handoffs are explicitly labeled, and no actual library data is accessed or deleted.

## Verification

`verify-tidy.cjs` runs Playwright checks for frame inventory, dimensions, image loading, selection continuity, cancel safety, consistent totals, partial failure/retry, limited permissions, scoped event deletion, compression original safety and Vault separation. `export-tidy.cjs` renders the static deliverables. Both scripts use the installed local Playwright and Brave paths by default; `PLAYWRIGHT_PATH` and `BROWSER_PATH` can override the export runtime.

Browser captures verify this web prototype, not native iOS behavior or a formal accessibility conformance audit.

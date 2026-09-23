---
name: Tidy
description: A reassuring iPhone utility in soft premium digital clay.
colors:
  primary: "#7C3AED"
  light-violet: "#A78BFA"
  background: "#F4F1FA"
  surface: "#F9F7FD"
  primary-text: "#332F3A"
  secondary-text: "#635F69"
  pink: "#DB2777"
  sky: "#0EA5E9"
  emerald: "#10B981"
  amber: "#F59E0B"
  destructive: "#C52B3A"
typography:
  display:
    fontFamily: "Nunito, ui-rounded, system-ui, sans-serif"
    fontSize: "48px"
    fontWeight: 800
    lineHeight: 1.12
    letterSpacing: "-0.025em"
  headline:
    fontFamily: "Nunito, ui-rounded, system-ui, sans-serif"
    fontSize: "32px"
    fontWeight: 800
    lineHeight: 1.12
  title:
    fontFamily: "Nunito, ui-rounded, system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 800
    lineHeight: 1.25
  body:
    fontFamily: "DM Sans, -apple-system, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: "DM Sans, -apple-system, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: 1.45
rounded:
  hero: "40px"
  card: "30px"
  nested: "22px"
  button: "20px"
  thumbnail: "16px"
spacing:
  xs: "6px"
  sm: "12px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.button}"
    padding: "14px 18px"
    height: "54px"
  button-destructive:
    backgroundColor: "{colors.destructive}"
    textColor: "#FFFFFF"
    rounded: "{rounded.button}"
    height: "54px"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary-text}"
    rounded: "{rounded.card}"
    padding: "20px"
---

# Design System: Tidy

## Overview

**Creative North Star: "Soft, premium digital clay"**

Tidy is tactile, dimensional and reassuring. Its material is matte silicone: broad soft highlights, tinted reflections and gently pressed controls. Nunito brings warmth to titles and numbers while DM Sans keeps file details readable.

The product stays a storage utility first. Photo content, explicit selection states and visible review totals carry the experience. The visual identity follows the user's pinned palette and typography.

**Key Characteristics:**

- Soft dimensional surfaces.
- Clear file comparison and selection.
- Familiar iOS navigation and explicit confirmation.
- Restrained category color within a lavender ground.

## Colors

Violet carries ordinary actions. Pink, sky, emerald and amber distinguish content categories; dark text remains the primary information layer.

### Primary

Primary violet and light violet form the button gradient and storage ring. The light end sits toward the highlight, while the stronger violet carries the button label area.

### Secondary

Pink identifies videos, sky identifies screenshots, emerald supports contacts and successful outcomes, and amber supports uncertain/blurry content and recoverable warnings. Category surfaces use pale tints, not saturated fields behind body text.

### Neutral

Lavender background, raised near-lavender surfaces, primary ink and secondary ink are defined in the frontmatter. The media viewer uses a dark photographic surround.

**The Destructive Role Rule.** Red is reserved for actions that remove or combine explicitly reviewed records. Standard review and navigation stay violet.

## Typography

**Display Font:** Nunito with rounded system fallback.

**Body Font:** DM Sans with Apple/system fallback.

### Hierarchy

- Display statistics use the largest Nunito treatment.
- Screen titles use the headline role; onboarding titles rise to 36px.
- Cards use the title role, with compact variants where content density requires them.
- DM Sans carries body, metadata, helper text and buttons.
- Tabular numerals support changing storage values.

The prototype scales its core text through `--text-scale` and scrolls content within the fixed screen. Native implementation must connect these roles to Dynamic Type rather than merely copying CSS sizes.

## Layout

Raw screens are exactly 393 × 852. The top status/safe region occupies 59px; the 5px home indicator sits 8px above the bottom edge. Content uses 24px side padding. Bottom tabs occupy 85px and remain separate from scrollable content. Sticky review actions remain visible during selection.

The design board arranges frames horizontally within eight flow groups; board zoom never changes the source frame geometry. The active prototype centers a single raw frame. Longer lists scroll internally, including at increased text sizes.

## Elevation & Depth

Raised surfaces use an offset ambient shadow, an opposing top-left highlight, a subtle inner colored reflection and an inner rim. Pressed surfaces reverse the emphasis. There is no surrounding device body or frame shadow.

### Shadow Vocabulary

- Raised clay: `8px 12px 24px #b7a8cf30, -5px -5px 15px #ffffffcf, inset -2px -3px 5px #d7cbea55, inset 2px 2px 3px #fff`.
- Pressed clay: `inset 3px 4px 8px #c8b9dc60, inset -3px -3px 8px #fff`.

Buttons compress to 96.5% on activation over 200ms using `cubic-bezier(.22,1,.36,1)`. Reduced Motion removes authored transitions and animation.

## Shapes

Hero, card, nested and button radii follow the frontmatter scale. Category orbs have soft, slightly rotated square silhouettes. Pills and circular selection marks carry small state indicators. Photo thumbnails use modest rounding so their content stays prominent.

## Components

| Requested component | Implemented primitive |
| --- | --- |
| ClayCard | Shared raised card surface |
| ClayButton | `btn` / `go`, primary, secondary, quiet and destructive variants |
| ClayIconOrb | `orb`, category colors and large illustration sizes |
| StorageRing | `ring`, data-driven arc with textual values |
| StorageCategoryCard | Home category card family |
| PhotoGroupCard | `groupCard`, group metadata and keeper recommendation |
| PhotoThumbnail | `thumb`, local image, selection state and preview affordance |
| SelectionControl | Checked thumbnail and standalone pressed-state control |
| VideoCard | Video row, preview, metadata and selection |
| ContactDuplicateCard | Contact group, evidence, review and ignore actions |
| PermissionCard | `permission`, explanation and continuation actions |
| PermissionStatusRow | Permissions management row |
| ReviewRow | Consolidated category count, size and edit link |
| BottomActionBar | `selectionBar`, selected count and review action |
| EmptyState | `empty`, category-specific illustration and return action |
| ErrorState | `errorScreen`, explanation and recovery actions |
| ProgressCard | Compact Home scan and expanded scan state |
| SuccessOrb | Emerald `orb` used by result screens |
| Badge | `badge`, recommendation and privacy/status variants |
| FilterChip | Recessed filter strip with raised active option |

Buttons have keyboard focus outlines and a pressed response. Selections combine checkmarks, tint and `aria-pressed`; color alone is never the state. Preview controls are distinct from selection controls. Permission explanations and native-service handoffs remain visibly distinguishable.

**The Separate States Rule.** Discovered content is not selected content. Selection does not authorize deletion. Approval creates the processing queue.

## Do's and Don'ts

### Do:

- **Do** show literal storage numbers next to charts.
- **Do** keep selections intact through previews, category edits and canceled confirmations.
- **Do** make uncertain findings advisory and keepers changeable.
- **Do** use the native platform APIs in the production application.

### Don't:

- **Don't** surround screens with device mockups or presentation cards.
- **Don't** use color alone to indicate selection.
- **Don't** turn discovery into automatic selection or deletion.
- **Don't** present browser simulations as real authentication, permissions or storage operations.

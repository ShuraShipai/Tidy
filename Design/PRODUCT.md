# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Stack

HTML, CSS, and JavaScript in `tidy_design.html` for a high-fidelity interactive web prototype; native storage access is out of scope for the prototype.

## Users

Primary users are iPhone users on iOS 17+ who are running low on storage or have cluttered photo, video, and contact libraries. They need to quickly understand what is taking up space, find unnecessary content, review it safely, and free storage without manually searching through thousands of files.

## Product Purpose

Tidy is a privacy-first, on-device iPhone storage cleaner. It helps users discover, review, and remove unnecessary photos, videos, and contacts in a guided workflow. Success means users can understand what is consuming storage and confidently reclaim space without accidental deletion.

## Positioning

Tidy's distinctive mechanism is safe, guided visual cleanup performed entirely on-device. It makes storage cleaning understandable and reassuring rather than aggressive or technical. Nothing is deleted automatically: discovered, selected, and deleted are separate states, and destructive actions always require explicit user approval.

## Operating Context

The core workflow is: SCAN → FIND → REVIEW → SELECT → FINAL REVIEW → CONFIRM → CLEAN → RESULT. The prototype represents the complete iOS application as interactive 393 × 852 screens, with each frame being the application screen itself rather than a phone mockup or device shell.

## Capabilities and Constraints

Tidy helps users find and review duplicate and similar photos, screenshots, large videos, and duplicate contacts. The complete design brief also confirms optional tools: possibly blurry-photo review, swipe-based photo review, video compression, Private Vault, calendar cleanup, Home Screen widgets, and local cleanup history. These remain secondary entry points, not additional navigation tabs.

There is no login, signup, account, cloud sync, subscription, premium plan, paywall, free trial, email cleaner, RAM cleaner, system junk cleaner, or other-app cache cleaner. All functionality is free and unlocked. The design prototype does not perform actual native storage access.

Prototype constraints: target iPhone 16 frames at exactly 393 × 852; the application UI fills each frame directly; multiple frames may later be arranged side-by-side on a large design board. Follow iOS conventions including safe areas, status bar/Dynamic Island region, native-feeling navigation, swipe-back behavior, bottom sheets, confirmation patterns, and minimum 44pt touch targets.

## Brand Commitments

The visual identity is high-fidelity premium claymorphism combined with Apple-like usability. It should feel tactile, dimensional, soft, modern, mature, polished, and like a real iOS utility—not childish, cartoonish, overly colorful, or like a website squeezed into a phone.

## Evidence on Hand

The complete screen-by-screen specification was supplied during the craft phase. `tidy_design.html` implements its visual flows with synthetic data and local sample photographs; sources are recorded in `assets/SOURCES.md`. There is no production storage data or real device access. Sample figures are reconciled from one fixture so review, confirmation, result and updated Home agree. Native permissions and authentication are represented by explicitly labeled handoffs.

## Product Principles

- Make storage understandable at a glance.
- Guide users through safe, explicit cleanup decisions.
- Keep discovery, selection, and deletion visibly separate.
- Preserve privacy through on-device operation and no account requirement.
- Deliver a premium, tactile utility experience grounded in iOS conventions.

## Accessibility & Inclusion

Support Dynamic Type, VoiceOver-friendly states, Reduce Motion, Increase Contrast, and WCAG AA contrast where practical. Interactive controls must meet a minimum 44pt touch target.

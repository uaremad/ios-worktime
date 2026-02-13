# Vorkeime App (iOS + macOS)

[![iOS](https://img.shields.io/badge/iOS-26%2B-blue.svg)]() [![macOS](https://img.shields.io/badge/macOS-26%2B-blue.svg)]() [![Swift](https://img.shields.io/badge/Swift-6-orange.svg)]() [![SwiftUI](https://img.shields.io/badge/SwiftUI-latest-brightgreen.svg)]()

The app provides time tracking and lightweight billing for freelancers and employees (including temporary work) across EU and US use cases: users record work time with activities, tags, cost centres, and orders, apply flexible rate rules (hourly, fixed, or no-charge), and then generate monthly invoices or internal reports with itemized lines that can be aggregated from tracked time or added manually from reusable templates (e.g., flat expenses). It supports multiple profiles (e.g., different workers), configurable terminology (client/mandate/customer), issuer identities (company or individual), approval and locking workflows, and snapshotting of billing data to keep historical invoices consistent even if rates change later.

## Overview

- Platforms: iOS, iPadOS, macOS
- Language: Swift 6
- UI: SwiftUI-first
- Project generation: Tuist
- Build tooling: Makefile
- Localization: multi-language via `xcstrings` + SwiftGen

## Repository Structure

- `App/` main app target, sources, resources, entitlements
- `Modules/` shared internal frameworks (`CoreDataKit`, `PDFGenerator`)
- `Tuist/` project description helpers and generation setup
- `Docs/` App Store metadata and product documentation
- `Scripts/` utility scripts used during development and CI

## Prerequisites

- Xcode (current stable)
- Homebrew
- Tuist (pinned via `.tuist-version`)
- SwiftFormat, SwiftLint, xcbeautify (installed via `make setup`)

## Quick Start

```bash
make setup
make open
```

## Common Commands

```bash
make help          # show all available commands
make run           # build + run iOS
make run-mac       # build + run macOS
make build-ios     # build iOS only
make build-mac     # build macOS only
make test-ios      # run iOS test plan
make lint          # strict lint checks
make format        # auto-format code
make swiftgen      # regenerate assets/localization enums
```

## Versioning

The project reads version values from repository files:

- `.app-version` -> `MARKETING_VERSION`
- `.app-buildnumber` -> `CURRENT_PROJECT_VERSION`

These values are injected through Tuist settings and used by `Info.plist` via:

- `CFBundleShortVersionString = $(MARKETING_VERSION)`
- `CFBundleVersion = $(CURRENT_PROJECT_VERSION)`

After changing version files, regenerate the project:

```bash
tuist generate
```

## Localization

- Source of truth: `App/Resources/*.xcstrings`
- Generated accessors: `App/Sources/Generated/L10n.swift`
- Regeneration command: `make swiftgen`

## Release Notes / App Store Texts

App Store metadata files are maintained in:

- `Docs/AppStore/iOS/`
- `Docs/AppStore/Mac/`

## Notes

- Use Makefile commands instead of manual `xcodebuild` invocations.
- Prefer Tuist regeneration (`tuist generate`) after project setting changes.
- Keep Swift and localization generation outputs in sync before archiving.

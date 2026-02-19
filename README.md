# TripFit

Travel packing organizer for iOS. Manage your wardrobe, create outfits, and pack smart for trips.

- **UIKit + SnapKit** — Programmatic UI with Auto Layout
- **SwiftData** — Offline-first persistence
- **Tuist** — Project generation and dependency management
- **SwiftLint** — Code quality enforcement

## Requirements

- Xcode 15.0+
- iOS 17.0+
- Tuist 4.x
- Swift 5.9+

## Getting Started

### Generate Project

```bash
tuist install
tuist generate
open TripFit.xcworkspace
```

### CLI Build (No Code Signing)

```bash
xcodebuild -workspace TripFit.xcworkspace \
  -scheme TripFit \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/TripFitDerived \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

### Lint

```bash
swiftlint lint --config .swiftlint.yml
```

## Architecture

```
TripFit/
├─ App/           # AppDelegate, SceneDelegate, DI, Seed, Root
├─ Core/          # DesignSystem, BaseUI, Utilities
├─ Domain/        # SwiftData models, Enums
├─ Features/
│  ├─ Wardrobe/   # Clothing CRUD (grid, search, filter, photo)
│  ├─ Outfits/    # Outfit CRUD (multi-select items)
│  ├─ Trips/      # Trip CRUD, Packing checklist, Essentials
│  └─ Onboarding/ # 3-page walkthrough
├─ Resources/     # Assets, CountryEssentials.json
└─ Scripts/       # SwiftLint build phase
```

## Features

- **Wardrobe**: Add/edit/delete clothing with photos, categories, seasons. Grid view with search and filter chips.
- **Outfits**: Create outfit combinations by selecting multiple wardrobe items.
- **Trips**: Plan trips with date ranges and destinations. Packing checklist with progress tracking.
- **Destination Essentials**: View voltage/frequency/plug info for 30+ countries. One-tap add recommended items.
- **Onboarding**: 3-page walkthrough on first launch.
- **Seed Data**: Sample clothing, outfit, and trip on first run.

## Design System

Bright pastel theme with pink (#FF5FA2), sky (#5AC8FF), lavender (#B18CFF), and mint (#34D399) accent colors. Rounded cards, gradient buttons, filter chips.

## Author

bbdyno

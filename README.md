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
- **Localization**: Korean, English, Japanese, Simplified Chinese, and Traditional Chinese.
- **Developer Support**: Optional coffee- and chicken-level consumable tips through StoreKit 2.
- **Seed Data**: Sample clothing, outfit, and trip on first run.

## Design System

Bright pastel theme with pink (#FF5FA2), sky (#5AC8FF), lavender (#B18CFF), and mint (#34D399) accent colors. Rounded cards, gradient buttons, filter chips.

## Author

bbdyno

---

## 💜 Support Me

TripFit users can also open **More → Support the Developer** in the iOS app. The optional App Store tips do not unlock features and can be purchased again.

<div align="left">
  <a href="https://buymeacoffee.com/bbdyno" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="45" width="174" />
  </a>
</div>

<br>

<details>
<summary>
  <b>🪙 Crypto Donation (BTC / ETH)</b><br>
  <span style="font-size: 0.8em; color: gray;">Click to see QR Codes & Addresses</span>
</summary>

<br>

<table>
  <tr>
    <td align="center" width="200">
      <img src="https://img.shields.io/badge/Bitcoin-FF9900?style=for-the-badge&logo=bitcoin&logoColor=white" height="30"/>
      <br><br>
      <img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=bc1qz5neag5j4cg6j8sj53889udws70v7223zlvgd3" width="120" alt="BTC QR">
      <br><br>
      <a href="bitcoin:bc1qz5neag5j4cg6j8sj53889udws70v7223zlvgd3"><b>Send BTC ↗</b></a>
    </td>
    <td align="center" width="200">
      <img src="https://img.shields.io/badge/Ethereum-3C3C3D?style=for-the-badge&logo=ethereum&logoColor=white" height="30"/>
      <br><br>
      <img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=0x5f35523757d0e672fa3ffbc0f1d50d35fd6b2571" width="120" alt="ETH QR">
      <br><br>
      <a href="ethereum:0x5f35523757d0e672fa3ffbc0f1d50d35fd6b2571"><b>Send ETH ↗</b></a>
    </td>
  </tr>
</table>

<blockquote>
<p><b>BTC:</b> <code>bc1qz5neag5j4cg6j8sj53889udws70v7223zlvgd3</code></p>
<p><b>ETH:</b> <code>0x5f35523757d0e672fa3ffbc0f1d50d35fd6b2571</code></p>
</blockquote>

</details>

<br>

> **Thanks for your support!** 🎁
>
> 🇰🇷 커피 한 잔의 후원은 저에게 큰 힘이 됩니다. 감사합니다! <br>
> 🇺🇸 Thanks for the coffee! Your support keeps me going. <br>
> 🇸🇦 شكراً على القهوة! دعمك يعني لي الكثير. <br>
> 🇩🇪 Danke für den Kaffee! Deine Unterstützung motiviert mich. <br>
> 🇫🇷 Merci pour le café ! Votre soutien me motive. <br>
> 🇪🇸 ¡Gracias por el café! Tu apoyo me motiva a seguir. <br>
> 🇯🇵 コーヒーの差し入れ、ありがとうございます！励みになります。 <br>
> 🇨🇳 感谢请我喝杯咖啡！您的支持是我最大的动力。 <br>
> 🇮🇩 Terima kasih traktiran kopinya! Dukunganmu sangat berarti.

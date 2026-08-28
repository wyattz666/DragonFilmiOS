#             DragonFilm iOS

<p align="center">
  <img src="DragonFilm/Resources/Assets.xcassets/Logo.imageset/logo.png" alt="DragonFilm Logo" width="120" />
</p>

<p align="center">
  <strong>A modern, high-performance cinema streaming application for iOS (iPhone & iPad).</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017.0+-000000.svg?style=flat&logo=apple" alt="Platform" />
  <img src="https://img.shields.io/badge/Language-Swift%205.9+-FA7343.svg?style=flat&logo=swift" alt="Language" />
  <img src="https://img.shields.io/badge/UI%20Framework-SwiftUI-0071e3.svg?style=flat" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Release-v1.0.0-F5C518.svg?style=flat" alt="Release" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat" alt="License" />
</p>

---

## ✨ Features

- 🚀 **Seamless Video Streaming**: Custom-built video player supporting both Native HLS (`.m3u8`) streaming and Embed players with automatic episode progress tracking and instant resume playback.
- ☁️ **Real-Time Cloud Sync**: Seamless two-way synchronization of watch history, favorite movies, and watch-later lists between the Web and iOS app.
- 🔐 **Flexible Authentication**: Secure user authentication supporting both native DragonFilm accounts and **Sign in with Google (Google OAuth)**.
- 🎨 **Cinema Obsidian & Gold UI**: Premium dark cinema aesthetic featuring deep OLED obsidian black backgrounds, radiant golden accents, and frosted glassmorphism overlays.
- 📊 **Live Rankings & Trends**: Real-time trending rankings curated from Netflix VN, TMDB (Korean & Chinese TV Series), and AniList (Trending Anime).
- 📅 **Release Schedule**: Daily interactive broadcast schedule tracking new episode releases.
- 🔍 **Instant Search & Discovery**: Fast, debounced search across thousands of movies, series, anime, and cast members.

---

## 📱 Sideloading & Installation

You can install DragonFilm on any iPhone or iPad running **iOS 17.0+** using the prebuilt `.ipa` binary:

### 1. Direct Install via TrollStore (No Re-signing Required)
1. Download `DragonFilm.ipa` from the [Latest Release](https://github.com/wyattz666/DragonFilmiOS/releases/latest).
2. Open the `.ipa` file using **TrollStore** to install permanently without certificate expiration.

### 2. Sideloading via AltStore / Sideloadly / Scarlet / SideStore
1. Download `DragonFilm.ipa` from [GitHub Releases](https://github.com/wyattz666/DragonFilmiOS/releases/latest).
2. Drag and drop `DragonFilm.ipa` into **AltStore**, **Sideloadly**, or your preferred sideloading tool.
3. Sign in with your Apple ID to install onto your device.

---

## 🛠 Prerequisites & Building from Source

### Requirements
- **macOS Sonoma** or later
- **Xcode 15.0+** or **Xcode 16.0+**
- **XcodeGen** (optional, for project file generation): `brew install xcodegen`
- iOS 17.0+ deployment target

### Build & Run
1. Clone the repository:
   ```bash
   git clone https://github.com/wyattz666/DragonFilmiOS.git
   cd DragonFilmiOS
   ```

2. Open the project in Xcode:
   ```bash
   open DragonFilm.xcodeproj
   ```

3. Select your target device / simulator and hit **Cmd + R** to run.

### Export IPA Package
To compile and package a signed/unsigned `.ipa` package directly from the command line:
```bash
chmod +x export_ipa.sh
./export_ipa.sh
```
The output file will be saved at `./DragonFilm.ipa`.

---

## 🏗 Project Architecture

```text
DragonFilm/
├── App/                # App entrypoint, AppState environment & Tab routing
├── Design/             # Theme tokens (DFColor, DFFont), Glassmorphism & Reusable Components
├── Features/
│   ├── Home/           # Hero carousel, Home catalog rows & Ranking panels
│   ├── Detail/         # Movie details, episode selector & version picker
│   ├── Player/         # AVPlayer controller, Embed player & playback observer
│   ├── Search/         # Instant debounced search & recent search history
│   ├── Schedule/       # Daily calendar release schedule
│   ├── Library/        # Watch history, Bookmarks & Watch-later manager
│   └── Profile/        # User profile, Google OAuth & Account settings
├── Models/             # Movie, Episode, Server, Ranking & User data models
├── Networking/         # API client, Stream resolvers, Source normalizers & AniList GraphQL
├── Storage/            # LocalStore (UserDefaults persistence), CloudSync & AuthManager
└── Resources/          # Assets catalog (AppIcon, Logos) & Info.plist
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

<p align="center">
  Crafted with ❤️ for cinema lovers by the <strong>DragonFilm Team</strong>.
</p>

# DockLock 🔒

<p align="center">
  <img src="Assets/AppIcon.png" alt="DockLock Logo" width="128">
</p>

[![Swift Version](https://img.shields.io/badge/Swift-6.0-F05138.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platforms-macOS_14+-lightgrey.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

**DockLock** is a lightweight macOS utility designed to solve a long-standing frustration for multi-monitor users: the "jumping Dock." It allows you to pin the macOS Dock to a specific display and prevents it from moving to other screens, even when performing bottom-edge gestures.

**v1.3.3 Signature Edition** features a refined visual theme and professional identity.

---

## 📋 Table of Contents
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Usage](#-usage)
- [Technical Architecture](#-technical-architecture)
- [Contributing](#-contributing)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)

---

## 📥 Download

You can download the latest pre-built version of **DockLock** from the [Releases](https://github.com/danielvm-git/docklock/releases) page.

1.  Download the `DockLock Installer (macOS)` (`.dmg` file).
2.  Open the file and drag `DockLock` to your `/Applications` folder.
3.  Launch the app and follow the [Permissions](#2-permissions-crucial) guide below.

---

## 🚀 Features

- **Persistent Dock Pinning:** Choose which monitor should hold the Dock and keep it there.
- **Gesture Blocking:** Actively prevents the mouse from triggering the Dock relocation gesture on non-primary displays.
- **Native SwiftUI Dashboard:** Simple interface to manage your monitor setup and engine status.
- **Menu Bar Integration:** Runs as a resident utility in the system tray.
- **Launch at Login:** Option to start automatically when you log into your Mac.
- **Automated Releases:** Continuous delivery via `semantic-release` and GitHub Actions.

---

## 📸 Screenshots

<p align="center">
  <img src="Assets/dashboard.png" alt="DockLock Dashboard" width="60%">
</p>

---

## ⚙️ Prerequisites

Before you begin, ensure you have met the following requirements:
*   You have a macOS machine running **macOS 14 (Sonoma) or newer**.
*   You have installed **Xcode 15+** or the latest Swift command-line tools.

---

## 🛠 Installation

### 1. Build from Source
Clone the repository and run the setup script to build and package the `.app` bundle:

```bash
git clone https://github.com/danielvm-git/docklock.git
cd docklock
./run.sh
```

### 2. Permissions (Crucial)
MacOS requires **Accessibility Permissions** to allow DockLock to monitor mouse movements for the "anti-jumping" logic.

1.  A new folder named `DockLock.app` will be created in your directory.
2.  Open **System Settings > Privacy & Security > Accessibility**.
3.  Drag the `DockLock.app` bundle from your project folder into the settings list.
4.  Toggle the switch to **ON**.

---

## 💡 Usage

1.  Run `./run.sh` (or launch the `DockLock.app` directly from Finder).
2.  Click the lock icon in your **Menu Bar** and select **Dashboard**.
3.  Choose which display you want to pin the Dock to.
4.  Click **Start Engine**. The app will now intercept bottom-edge mouse gestures on your other monitors.

---

## 🛠 Troubleshooting

### "DockLock" cannot be opened because it is from an unidentified developer
Because this is an open-source project and the pre-built binaries are ad-hoc signed, macOS blocks the first launch.

#### 🛡️ The 3-Step Security Bypass
1.  **Open the DMG:** Right-click (or Control-click) the `.dmg` file and select **Open**. This mounts the unsigned disk image.
2.  **Move to Applications:** Drag `DockLock` from the DMG to your **Applications** folder. **Do not run it directly from the DMG.**
3.  **Right-Click Open the App:** In the Applications folder, **Right-click** (or Control-click) the **DockLock** icon and select **Open**. Click **Open** again.

You will only need to do this once.

#### 💻 Power User Fix (Terminal)
If the right-click method fails, you can manually remove the "quarantine" flag that macOS attaches to downloaded files:
```bash
xattr -d com.apple.quarantine /Applications/DockLock.app
```

Alternatively, you can run the included helper script from the source:
```bash
./scripts/fix-quarantine.sh
```


---

DockLock is built with **Swift 6** and **SwiftUI**, utilizing low-level macOS APIs for its core functionality:

- **Core Graphics (`CGEventTap`):** Intercepts and modifies mouse movement events at the system level.
- **Accessibility API (`AXUIElement`):** Required for the event tap to function as a trusted process.
- **ServiceManagement (`SMAppService`):** Handles the modern macOS "Launch at Login" registration.
- **CoreGraphics (`CGDirectDisplayID`):** Manages multi-monitor identification and coordinate mapping.

### Testing
Run the automated test suite to verify coordinate logic and manager interfaces:
```bash
swift test
```

---

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: Add some AmazingFeature'`) - *Note: This project uses Conventional Commits.*
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 🌟 Acknowledgments

*   Concept inspired by the excellent [DockLock Pro](https://docklockpro.com/).
*   Developed using the [bigpowers](https://github.com/danielvm-git/bigpowers) AI orchestration methodology.

# DockLock 🔒

**DockLock** is a lightweight macOS utility designed to solve a long-standing frustration for multi-monitor users: the "jumping Dock." It allows you to pin the macOS Dock to a specific display and prevents it from moving to other screens, even when performing bottom-edge gestures.

Inspired by [DockLock Pro](https://docklockpro.com/).

## 🚀 Features

- **Persistent Dock Pinning:** Choose which monitor should hold the Dock and keep it there.
- **Gesture Blocking:** Actively prevents the mouse from triggering the Dock relocation gesture on non-primary displays.
- **Native SwiftUI Dashboard:** Simple interface to manage your monitor setup and monitor engine status.
- **Menu Bar Integration:** Runs as a resident utility in the system tray.
- **Launch at Login:** Option to start automatically when you log into your Mac.
- **Automated Releases:** Continuous delivery via `semantic-release` and GitHub Actions.

## 🛠 Installation & Usage

### 1. Build from Source
Ensure you have the latest Swift toolchain installed (Xcode 15+).

```bash
git clone https://github.com/[your-username]/docklock.git
cd docklock
./run.sh
```

### 2. Permissions (Crucial)
MacOS requires **Accessibility Permissions** to allow DockLock to monitor mouse movements for the "anti-jumping" logic.

1. Launch the app using `./run.sh`.
2. Open **System Settings > Privacy & Security > Accessibility**.
3. Drag the `DockLock.app` bundle from your project folder into the list.
4. Toggle the switch to **ON**.

## 🏗 Technical Architecture

DockLock is built with **Swift 6** and **SwiftUI**, utilizing low-level macOS APIs for its core functionality:

- **Core Graphics (`CGEventTap`):** Intercepts and modifies mouse movement events at the system level.
- **Accessibility API (`AXUIElement`):** Required for the event tap to function as a trusted process.
- **ServiceManagement (`SMAppService`):** Handles the modern macOS "Launch at Login" registration.
- **CoreGraphics (`CGDirectDisplayID`):** Manages multi-monitor identification and coordinate mapping.

### Project Methodology
This project follows the **bigpowers** methodology, ensuring high-integrity development through:
- **TDD (Test-Driven Development):** Core logic is verified via `swift test`.
- **Conventional Commits:** Automated versioning and changelog generation.
- **Bundle Packaging:** Uses a proper `.app` structure to maintain stable security permissions.

## 🧪 Testing

Run the automated test suite to verify coordinate logic and manager interfaces:

```bash
swift test
```

## 📜 License

This project is released under the MIT License.

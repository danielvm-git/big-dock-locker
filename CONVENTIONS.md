# Conventions

All agents and contributors must follow these rules.

## Bigpowers Methodology
- This project follows the bigpowers lifecycle: Discover -> Elaborate -> Plan -> Build -> Verify -> Release.
- Use the appropriate skills for each phase.

## Technical Standards
- **Language:** Swift
- **Framework:** SwiftUI
- **Architecture:** MVVM
- **Error Handling:** Use Swift `Result` or `throws` for explicit error propagation.

## Defensive Coding
- **Timeout:** All API and system calls should have appropriate timeouts.
- **Graceful Degradation:** If Accessibility permissions are missing, the app should remain functional (in a restricted mode) and guide the user to enable permissions.

## Project Structure
- `Sources/`: Application source code.
- `Tests/`: Unit and integration tests.
- `specs/`: Bigpowers specifications and plans.
- `Assets/`: Visual assets and icons.

## Documentation
- Document all public APIs using Swift DocC comments.
- Maintain `specs/` with up-to-date plans.

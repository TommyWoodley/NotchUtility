# NotchUtility

[![CI](https://github.com/TommyWoodley/NotchUtility/actions/workflows/ci.yml/badge.svg)](https://github.com/TommyWoodley/NotchUtility/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/TommyWoodley/NotchUtility/badge.svg)](https://coveralls.io/github/TommyWoodley/NotchUtility)

A SwiftUI application that transforms your MacBook's notch into a productive workspace featuring temporary file storage and clipboard management.

## 🎯 Project Vision

NotchUtility transforms the MacBook notch from a simple design element into a functional productivity space. The app provides a seamless overlay interface that appears when you interact with the notch area, offering quick access to temporary file storage and clipboard management.

## ✨ Current Status

**Phase 1 - Foundation & File Storage** (✅ **COMPLETE**)
- Sophisticated notch overlay system ✅
- Temporary file storage with drag & drop ✅
- Clipboard history management ✅
- Multi-display support ✅
- Event monitoring and state management ✅

## 🚀 Current Features

- **📁 DropZone**: Drag & drop files with automatic cleanup and organization
  - **🔄 File Conversion**: Convert between multiple formats with preview support
- **📋 Clipboard Management**: History tracking with one-click copy and type detection  
- **Developer Tools**: A series of quick access tools designed for developers
  - Base64 Encoding/Decoding

## 🛠 Technical Requirements

### System Requirements
- macOS 15.5 or later
- MacBook with notch (Pro/Air M1/M2/M3/M4) or any Mac for testing
- Xcode 16.2 or later for development

### Development Stack
- **Framework**: SwiftUI with AppKit integration
- **Language**: Swift 5.9+
- **Architecture**: MVVM with Combine for reactive programming
- **Event System**: Global event monitoring with NSEvent
- **Storage**: FileManager with UserDefaults for preferences
- **UI**: Native macOS design with custom notch positioning

## 🏃‍♂️ Getting Started

### Prerequisites
1. Xcode 16.2 or later
2. macOS 15.5 or later
3. MacBook with notch (recommended) or any Mac for development

### Installation
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd NotchUtility
   ```

2. Open the project in Xcode:
   ```bash
   open NotchUtility.xcodeproj
   ```

3. Build and run (⌘+R)

### First Run
1. The app will start as a background accessory (no dock icon)
2. Move your mouse to the top of the screen near the notch area
3. Click or hover over the notch to reveal the interface
4. Try dragging files from Finder onto the notch area
5. Access clipboard history through the Clipboard tab


### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and ensure they pass all checks
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Quality Assurance
All pull requests automatically run through our CI/CD pipeline which includes:
- **SwiftLint**: Ensures code style consistency
- **Unit Tests**: Verifies core functionality works correctly  
- **UI Tests**: Validates user interface behavior
- **Multi-architecture**: Tests on both Intel and Apple Silicon (x86_64 and arm64)

The pipeline must pass before merging. You can run these checks locally:

```bash
# Install SwiftLint
brew install swiftlint

# Run linting
swiftlint lint

# Run tests (treating warnings as errors)
xcodebuild test -project NotchUtility.xcodeproj -scheme NotchUtility SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

## 🗺 Roadmap

- **Phase 1**: Temporary File Storage & Clipboard Management (✅ **COMPLETE**)
- **Phase 2**: System Integration & Media Controls (🔄 **PLANNING**)
- **Phase 3**: Productivity Suite (Calendar, Notes, App Launcher)
- **Phase 4**: Customization & Extensions


## 📞 Support

- Create an issue for bug reports
- Start a discussion for feature requests
- Check existing issues before reporting

---

**Made with ❤️ and SwiftUI** 

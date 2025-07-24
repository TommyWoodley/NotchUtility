# NotchUtility

A SwiftUI application that transforms your MacBook's notch into a productive workspace, starting with temporary file storage capabilities and expanding to a full suite of utilities.

## 🎯 Project Vision

NotchUtility aims to make the MacBook notch more than just a design element - turning it into a functional space that enhances productivity. Taking inspiration from apps like Boring Notch, we're building a comprehensive utility that starts with file management and grows into a complete productivity suite.

## ✨ Current Status

**Phase 1 - Foundation & File Storage** (In Development)
- Basic SwiftUI app structure ✅
- Project setup complete ✅
- Ready for file storage implementation

## 🚀 Phase 1 Features (Temporary File Store)

### Core File Storage
- **Drag & Drop Interface**: Drag files directly onto the notch area
- **Temporary Storage**: Files stored temporarily for quick access
- **File Preview**: Quick preview of stored files with thumbnails
- **File Types Support**: 
  - Documents (PDF, TXT, DOCX)
  - Images (PNG, JPG, HEIC)
  - Archives (ZIP, DMG)
  - Code files (Swift, Python, JS, etc.)
- **Storage Management**: 
  - Auto-cleanup after specified time
  - Manual file removal
  - Storage size limits
- **Quick Actions**:
  - Open with default app
  - Reveal in Finder
  - Share via AirDrop
  - Copy to clipboard

### User Interface
- **Minimalist Design**: Clean, unobtrusive interface
- **Smooth Animations**: Fluid transitions and hover effects
- **Notch Integration**: Seamless integration with the notch area
- **Status Indicators**: Visual feedback for storage status

## 🛠 Technical Requirements

### System Requirements
- macOS 14.2 or later
- MacBook with notch (Pro/Air M1/M2/M3)
- Xcode 15.0 or later for development

### Development Stack
- **Framework**: SwiftUI
- **Language**: Swift 5.9+
- **Architecture**: MVVM
- **Storage**: UserDefaults + FileManager
- **UI**: Native macOS design language

## 📁 Project Structure

```
NotchUtility/
├── NotchUtility/
│   ├── App/
│   │   ├── NotchUtilityApp.swift
│   │   └── ContentView.swift
│   ├── Models/
│   │   ├── FileItem.swift
│   │   └── StorageManager.swift
│   ├── Views/
│   │   ├── NotchView.swift
│   │   ├── FileStorageView.swift
│   │   └── Components/
│   ├── Utils/
│   │   ├── FileHandler.swift
│   │   └── Extensions/
│   └── Resources/
│       └── Assets.xcassets/
```

## 🏃‍♂️ Getting Started

### Prerequisites
1. Xcode 15.0 or later
2. macOS 14.2 or later
3. Basic understanding of SwiftUI

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

## 🤝 Contributing

We welcome contributions! Please see our [Development Plan](DEVELOPMENT_PLAN.md) for detailed implementation guidelines.

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🗺 Roadmap

- **Phase 1**: Temporary File Storage (Current)
- **Phase 2**: System Integration & Media Controls
- **Phase 3**: Productivity Suite
- **Phase 4**: Customization & Extensions

See [Development Plan](DEVELOPMENT_PLAN.md) for detailed phase breakdowns.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Inspired by [Boring Notch](https://github.com/TheBoredTeam/boring.notch)
- SwiftUI community for excellent resources
- Apple for the notch design (surprisingly useful!)

## 📞 Support

- Create an issue for bug reports
- Start a discussion for feature requests
- Check existing issues before reporting

---

**Made with ❤️ and SwiftUI** 
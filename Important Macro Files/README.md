# MacroAI

A comprehensive iOS nutrition tracking app with advanced features including barcode scanning, food recognition, and macro tracking.

## Features

### 🏷️ Barcode Scanning
- Real-time barcode detection using Apple's Vision framework
- Integration with Open Food Facts database for nutrition data
- Instant nutrition information lookup from product barcodes

### 📸 Food Recognition
- AI-powered food recognition using computer vision
- Automatic nutrition estimation from food photos
- Support for multiple food items in single image

### 📊 Macro Tracking
- Comprehensive macro tracking (proteins, carbs, fats)
- Customizable macro targets
- Visual progress indicators
- Detailed nutrition breakdown

### 🍽️ Recipe Management
- Create and save custom recipes
- Recipe analysis with nutrition breakdown
- Meal planning capabilities
- Recipe sharing and discovery

### 🎨 Theme System
- Customizable app themes
- Marketplace for premium themes
- Seasonal theme packs (Christmas, Thanksgiving)

### 💰 Premium Features
- In-app purchases for premium features
- Subscription management
- Paywall integration

## Technical Stack

- **Language**: Swift
- **Framework**: SwiftUI
- **Camera**: AVFoundation + Vision Framework
- **AI/ML**: Core ML, Vision Framework
- **Data Persistence**: Core Data
- **Networking**: URLSession, Combine
- **In-App Purchases**: StoreKit 2

## Project Structure

```
MacroAI/
├── MacroAI/
│   ├── Views/
│   │   ├── CameraView.swift
│   │   ├── BarcodeScannerView.swift
│   │   ├── HomeView.swift
│   │   └── ...
│   ├── Services/
│   │   ├── CameraManager.swift
│   │   ├── BarcodeService.swift
│   │   ├── NutritionService.swift
│   │   └── ...
│   ├── Models/
│   │   ├── MacroEntry.swift
│   │   ├── Recipe.swift
│   │   └── ...
│   └── Resources/
│       ├── Diets/
│       └── Themes/
└── MacroAI.xcodeproj/
```

## Setup

1. Clone the repository
2. Open `MacroAI.xcodeproj` in Xcode
3. Configure your development team in project settings
4. Build and run on iOS device or simulator

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## Recent Updates

### Barcode Scanner Feature (Latest)
- ✅ Added dedicated barcode scanning UI
- ✅ Integrated with Open Food Facts API
- ✅ Real-time camera preview with barcode detection
- ✅ Nutrition data lookup and caching
- ✅ Seamless integration with existing camera system

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue on GitHub or contact the development team. 
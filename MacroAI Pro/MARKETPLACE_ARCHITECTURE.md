# Diet Marketplace Architecture

## Overview

We've successfully implemented a comprehensive **Diet Marketplace** system for MacroAI that's ready for both diet packs and future seasonal themes. This modular, data-driven architecture integrates seamlessly with the existing subscription model.

## 🏗️ Architecture Components

### Core Models (`DietPack.swift`)

1. **DietPack Model**
   - Contains diet metadata (name, summary, macro ranges, benefits)
   - Supports multiple pricing models (free, subscription-gated, one-time purchase)
   - Includes seasonal availability for holiday packs
   - Category-based organization (lifestyle, performance, medical, seasonal)

2. **ThemePack Model**
   - Visual themes for seasonal customization
   - Custom colors, icons, animations, and backgrounds
   - Season-specific availability windows
   - Pricing integration with subscription tiers

3. **Pricing Models**
   - Free packs (available to all users)
   - Pro/Elite subscription-gated content
   - One-time purchases with StoreKit integration
   - Seasonal purchases with time-limited availability

### Marketplace Manager (`MarketplaceManager.swift`)

**Centralized management system** that handles:
- Diet pack and theme pack loading from local data
- Purchase state persistence
- Subscription tier checking
- StoreKit purchase processing
- Offline-first caching with fallback

**Key Features:**
- Subscription integration for premium content
- Local storage for purchase states
- Automatic unlocking for subscription holders
- Error handling and validation

### User Interface Components

1. **MarketplaceView.swift** - Main marketplace interface
   - Category-based filtering (Lifestyle, Performance, Medical, Seasonal)
   - Toggle between diet packs and theme packs
   - Search and discovery features
   - Subscription upgrade prompts

2. **DietPackDetailView.swift** - Detailed diet pack information
   - Macro breakdown visualization
   - Benefits and sample meals
   - Purchase/unlock interface
   - Subscription upgrade paths

3. **ThemePackDetailView.swift** - Theme pack preview and purchase
   - Visual theme preview with color swatches
   - Animation previews
   - Live theme application demo
   - Purchase integration

## 📦 Pre-loaded Content

### Diet Packs Available

**Free Packs:**
- **Balanced Nutrition** - General healthy eating
- **Ketogenic** - High-fat, low-carb lifestyle

**Pro Required:**
- **Carnivore** - Animal-based elimination diet
- **Intermittent Fasting** - Time-restricted eating

**Elite Required (Medical):**
- **Diabetic** - Blood sugar management
- **Gastric Sleeve** - Post-surgery nutrition

**Seasonal Examples:**
- **Christmas Feast 2024** - Holiday nutrition planning

### Theme Packs (Examples)

**Seasonal Themes:**
- **Christmas Magic** - Festive red/green colors with snowfall animations
- **Thanksgiving Harvest** - Warm autumn colors with falling leaves

## 🔄 Integration Points

### Settings Integration
- Added marketplace section to SettingsView
- Direct access from main app navigation
- Subscription status integration

### Subscription System
- Automatic unlocking for Pro/Elite subscribers
- Subscription upgrade prompts for gated content
- Purchase state persistence across app launches

### StoreKit Integration
- Ready for App Store Connect product configuration
- Purchase flow with error handling
- Receipt validation and restoration

## 🎯 Future Monetization Ready

### Seasonal Content Pipeline
The architecture supports easy addition of:
- **Holiday Theme Packs** (Christmas, Halloween, Valentine's Day)
- **Seasonal Diet Packs** (Summer Shred, Holiday Survival)
- **Limited-time exclusive content**

### Content Management
- **Data-driven design** - Add new packs via JSON/SwiftData
- **Admin-friendly** - No code changes needed for new content
- **A/B testing ready** - Feature flags and availability windows

### Pricing Flexibility
- One-time purchases ($2.99-$4.99 for themes)
- Seasonal bundles and discounts
- Subscription tier benefits
- Geographic pricing support

## 🚀 Implementation Status

✅ **Complete & Working:**
- Core marketplace architecture
- Diet pack system with full categorization
- Theme pack system with visual previews
- Subscription integration
- Purchase flow (StoreKit ready)
- Settings integration
- Offline-first data management

✅ **Ready for Production:**
- Add StoreKit product IDs to App Store Connect
- Configure seasonal availability windows
- Add actual theme assets (colors, animations)
- Populate with additional diet content

## 🎨 Seasonal Strategy

The system is architected to support your holiday monetization strategy:

1. **Christmas 2025 Pack** - Ready to activate with:
   - Festive UI themes
   - Holiday meal planning
   - Special pricing ($2.99-$4.99)

2. **Future Seasonal Releases:**
   - Valentine's Day (February)
   - Easter/Spring (March-April)
   - Summer themes (June-August)
   - Halloween (October)
   - Thanksgiving (November)

## 📊 Monetization Projections

Based on the implemented architecture:
- **Theme Packs**: $2.99-$4.99 each (high margin, low development cost)
- **Diet Packs**: Subscription driver + $4.99 individual purchases
- **Seasonal Bundles**: Premium pricing during peak seasons
- **Subscription Uplift**: Premium content drives Pro/Elite upgrades

The marketplace is now fully integrated and ready for your holiday launch strategy! 🎄 
# Macro AI Pro - Legal Compliance & Data Flow Update

## 🔄 Updated Data Flow Pipeline

The app now implements a compliant nutrition data pipeline:

1. **Image Analysis**: User takes photo → OpenAI GPT-4o Vision identifies food items
2. **Nutrition Lookup**: Identified food names → Spoonacular API for nutrition data
3. **Temporary Storage**: Nutrition data cached for maximum 1 hour (Spoonacular ToS compliance)
4. **User Display**: Results shown with proper attribution to Spoonacular
5. **Automatic Cleanup**: Background task purges expired data every 30 minutes

## 🗄️ Data Retention Implementation

### Nutrition Cache System
- **New Model**: `NutritionCacheEntry` for temporary Spoonacular data storage
- **Manager**: `NutritionCacheManager` handles caching logic and expiry
- **Automatic Expiry**: 1-hour TTL for all Spoonacular-sourced nutrition data
- **Background Cleanup**: `NutritionCacheCleanupTask` ensures compliance

### User Image Retention
- **Storage Period**: Up to 7 days for user-owned photos
- **Purpose**: Re-analysis and user review capabilities
- **Privacy**: Images not shared beyond OpenAI/Spoonacular during analysis

## ⚖️ Legal Compliance Additions

### Settings → Legal & Data Use Section
New section with complete disclosure:

**Attribution & Data Use Disclosure:**
> "Nutrition data is provided by the Spoonacular API. All recipes, ingredients, and nutritional facts are sourced from Spoonacular's content partners. We credit all original sources where applicable. This app does not permanently store or scrape Spoonacular content. Nutritional data is cached for no more than one hour per Spoonacular's Terms of Use."

**AI Analysis Disclosure:**
> "Image analysis is performed by OpenAI's GPT-4o Vision model to identify food items. Food names are then matched to Spoonacular's nutrition database."

**User Data Policy:**
> "User-submitted images are retained for up to 7 days to support re-analysis and user review. These images are owned by the user and are not shared with third parties outside of OpenAI or Spoonacular during analysis."

**Medical Disclaimer (Restored):**
> "Macro AI Pro is for educational and informational use only. It is not intended to provide medical advice, diagnosis, or treatment. Consult a licensed healthcare provider before making dietary or health decisions. This app does not replace professional medical care."

## 🏷️ Attribution Implementation

### UI Attribution
- **Manual Entry**: "Nutrition data powered by Spoonacular" appears when auto-populated
- **Edit View**: Attribution included in AI detection notices
- **Cache Details**: Available in Settings for transparency

### Technical Attribution
- Proper API source tracking in cache entries
- Console logging includes Spoonacular attribution
- Cache statistics include data source information

## 🔧 Technical Implementation

### New Files Created
- `NutritionCache.swift` - Cache model and manager
- `NutritionCacheCleanupTask.swift` - Background cleanup task
- `BACKGROUND_TASKS_SETUP.md` - Setup documentation
- `SPOONACULAR_COMPLIANCE_UPDATE.md` - This summary

### Modified Files
- `NutritionService.swift` - Added caching layer
- `ManualEntryView.swift` - Added attribution display
- `EditMacroEntryView.swift` - Added attribution display
- `SettingsView.swift` - Added Legal & Data Use section
- `DevSettingsView.swift` - Added manual cleanup button
- `ContentView.swift` - Initialized cache manager
- `MacroAIApp.swift` - Registered background tasks

### Background Task Setup Required
Add to app configuration:
```
BGTaskSchedulerPermittedIdentifiers: ["com.macroai.nutritionCleanup"]
```

## ✅ Compliance Verification

### Spoonacular Terms Compliance
- ✅ No permanent storage of API results
- ✅ 1-hour maximum cache duration
- ✅ Automatic expiry and cleanup
- ✅ Proper attribution in UI
- ✅ No offline scraping or bulk downloading

### User Privacy
- ✅ Clear data retention policies disclosed
- ✅ User image ownership clarified
- ✅ Third-party data sharing disclosed
- ✅ Medical disclaimer included

### Technical Validation
- ✅ Cache expiry logic tested
- ✅ Background cleanup registered
- ✅ Attribution displayed consistently
- ✅ Manual cleanup available in dev tools

## 🧪 Testing Features

### Dev Settings Additions
- **"Clean Nutrition Cache"** - Manual cache cleanup for testing
- **Cache details view** - Shows cache statistics and compliance status
- **Reset scan limits** - Now also resets cache refresh timers

### Verification Commands
```swift
// Check cache status
let stats = await cacheManager.getCacheStats()

// Manual cleanup
let deleted = await NutritionCacheCleanupTask.shared.performImmediateCleanup()

// Verify expiry logic
let isExpired = cacheEntry.isExpired // true if > 1 hour old
```

## 🚀 Deployment Notes

1. **Background Task Permission**: Ensure BGTaskSchedulerPermittedIdentifiers is configured
2. **API Attribution**: All nutrition displays now include Spoonacular attribution
3. **Legal Disclosure**: Users can review data policies in Settings → Legal & Data Use
4. **Cache Monitoring**: Dev tools allow manual cache inspection and cleanup

This update ensures full commercial compliance with both Spoonacular's API terms and user privacy requirements while maintaining app functionality. 
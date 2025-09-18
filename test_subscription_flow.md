# MacroAI Pro Subscription Testing Guide

## Issues Fixed
1. **Product ID Mismatch**: Updated product IDs to match App Store Connect format:
   - `comFolkTechAI.MacroAI-Pro.pro.yearly`
   - `comFolkTechAI.MacroAI-Pro.pro.monthly`
   - `comFolkTechAI.MacroAI-Pro.elite.yearly`
   - `comFolkTechAI.MacroAI-Pro.elite.monthly`
   - `comFolkTechAI.MacroAI-Pro.credits.10`

2. **Added Comprehensive Testing Tools**:
   - `SubscriptionTestView.swift` - Interactive test interface
   - `SubscriptionDiagnosticView.swift` - Diagnostic tool for Apple reviewers
   - Added test options to Settings > DEBUG section

## How to Test Subscriptions

### 1. Access Test Tools
1. Open the app in DEBUG mode
2. Go to Settings
3. Scroll to the bottom to find the DEBUG section
4. Tap "Test Subscriptions" or "Subscription Diagnostics"

### 2. Run Diagnostics
1. Open "Subscription Diagnostics"
2. Tap "Run Full Diagnostic"
3. Review results for any RED errors
4. Check "Logs" for detailed information

### 3. Test Purchase Flow
1. Open "Test Subscriptions"
2. Verify all 5 products are loaded
3. Test purchase for each product
4. Test restore purchases functionality

### 4. Common Issues to Check

#### Product Loading Issues
- ❌ **No products loaded**: Check App Store Connect configuration
- ❌ **Missing products**: Verify product IDs match exactly
- ❌ **Wrong environment**: Ensure sandbox testing account is signed in

#### Purchase Flow Issues
- ❌ **Purchase fails immediately**: Check sandbox account setup
- ❌ **Wrong prices displayed**: Check regional pricing in App Store Connect
- ❌ **Restore doesn't work**: Verify transaction verification logic

#### Environment Issues
- ❌ **Production vs Sandbox**: Ensure correct environment for testing
- ❌ **TestFlight detection**: Verify TestFlight users get unlimited access

## Testing Checklist for Apple Review

- [ ] All 5 products load successfully
- [ ] Purchase flow works for Pro yearly/monthly
- [ ] Purchase flow works for Elite yearly/monthly  
- [ ] Credit pack purchase works
- [ ] Restore purchases works correctly
- [ ] Trial activation works
- [ ] Feature access respects subscription tiers
- [ ] TestFlight users get unlimited access
- [ ] Error handling works for failed purchases
- [ ] Subscription status updates correctly after purchase

## Quick Fixes if Tests Fail

1. **No Products Loading**:
   ```swift
   // Check these product IDs in App Store Connect:
   "comFolkTechAI.MacroAI-Pro.pro.yearly"
   "comFolkTechAI.MacroAI-Pro.pro.monthly"
   "comFolkTechAI.MacroAI-Pro.elite.yearly"
   "comFolkTechAI.MacroAI-Pro.elite.monthly"
   "comFolkTechAI.MacroAI-Pro.credits.10"
   ```

2. **Sandbox Testing**:
   - Sign out of App Store
   - Sign in with sandbox test account
   - Clear app and reinstall if needed

3. **Product Status in App Store Connect**:
   - Ensure products are "Ready for Sale"
   - Check pricing for all regions
   - Verify subscription groups are configured

## For Apple Reviewers

If you're an Apple reviewer testing this app:

1. Use the "Subscription Diagnostics" tool in Settings > DEBUG
2. Run the full diagnostic and check for any red errors
3. Test the purchase flow with your review account
4. The app should handle all edge cases gracefully
5. Contact support@folktechai.com if you encounter issues

## Build and Test Commands

```bash
# Build the project
cd "/Volumes/Folk_DAS/Apps/MacroAI/MacroAI Pro"
xcodebuild -project "MacroAI Pro.xcodeproj" -scheme "MacroAI Pro" -configuration Debug build

# Run tests
xcodebuild -project "MacroAI Pro.xcodeproj" -scheme "MacroAI Pro" test
```
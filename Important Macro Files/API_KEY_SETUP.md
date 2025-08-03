# MacroAI API Key Setup Instructions

## 🔑 How to Add Your API Keys

Your MacroAI app is now configured to use API keys stored directly in the code (like most AI apps). This means:

- ✅ **Users don't need their own API keys** - they just download and use your app
- ✅ **You control all costs** through your own API accounts  
- ✅ **Professional app experience** - no setup required for users

## 📝 Steps to Configure:

### 1. Get Your API Keys
- **OpenAI**: Go to https://platform.openai.com/api-keys and create a new key
- **Spoonacular**: Go to https://spoonacular.com/food-api and get your API key

### 2. Add Keys to SecureConfig.swift
Open `MacroAI/MacroAI/SecureConfig.swift` and replace:

```swift
static let openAIAPIKey = "YOUR_OPENAI_API_KEY_WILL_GO_HERE"
static let spoonacularAPIKey = "YOUR_SPOONACULAR_API_KEY_WILL_GO_HERE"
```

With your actual keys:

```swift
static let openAIAPIKey = "sk-proj-your-actual-openai-key-here"
static let spoonacularAPIKey = "your-actual-spoonacular-key-here"
```

### 3. Build and Test
- Build the app in Xcode
- Test in simulator - should work immediately without any user setup
- Deploy to TestFlight - users can use immediately

## 🔒 Security Notes:

- Your API keys are compiled into the app (this is standard for AI apps)
- Only you have access to your keys
- Users get to use your app without needing their own API accounts
- You control usage and costs through your API dashboards

## 🚀 Ready for Production:

Once you add your keys, the app will:
- ✅ Use real OpenAI GPT-4o-mini for food recognition
- ✅ Use real Spoonacular API for nutrition data  
- ✅ Work immediately for all TestFlight users
- ✅ No more "doughnut identified as banana" issues
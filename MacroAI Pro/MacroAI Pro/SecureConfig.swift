// SecureConfig.swift
// Configuration file for API keys and secure settings
// API keys are stored securely in the keychain

import Foundation

struct SecureConfig {
    // Keychain service identifiers (matching MacroAI-real)
    static let openAIService = "OpenAIService"
    static let spoonacularService = "SpoonacularService"
    
    // Development/Testing Configuration
    static let isDevelopment = true
    
    // MARK: - API Key Management
    
    static func getOpenAIAPIKey() -> String? {
        do {
            let key = try KeychainHelper.shared.retrieveString(service: openAIService, account: "apiKey")
            return key
        } catch {
            // Suppress warning for expected "item not found" error
            if let keychainError = error as? KeychainHelper.KeychainError,
               case .unhandledError(let status) = keychainError,
               status == errSecItemNotFound {
                // This is expected when API key hasn't been set yet
                return nil
            } else {
                print("⚠️ [SecureConfig] Failed to retrieve OpenAI API key: \(error)")
            }
            return nil
        }
    }
    
    static func getSpoonacularAPIKey() -> String? {
        do {
            let key = try KeychainHelper.shared.retrieveString(service: spoonacularService, account: "apiKey")
            return key
        } catch {
            // Suppress warning for expected "item not found" error
            if let keychainError = error as? KeychainHelper.KeychainError,
               case .unhandledError(let status) = keychainError,
               status == errSecItemNotFound {
                // This is expected when API key hasn't been set yet
                return nil
            } else {
                print("⚠️ [SecureConfig] Failed to retrieve Spoonacular API key: \(error)")
            }
            return nil
        }
    }
    
    static func saveOpenAIAPIKey(_ key: String) throws {
        try KeychainHelper.shared.saveString(key, service: openAIService, account: "apiKey")
        print("✅ OpenAI API key saved to keychain")
    }
    
    static func saveSpoonacularAPIKey(_ key: String) throws {
        try KeychainHelper.shared.saveString(key, service: spoonacularService, account: "apiKey")
        print("✅ Spoonacular API key saved to keychain")
    }
    
    static func deleteOpenAIAPIKey() throws {
        try KeychainHelper.shared.delete(service: openAIService, account: "apiKey")
        print("🗑️ OpenAI API key deleted from keychain")
    }
    
    static func deleteSpoonacularAPIKey() throws {
        try KeychainHelper.shared.delete(service: spoonacularService, account: "apiKey")
        print("🗑️ Spoonacular API key deleted from keychain")
    }
    
        // Initialize API keys in keychain (keys are now stored securely in keychain)
    static func initializeAPIKeys() {
        // Check if OpenAI key already exists in keychain (silent check)
        if getOpenAIAPIKey() == nil {
            // Silent - no console spam
        } else {
            // Silent - no console spam
        }

        // Check if Spoonacular key already exists in keychain (silent check)
        if getSpoonacularAPIKey() == nil {
            // Silent - no console spam
        } else {
            // Silent - no console spam
        }
    }
} 
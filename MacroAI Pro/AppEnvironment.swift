import Foundation

enum AppEnvironment {
    static var isSandboxReceipt: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    static var isSandboxBuild: Bool {
        #if SANDBOX
        return true
        #else
        return false
        #endif
    }

    static var isSandbox: Bool {
        return isSandboxBuild || isSandboxReceipt
    }
}

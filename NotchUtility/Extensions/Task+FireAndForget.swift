import Foundation

/**
 Fire-and-forget async operation extension for Task.
 
 This extension provides a clean API for executing async operations without blocking the caller,
 with optional error handling that automatically runs on the MainActor.
 
 ## Usage Examples
 
 ### Simple fire-and-forget
 ```swift
 // Single async operation with error handling
 Task.fire {
     try await storageManager.saveFile(data)
 } catch: { error in
     showAlert("Save failed: \(error.localizedDescription)")
 }
 
 // Fire-and-forget without error handling
 Task.fire {
     try await analyticsService.trackEvent("user_action")
 }
 ```
 
 ### Complex operations
 ```swift
 // Multiple async operations
 Task.fire {
     try await downloadFile()
     try await processFile()
     try await uploadResults()
 } catch: { error in
     showError("Pipeline failed: \(error)")
 }
 
 // Conditional async logic
 Task.fire {
     let user = try await fetchCurrentUser()
     if user.isPremium {
         try await enablePremiumFeatures()
     }
 } catch: { error in
     handleAuthError(error)
 }
 ```
 */
extension Task where Success == Void, Failure == Never {
    /// Fire-and-forget async operation with error handling
    /// - Parameters:
    ///   - operation: The async throwing operation to execute
    ///   - catch: Optional error handler called on MainActor if the operation fails
    @discardableResult
    static func fire(
        _ operation: @escaping () async throws -> Void,
        catch errorHandler: (@MainActor (Error) -> Void)? = nil
    ) -> Task<Void, Never> {
        return Task {
            do {
                try await operation()
            } catch {
                if let errorHandler = errorHandler {
                    await MainActor.run {
                        errorHandler(error)
                    }
                }
            }
        }
    }
} 
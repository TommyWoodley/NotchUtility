import Foundation

/**
 Fire-and-forget async operation extension for Task.
 
 This extension provides a clean API for executing async operations without blocking the caller,
 with optional error handling that automatically runs on the MainActor.
 
 ## Usage Examples
 
 ### Simple fire-and-forget (autoclosure version)
 ```swift
 // Single async operation with error handling
 Task.fire(storageManager.saveFile(data), catch: { error in
     showAlert("Save failed: \(error.localizedDescription)")
 })
 
 // Fire-and-forget without error handling
 Task.fire(analyticsService.trackEvent("user_action"))
 ```
 
 ### Complex operations (closure version)
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
    /// Fire-and-forget async operation with error handling (closure version)
    /// - Parameters:
    ///   - operation: The async throwing operation to execute
    ///   - catch: Optional error handler called on MainActor if the operation fails
    @discardableResult
    static func fire(
        _ operation: @escaping () async throws -> Void,
        catch errorHandler: (@MainActor @escaping (Error) -> Void)? = nil
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
    
    /// Fire-and-forget async operation with error handling (autoclosure version)
    /// - Parameters:
    ///   - operation: The async throwing operation to execute (autoclosure)
    ///   - catch: Optional error handler called on MainActor if the operation fails
    @discardableResult
    static func fire<T>(
        _ operation: @escaping @autoclosure () async throws -> T,
        catch errorHandler: (@MainActor @escaping (Error) -> Void)? = nil
    ) -> Task<Void, Never> {
        return Task {
            do {
                _ = try await operation()
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
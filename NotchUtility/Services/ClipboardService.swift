//
//  ClipboardService.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Foundation
import Combine
import AppKit

@MainActor
class ClipboardService: ObservableObject {
    @Published var clipboardHistory: [ClipboardItem] = []
    
    private let maxHistoryItems = 5
    private var lastChangeCount: Int = 0
    private var monitoringTimer: Timer?
    
    init() {
        setupClipboardMonitoring()
        loadInitialClipboard()
    }
    
    deinit {
        monitoringTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
    }
    
    func clearHistory() {
        clipboardHistory.removeAll()
    }
    
    func removeItem(_ item: ClipboardItem) {
        clipboardHistory.removeAll { $0.id == item.id }
    }
    
    // MARK: - Private Methods
    
    private func setupClipboardMonitoring() {
        // Monitor clipboard changes every 0.5 seconds
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboardChanges()
            }
        }
    }
    
    private func loadInitialClipboard() {
        checkClipboardChanges()
    }
    
    private func checkClipboardChanges() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        // Only process if clipboard has actually changed
        guard currentChangeCount != lastChangeCount else { return }
        
        lastChangeCount = currentChangeCount
        
        // Try to get string content first
        if let stringContent = pasteboard.string(forType: .string), !stringContent.isEmpty {
            let type = determineClipboardType(for: stringContent)
            let newItem = ClipboardItem(
                content: stringContent,
                type: type,
                changeCount: currentChangeCount
            )
            
            addToHistory(newItem)
        }
    }
    
    private func determineClipboardType(for content: String) -> ClipboardType {
        // Check if it's a URL
        if let url = URL(string: content.trimmingCharacters(in: .whitespacesAndNewlines)),
           url.scheme != nil {
            return .url
        }
        
        // Default to text
        return .text
    }
    
    private func addToHistory(_ item: ClipboardItem) {
        // Don't add duplicate content
        guard !clipboardHistory.contains(where: { $0.content == item.content }) else { return }
        
        // Add to front of array
        clipboardHistory.insert(item, at: 0)
        
        // Keep only the last maxHistoryItems
        if clipboardHistory.count > maxHistoryItems {
            clipboardHistory = Array(clipboardHistory.prefix(maxHistoryItems))
        }
    }
} 
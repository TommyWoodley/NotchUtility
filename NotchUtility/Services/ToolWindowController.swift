//
//  ToolWindowController.swift
//  NotchUtility
//
//  Created for presenting tool modals in a separate window without sheet dimming.
//

import Cocoa
import SwiftUI

class ToolWindowController: NSWindowController {
    private static var currentController: ToolWindowController?
    
    static func show(tool: DevTool) {
        // Close any existing tool window
        currentController?.close()
        
        let controller = ToolWindowController(tool: tool)
        currentController = controller
        controller.showWindow(nil)
    }
    
    static func dismiss() {
        currentController?.close()
        currentController = nil
    }
    
    init(tool: DevTool) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.windowBackgroundColor
        window.center()
        
        // Set window level slightly above normal to ensure visibility
        window.level = .floating
        
        super.init(window: window)
        
        // Create the SwiftUI content with dismiss action
        let contentView = ToolWindowContentView(tool: tool) {
            ToolWindowController.dismiss()
        }
        
        window.contentViewController = NSHostingController(rootView: contentView)
        
        // Make the window key and order front
        window.makeKeyAndOrderFront(nil)
        
        // Use known window dimensions (set in contentRect during init)
        let windowWidth: CGFloat = 500
        let windowHeight: CGFloat = 400
        
        // Position the window centered horizontally and underneath the notch area
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            
            // Center horizontally on screen using known window width
            let x = screenFrame.origin.x + (screenFrame.width - windowWidth) / 2
            
            // Position below the notch/menu bar area
            let distanceFromTop: CGFloat = 250
            let y = screenFrame.maxY - distanceFromTop - windowHeight
            
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ToolWindowContentView: View {
    let tool: DevTool
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Modal Header
            HStack {
                Image(systemName: tool.icon)
                    .foregroundColor(tool.color)
                    .font(.title2)
                
                Text(tool.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: dismissAction) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
            
            // Tool Content
            ScrollView {
                switch tool {
                case .base64:
                    Base64Tool()
                case .jsonFormatter:
                    JSONFormatterTool()
                case .xmlFormatter:
                    XMLFormatterTool()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .windowBackgroundColor))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 500, height: 400)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(.dark)
    }
}


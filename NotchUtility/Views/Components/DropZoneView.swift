//
//  DropZoneView.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

// MARK: - Drop Zone View (Visual Elements)
struct DropZoneView: View {
    let style: DropZoneStyle
    let isActive: Bool
    
    enum DropZoneStyle {
        case standard
        case overlay
    }
    
    init(style: DropZoneStyle, isActive: Bool = false) {
        self.style = style
        self.isActive = isActive
    }
    
    var body: some View {
        ZStack {
            switch style {
            case .standard:
                standardDropZone
            case .overlay:
                overlayDropZone
            }
        }
    }
    
    private var standardDropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isActive ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
                )
            
            VStack(spacing: 5) {
                Image(systemName: isActive ? "arrow.down.circle.fill" : "plus.circle")
                    .font(.system(size: 32))
                    .foregroundColor(isActive ? .accentColor : .secondary)
            }
            .padding()
        }
    }
    
    private var overlayDropZone: some View {
        Group {
            if isActive {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    )
                    .overlay(
                        VStack(spacing: 5) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.accentColor)
                        }
                        .padding()
                    )
                    .transition(.opacity)
            }
        }
    }
}

#Preview("Standard - Inactive") {
    DropZoneView(style: .standard)
        .frame(width: 200, height: 100)
        .padding()
}

#Preview("Standard - Active") {
    DropZoneView(style: .standard, isActive: true)
        .frame(width: 200, height: 100)
        .padding()
}

#Preview("Overlay - Active") {
    ZStack {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(width: 300, height: 200)
        
        DropZoneView(style: .overlay, isActive: true)
    }
} 

//
//  NotchOverlayView.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import SwiftUI

struct NotchOverlayView: View {
    @StateObject var vm: NotchViewModel
    @State var dropTargeting: Bool = false
    @State private var selectedTab: NotchTab = .files

    var notchSize: CGSize {
        switch vm.status {
        case .closed:
            var ans = CGSize(
                width: vm.deviceNotchRect.width - 4,
                height: vm.deviceNotchRect.height - 4
            )
            if ans.width < 0 { ans.width = 0 }
            if ans.height < 0 { ans.height = 0 }
            return ans
        case .opened:
            return vm.notchOpenedSize
        case .popping:
            return .init(
                width: vm.deviceNotchRect.width,
                height: vm.deviceNotchRect.height + 4
            )
        }
    }

    var notchCornerRadius: CGFloat {
        switch vm.status {
        case .closed: 8
        case .opened: 32
        case .popping: 10
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            notch
                .zIndex(0)
                .disabled(true)
                .opacity(vm.notchVisible ? 1 : 0.3)
            Group {
                if vm.status == .opened {
                    VStack(spacing: vm.spacing) {
                        NotchHeaderView(vm: vm, selectedTab: $selectedTab)
                        NotchContentView(vm: vm, selectedTab: selectedTab)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(vm.spacing)
                    .frame(maxWidth: vm.notchOpenedSize.width, maxHeight: vm.notchOpenedSize.height)
                    .zIndex(1)
                }
            }
            .transition(
                .scale
                    .combined(with: .opacity)
                    .combined(with: .offset(y: -vm.notchOpenedSize.height / 2))
                    .animation(vm.animation)
            )
        }
        .background(dragDetector)
        .animation(vm.animation, value: vm.status)
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    var notch: some View {
        Rectangle()
            .foregroundStyle(.black)
            .mask(notchBackgroundMaskGroup)
            .frame(
                width: notchSize.width + notchCornerRadius * 2,
                height: notchSize.height
            )
            .shadow(
                color: .black.opacity(([.opened, .popping].contains(vm.status)) ? 1 : 0),
                radius: 8
            )
    }

    var notchBackgroundMaskGroup: some View {
        Rectangle()
            .foregroundStyle(.black)
            .frame(
                width: notchSize.width,
                height: notchSize.height
            )
            .clipShape(.rect(
                bottomLeadingRadius: notchCornerRadius,
                bottomTrailingRadius: notchCornerRadius
            ))
            .overlay {
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .frame(width: notchCornerRadius, height: notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topTrailingRadius: notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchCornerRadius + vm.spacing,
                            height: notchCornerRadius + vm.spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -notchCornerRadius - vm.spacing + 0.5, y: -0.5)
            }
            .overlay {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: notchCornerRadius, height: notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topLeadingRadius: notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchCornerRadius + vm.spacing,
                            height: notchCornerRadius + vm.spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: notchCornerRadius + vm.spacing - 0.5, y: -0.5)
            }
    }

    @ViewBuilder var dragDetector: some View {
        RoundedRectangle(cornerRadius: notchCornerRadius)
            .foregroundStyle(Color.black.opacity(0.001))
            .contentShape(Rectangle())
            .frame(width: notchSize.width + vm.dropDetectorRange, height: notchSize.height + vm.dropDetectorRange)
            .onDrop(of: [.data], isTargeted: $dropTargeting) { _ in true }
            .onChange(of: dropTargeting) { isTargeted in
                if isTargeted, vm.status == .closed {
                    vm.notchOpen(.drag)
                    vm.hapticSender.send()
                } else if !isTargeted {
                    let mouseLocation: NSPoint = NSEvent.mouseLocation
                    if !vm.notchOpenedRect.insetBy(dx: vm.inset, dy: vm.inset).contains(mouseLocation) {
                        vm.notchClose()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Preview Components

#Preview("NotchOverlayView - Closed") {
    NotchOverlayView(vm: createMockViewModel(status: .closed))
        .frame(width: 400, height: 200)
        .background(Color.blue.opacity(0.3)) // Background to visualize the notch
}

#Preview("NotchOverlayView - Opened") {
    NotchOverlayView(vm: createMockViewModel(status: .opened))
        .frame(width: 700, height: 500)
        .background(Color.blue.opacity(0.3))
}

#Preview("NotchOverlayView - Popping") {
    NotchOverlayView(vm: createMockViewModel(status: .popping))
        .frame(width: 400, height: 200)
        .background(Color.blue.opacity(0.3))
}

// MARK: - Preview Helper Functions

@MainActor
private func createMockViewModel(status: NotchViewModel.Status) -> NotchViewModel {
    let vm = PreviewNotchViewModel(targetStatus: status)
    return vm
}

// MARK: - Preview-specific ViewModel

@MainActor
private class PreviewNotchViewModel: NotchViewModel {
    private let targetStatus: Status
    private var isLocked = false
    
    init(targetStatus: Status) {
        self.targetStatus = targetStatus
        super.init(inset: -4)
        
        // Set up mock geometry
        deviceNotchRect = CGRect(x: 0, y: 0, width: 200, height: 30)
        screenRect = CGRect(x: 0, y: 0, width: 400, height: 250)
        
        // Set the target status using public methods
        switch targetStatus {
        case .closed:
            notchClose()
        case .opened:
            notchOpen(.click)
        case .popping:
            notchPop()
        }
        
        // Now lock the state and disable event handling
        isLocked = true
        destroy()
    }
    
    // Prevent any state changes in previews after locking
    override func notchOpen(_ reason: OpenReason) {
        if isLocked { return }
        super.notchOpen(reason)
    }
    
    override func notchClose() {
        if isLocked { return }
        super.notchClose()
    }
    
    override func notchPop() {
        if isLocked { return }
        super.notchPop()
    }
} 

//
//  Binding+IsPresent.swift
//  NotchUtility
//
//  Created by thwoodle on 28/07/2025.
//

import SwiftUI

/*
 Extension providing convenient methods for working with optional Binding values
 */
extension Binding {
    
    /*
     Creates a Boolean binding that represents whether an optional binding has a non-nil value.
     
     This method is particularly useful for presenting sheets, alerts, or other UI elements
     based on optional state variables. When the returned binding is set to `false`,
     the original optional binding is automatically set to `nil`.
     
     # Example Usage
     ```swift
     @State private var selectedItem: Item?
     
     var body: some View {
         ContentView()
             .sheet(isPresented: $selectedItem.isPresent()) {
                 ItemDetailView(item: selectedItem!)
             }
     }
     ```
     
     - Returns: A `Binding<Bool>` that is `true` when the optional value is non-nil,
       and setting it to `false` will set the optional value to `nil`.
     
     - Note: This method only works with optional types. The generic constraint ensures
       compile-time safety.
     */
    func isPresent<T>() -> Binding<Bool> where Value == T? {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { if !$0 { wrappedValue = nil } }
        )
    }
} 
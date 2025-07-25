//
//  DropUtility.swift
//  NotchUtility
//
//  Created by thwoodle on 24/07/2025.
//

import Foundation

struct DropUtility {
    static func extractURLs(from providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        let group = DispatchGroup()
        var urls: [URL] = []
        
        for provider in providers where provider.canLoadObject(ofClass: URL.self) {
            group.enter()
            provider.loadObject(ofClass: URL.self) { url, _ in
                defer { group.leave() }
                
                if let url = url, url.isFileURL {
                    urls.append(url)
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(urls)
        }
    }
} 
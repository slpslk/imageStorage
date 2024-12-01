//
//  MemoryImageStorage.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 30.11.2024.
//

import Foundation
import UIKit

final class MemoryImageStorage {
    let cache = NSCache<NSString, NSData>()
    static let shared = MemoryImageStorage()
    
    func saveToMemoryStorage(_ image: NSData, forKey key: NSString) {
        cache.setObject(image, forKey: key)
    }

    func getFromMemoryStorage(forKey key: NSString) -> NSData? {
        cache.object(forKey: key)
    }
}

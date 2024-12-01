//
//  AddImageViewModel.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 29.11.2024.
//

import Foundation

final class AddImageViewModel {
    var urlText: String = ""
    @Published var isClosed: Bool = false
    
    func closeView() {
        isClosed = true
    }
}

//
//  CollectionViewModel.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 27.11.2024.
//

import Foundation
import Combine

final class CollectionViewModel {
    @Published var imagesViewModels: [ImageCellModel] = []
    private let downloader = ImageDownloadingManager()
    private var cancellable: AnyCancellable?
    
    init() {
        loadViewModels()
    }
    
    func loadViewModels() {
        cancellable = downloader.getImagesViewModels()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to load images: \(error)")
                }
            }, receiveValue: { [weak self] imagesViewModels in
                self?.imagesViewModels = imagesViewModels
            })
    }
}

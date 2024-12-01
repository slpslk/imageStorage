//
//  ImageCellViewModel.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 27.11.2024.
//

import Foundation
import Combine

final class ImageCellViewModel {
    @Published var viewState: CellViewState = .initial
    private let model: ImageCellModel
    private let downloader: ImageDownloadingManaging

    private var cancellable: AnyCancellable?

    init(model: ImageCellModel, downloader: ImageDownloadingManaging) {
        self.model = model
        self.downloader = downloader
        getCachedImage()
    }
    
    func loadImage() {
        cancellable = downloader.downloadImageFromServer(imageURL: model.url)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    self.viewState = .error
                }
            }, receiveValue: { [weak self] state in
                if case .progress(let persent) = state.progress {
                    self?.viewState = .inProgress(persent)
                } else if case .finish = state.progress {
                    if let data = state.data {
                        self?.cacheImage(data)
                        self?.viewState = .downloaded(data)
                    }
                }
            })
    }
}

private extension ImageCellViewModel {
    func cacheImage(_ data: Data) {
        let key = model.name as NSString
        MemoryImageStorage.shared.saveToMemoryStorage(NSData(data: data), forKey: key)
    }

    func getCachedImage() {
        let key = model.name as NSString
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let imageData = MemoryImageStorage.shared.getFromMemoryStorage(forKey: key) {
                self?.viewState = .downloaded(Data(imageData))
            }
        }
    }
}

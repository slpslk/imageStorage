//
//  ImagePreviewViewModel.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 29.11.2024.
//

import Foundation
import Combine

final class ImagePreviewViewModel {
    private enum Constants {
        static let compressSize = 1
    }

    @Published var viewState: ImagePreviewViewState = .initial
    let imageURL: String?
    private var cancellables = Set<AnyCancellable>()
    private let downloader: ImageDownloadingManaging
    private let preparator: ImagePreparating
    
    init(downloader: ImageDownloadingManaging, preparator: ImagePreparating) {
        self.downloader = downloader
        self.preparator = preparator
        self.imageURL = nil
    }
    
    init(imageURL: String, downloader: ImageDownloadingManaging, preparator: ImagePreparating) {
        self.downloader = downloader
        self.preparator = preparator
        self.imageURL = imageURL
    }
    
    func loadImageFromURL() {
        viewState = .downloading
        if let imageURL {
            downloader.downloadImageFromURL(imageURL)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        self.viewState = .error
                    }
                }, receiveValue: { [weak self] state in
                    if case .finish = state.progress {
                        if let data = state.data {
                            self?.prepareImage(imageData: data)
                        }
                    }
                })
                .store(in: &cancellables)
        }
    }
    
    func prepareImage(imageData: Data) {
        viewState = .preparing
        preparator.compressImage(imageData: imageData, toSizeInMB: Constants.compressSize)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self.viewState = .error
                }
            }, receiveValue: { [weak self] data in
                self?.viewState = .ready(data)
            })
            .store(in: &cancellables)
    }
    
    func uploadImage(imageData: Data) {
        viewState = .uploading
        downloader.uploadImageToServer(imageData: imageData)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self.viewState = .error
                }
            }, receiveValue: { [weak self] data in
                if let name = data["name"] as? String {
                    self?.cacheImage(imageData, key: name)
                }
                self?.viewState = .uploaded
            })
            .store(in: &cancellables)
    }
}

private extension ImagePreviewViewModel {
    func cacheImage(_ data: Data, key: String) {
        MemoryImageStorage.shared.saveToMemoryStorage(NSData(data: data), forKey: key as NSString)
    }
}



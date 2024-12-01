//
//  ImagePreparator.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 29.11.2024.
//

import Foundation
import UIKit
import Combine

protocol ImagePreparating {
    func compressImage(imageData: Data, toSizeInMB: Int) -> AnyPublisher<Data, Error>
}

final class ImagePreparator {
    private enum Constants {
        static let maxDimension: CGFloat = 1000
    }
}

extension ImagePreparator: ImagePreparating {
    func compressImage(imageData: Data, toSizeInMB: Int) -> AnyPublisher<Data, Error> {
        return Future { [weak self] promise in
            guard var originalImage = UIImage(data: imageData) else {
                promise(.failure(ImageResizeError.invalidImageData))
                return
            }
            
            if let resizedImage = self?.resizeImageDimensional(image: originalImage) {
                originalImage = resizedImage
            }
            
            let maxFileSize = toSizeInMB * 1024 * 1024
            var compression: CGFloat = 1.0
            var compressedData: Data? = originalImage.jpegData(compressionQuality: compression)
            
            while let data = compressedData, data.count > Int(maxFileSize), compression > 0.01 {
                compression -= 0.1
                compressedData = originalImage.jpegData(compressionQuality: compression)
            }
            
            guard let finalData = compressedData else {
                promise(.failure(ImageResizeError.imageConversionFailed))
                return
            }
            
            promise(.success(finalData))
        }
        .eraseToAnyPublisher()
    }
}

private extension ImagePreparator {
    func resizeImageDimensional(image: UIImage) -> UIImage? {
        let aspectRatio = min(Constants.maxDimension / image.size.width, Constants.maxDimension / image.size.height)
        
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}

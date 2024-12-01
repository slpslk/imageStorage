//
//  ImageDownloadingManager.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 27.11.2024.
//

import Foundation
import UIKit
import Combine

protocol ImageDownloadingManaging {
    func getImagesViewModels() -> AnyPublisher<[ImageCellModel], URLFetchError>
    func downloadImageFromURL(_ imageURL: String) ->AnyPublisher<DownloadingState, Error>
    func downloadImageFromServer(imageURL: String) -> AnyPublisher<DownloadingState, Error>
    func uploadImageToServer(imageData: Data) -> AnyPublisher<[String: Any], Error>
}

final class ImageDownloadingManager: NSObject {
    private enum Constants {
        static let serverURL = "http://164.90.163.215:1337"
        static let token = "11c211d104fe7642083a90da69799cf055f1fe1836a211aca77c72e3e069e7fde735be9547f0917e1a1000efcb504e21f039d7ff55bf1afcb9e2dd56e4d6b5ddec3b199d12a2fac122e43b4dcba3fea66fe428e7c2ee9fc4f1deaa615fa5b6a68e2975cd2f99c65a9eda376e5b6a2a3aee1826ca4ce36d645b4f59f60cf5b74a"
    }
    
    private var downloadingStatePublisher = PassthroughSubject<DownloadingState, Error>()
    private var progressObserver: NSKeyValueObservation?
}

extension ImageDownloadingManager: ImageDownloadingManaging {
    func getImagesViewModels() -> AnyPublisher<[ImageCellModel], URLFetchError> {
        return getAllAssets(from: Constants.serverURL, token: Constants.token)
            .tryMap { assets in
                assets.compactMap { item in
                    if let name = item["name"] as? String, let url = item["url"] as? String {
                        return ImageCellModel(name: name, url: url)
                    }
                    return nil
                }
            }
            .mapError { _ in URLFetchError.parsingError }
            .eraseToAnyPublisher()
    }
    
    func downloadImageFromURL(_ imageURL: String) ->AnyPublisher<DownloadingState, Error> {
        getImage(from: "", token: "", image: imageURL)
            .eraseToAnyPublisher()
    }
    
    func downloadImageFromServer(imageURL: String) -> AnyPublisher<DownloadingState, Error> {
        getImage(from: Constants.serverURL, token: Constants.token, image: imageURL)
            .eraseToAnyPublisher()
    }
    
    func uploadImageToServer(imageData: Data) -> AnyPublisher<[String: Any], Error> {
        uploadImage(to: Constants.serverURL, imageData: imageData, token: Constants.token)
            .eraseToAnyPublisher()
    }
}

private extension ImageDownloadingManager {
    func getAllAssets(from url: String, token: String) -> AnyPublisher<[[String: Any]], Error> {
        guard let assetsURL = URL(string: "\(url)/api/upload/files") else {
            return Fail(error: URLFetchError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: assetsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLFetchError.invalidServerResponse
                }
                return output.data
            }
            .tryMap { data in
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    return json
                } else {
                    throw URLFetchError.parsingError
                }
            }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    
    func getImage(from url: String, token: String, image: String) -> AnyPublisher<DownloadingState, Error> {
        guard let assetsURL = URL(string: "\(url)\(image)") else {
            return Fail(error: URLFetchError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: assetsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        downloadingStatePublisher.send(.init(progress: .progress(0)))
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: .main)
        let task = session.downloadTask(with: request) { (location, response, error) in
            if let error = error {
                self.downloadingStatePublisher.send(completion: .failure(error))
                return
            }
            guard let location = location, let data = try? Data(contentsOf: location) else {
                self.downloadingStatePublisher.send(completion: .failure(URLFetchError.invalidServerResponse))
                return
            }
            
            let finishData = DownloadingState(progress: .finish,
                                              data: data,
                                              error: nil)
            
            self.downloadingStatePublisher.send(finishData)
            self.downloadingStatePublisher.send(completion: .finished)
        }
        
        progressObserver = task.progress.observe(\.fractionCompleted, changeHandler: { [weak self] progress, _ in
            let progressData = DownloadingState(progress: .progress(progress.fractionCompleted),
                                                data: nil,
                                                error: nil)
            
            self?.downloadingStatePublisher.send(progressData)
        })

        task.resume()

        return downloadingStatePublisher
            .eraseToAnyPublisher()
            
    }
    
    func uploadImage(to url: String, imageData: Data, token: String) -> AnyPublisher<[String: Any], Error>{
        guard let uploadURL = URL(string: "\(url)/api/upload") else {
            return Fail(error: URLFetchError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let imageName = UUID().uuidString
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(imageName).jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLFetchError.invalidServerResponse
                }
                return output.data
            }
            .tryMap { data in
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]], let firstFile = json.first {
                    return firstFile
                } else {
                    throw URLFetchError.parsingError
                }
            }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}

extension ImageDownloadingManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, 
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
    }
}

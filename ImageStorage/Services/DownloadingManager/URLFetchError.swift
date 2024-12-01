//
//  URLFetchError.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 01.12.2024.
//

import Foundation

enum URLFetchError: Error {
    case invalidURL
    case invalidServerResponse
    case parsingError
}

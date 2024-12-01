//
//  ImagePreviewViewState.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 01.12.2024.
//

import Foundation

enum ImagePreviewViewState {
    case initial
    case downloading
    case preparing
    case uploading
    case uploaded
    case error
    case ready(Data?)
}

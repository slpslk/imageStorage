//
//  DownloadingState.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 01.12.2024.
//

import Foundation

struct DownloadingState {
    var progress: DownloadProgress
    var data: Data?
    var error: Error?
}

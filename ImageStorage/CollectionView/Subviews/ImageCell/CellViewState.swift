//
//  CellViewState.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 30.11.2024.
//

import Foundation

enum CellViewState: Equatable {
    case initial
    case inProgress(Double)
    case downloaded(Data?)
    case error
}

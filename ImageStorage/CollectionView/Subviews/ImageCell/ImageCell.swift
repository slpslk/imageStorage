//
//  ImageCell.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 27.11.2024.
//

import Foundation
import UIKit
import Combine

final class ImageCell: UICollectionViewCell {
    var viewModel: ImageCellViewModel? {
        didSet {
            setupBindings()
        }
    }
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var progressStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.addArrangedSubview(progressLabel)
        stack.addArrangedSubview(progressView)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isHidden = true
        return stack
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(progressStack)
        return imageView
    }()
    
    private lazy var downloadButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.setImage(UIImage(systemName: "photo.badge.arrow.down"), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        button.isHidden = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        imageView.image = nil
        progressView.progress = 0
        progressLabel.text = nil
        progressStack.isHidden = true
        downloadButton.isHidden = false
    }
}

private extension ImageCell {
    func setupUI() {
        contentView.backgroundColor = .white
        contentView.addSubview(imageView)
        contentView.addSubview(downloadButton)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            progressStack.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            progressStack.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 10),
            progressStack.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -10)
        ])
        
        NSLayoutConstraint.activate([
            progressView.widthAnchor.constraint(equalTo: progressStack.widthAnchor, multiplier: 1)
        ])
        
        NSLayoutConstraint.activate([
            downloadButton.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 0.25),
            downloadButton.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.25),
            downloadButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            downloadButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])
    }
    
    func setupBindings() {
        guard let viewModel else {
            return
        }
        
        viewModel.$viewState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] viewState in
                switch viewState {
                case .initial:
                    break
                case .inProgress(let progress):
                    self?.progressView.progress = Float(progress)
                    self?.progressLabel.text = "\(Int(progress * 100))%"
                case .downloaded(let data):
                    if let data, let image =  UIImage(data: data), let self {
                        let size = self.imageView.bounds.size
                        DispatchQueue.global().async {
                            let resizedImage = self.resizeImage(image: image, targetSize: size)
                            DispatchQueue.main.async {
                                self.imageView.image = resizedImage
                                self.progressStack.isHidden = true
                                self.downloadButton.isHidden = true
                            }
                        }
                    }
                case .error:
                    self?.progressStack.isHidden = true
                    self?.downloadButton.isHidden = false
                }
            })
            .store(in: &cancellables)
    }
    
    @objc func downloadButtonTapped() {
        guard let viewModel else {
            return
        }
        downloadButton.isHidden = true
        progressStack.isHidden = false
        viewModel.loadImage()
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let aspectWidth = targetSize.width / image.size.width
        let aspectHeight = targetSize.height / image.size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

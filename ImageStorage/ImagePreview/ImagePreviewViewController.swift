//
//  ImagePreviewViewController.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 29.11.2024.
//

import Foundation
import UIKit
import Combine

final class ImagePreviewViewController: UIViewController {
    var viewModel: ImagePreviewViewModel? {
        didSet {
            setupBindings()
            showImage()
        }
    }
    
    private var rawImage: UIImage?
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var loader: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView(style: .medium)
        loader.color = .systemBlue
        loader.translatesAutoresizingMaskIntoConstraints = false
        return loader
    }()
    
    private lazy var loaderLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var loaderStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(loader)
        stack.addArrangedSubview(loaderLabel)
        stack.isHidden = true
        return stack
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setTitle("Отправить", for: .normal)
        button.backgroundColor = .blue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(uploadImage), for: .touchUpInside)
        return button
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    init(image: UIImage) {
        self.rawImage = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        title = "Загрузить изображение"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                                 target: self,
                                                                 action: #selector(dismissVC))
        setupUI()
    }
}

private extension ImagePreviewViewController {
    func setupUI() {
        view.addSubview(imageView)
        view.addSubview(loaderStack)
        view.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            loaderStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            loaderStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        NSLayoutConstraint.activate([
            sendButton.heightAnchor.constraint(equalToConstant: 40),
            sendButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            sendButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }
    
    func setupBindings() {
        guard let viewModel else {
            return
        }
        
        viewModel.$viewState
            .sink(receiveValue: { [weak self] state in
                switch state {
                case .initial:
                    break
                case .error:
                    self?.loader.stopAnimating()
                    self?.loaderStack.isHidden = true
                case .downloading:
                    self?.loaderLabel.text = "Скачивание"
                case .preparing:
                    self?.loaderLabel.text = "Оптимизация"
                case .uploading:
                    self?.loaderLabel.text = "Загрузка"
                case .uploaded:
                    self?.loader.stopAnimating()
                    self?.loaderStack.isHidden = true
                    self?.dismissVC()
                case .ready(let data):
                    if let data {
                        let image = UIImage(data: data)
                        self?.imageView.image = image
                        self?.loader.stopAnimating()
                        self?.loaderStack.isHidden = true
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    func showImage() {
        guard let viewModel else {
            return
        }
        
        if viewModel.imageURL != nil {
            showImageFromURL()
        } else if rawImage != nil {
            showImageFromGallery()
        }
    }
    
    func showImageFromGallery() {
        guard let data = rawImage?.jpegData(compressionQuality: 1), let viewModel else {
            return
        }
        loaderStack.isHidden = false
        loader.startAnimating()
        
        viewModel.prepareImage(imageData: data)
    }
    
    func showImageFromURL() {
        guard let viewModel else {
            return
        }
        loaderStack.isHidden = false
        loader.startAnimating()
        
        viewModel.loadImageFromURL()
    }
    
    @objc func uploadImage() {
        guard let imageData = imageView.image?.jpegData(compressionQuality: 1), let viewModel else {
            return
        }
        
        loaderStack.isHidden = false
        loader.startAnimating()
        applyBlurEffect(to: imageView, withRadius: 30)
        
        viewModel.uploadImage(imageData: imageData)
    }
    
    @objc func dismissVC() {
        dismiss(animated: true)
    }
    
    func applyBlurEffect(to imageView: UIImageView, withRadius radius: CGFloat) {
        guard let image = imageView.image, let ciImage = CIImage(image: image) else {
            return
        }
        
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else  {
            return
        }
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let bluredCIImage = blurFilter.outputImage else {
            return
        }
        
        guard let brightnessFilter = CIFilter(name: "CIColorControls") else  {
            return
        }
        brightnessFilter.setValue(bluredCIImage, forKey: kCIInputImageKey)
        brightnessFilter.setValue(0.5, forKey: kCIInputBrightnessKey)
        
        guard let outputCIImage = brightnessFilter.outputImage else {
            return
        }
        
        let context = CIContext(options: nil)
        
        if let cgImage = context.createCGImage(outputCIImage, from: ciImage.extent) {
            let blurredImage = UIImage(cgImage: cgImage)
            imageView.image = blurredImage
        }
    }
}

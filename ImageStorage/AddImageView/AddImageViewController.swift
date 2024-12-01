//
//  AddImageViewController.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 29.11.2024.
//

import Foundation
import UIKit
import Combine

final class AddImageViewController: UIViewController {
    var viewModel: AddImageViewModel? {
        didSet {
            setupBindings()
        }
    }
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var urlHeader: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.text = "Загрузить по URL"
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var urlTextField: UITextField = {
        let textField = UITextField()
        textField.textColor = .black
        textField.placeholder = "Введите URL"
        textField.font = .systemFont(ofSize: 14)
        textField.borderStyle = .roundedRect
        textField.layer.borderColor = UIColor.black.cgColor
        return textField
    }()
    
    private lazy var urlButton: UIButton = {
        let button = UIButton()
        button.setTitle("Загрузить", for: .normal)
        button.backgroundColor = .blue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(urlButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var stack: UIStackView = {
       let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.addArrangedSubview(urlTextField)
        stack.addArrangedSubview(urlButton)
        return stack
    }()
    
    private lazy var galleryButton: UIButton = {
        let button = UIButton()
        button.setTitle("Выбрать в галерее", for: .normal)
        button.backgroundColor = .blue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(galleryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = self
        return picker
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

extension AddImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, 
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true)
            
            let imagePreviewView = ImagePreviewViewController(image: image)
            self.present(UINavigationController(rootViewController: imagePreviewView), animated: true)
            
            let imageDownloader = ImageDownloadingManager()
            let imagePreparator = ImagePreparator()
            let imagePreviewViewModel = ImagePreviewViewModel(downloader: imageDownloader,
                                                              preparator: imagePreparator)
            imagePreviewViewModel.$viewState
                .sink(receiveValue: { [weak self] state in
                    if case .uploaded = state {
                        self?.viewModel?.closeView()
                        self?.navigationController?.popViewController(animated: true)
                    }
                })
                .store(in: &cancellables)
            imagePreviewView.viewModel = imagePreviewViewModel
        }
    }
}

private extension AddImageViewController {
    func setupUI() {
        view.addSubview(urlHeader)
        view.addSubview(stack)
        view.addSubview(galleryButton)
        view.backgroundColor = .white
        title = "Загрузить изображение"
        
        urlHeader.translatesAutoresizingMaskIntoConstraints = false
        urlTextField.translatesAutoresizingMaskIntoConstraints = false
        urlButton.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            urlHeader.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            urlHeader.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            urlHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
        ])

        NSLayoutConstraint.activate([
            urlButton.widthAnchor.constraint(equalToConstant: 100),
            urlButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: urlHeader.bottomAnchor, constant: 10)
        ])
        
        NSLayoutConstraint.activate([
            galleryButton.heightAnchor.constraint(equalToConstant: 50),
            galleryButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            galleryButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            galleryButton.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 10)
        ])
    }
    
    func setupBindings() {
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: urlTextField)
            .compactMap { ($0.object as? UITextField)?.text }
            .sink { [weak self] text in
                self?.viewModel?.urlText = text
            }
            .store(in: &cancellables)
    }
    
    @objc func urlButtonTapped() {
        if let url = viewModel?.urlText, !url.isEmpty {
            let imagePreviewView = ImagePreviewViewController()
            let imageDownloader = ImageDownloadingManager()
            let imagePreparator = ImagePreparator()
            let imagePreviewViewModel = ImagePreviewViewModel(imageURL: url,
                                                              downloader: imageDownloader,
                                                              preparator: imagePreparator)
            imagePreviewViewModel.$viewState
                .sink(receiveValue: { [weak self] state in
                    if case .uploaded = state {
                        self?.viewModel?.closeView()
                        self?.navigationController?.popViewController(animated: true)
                    }
                })
                .store(in: &cancellables)
            imagePreviewView.viewModel = imagePreviewViewModel
            
            self.present(UINavigationController(rootViewController: imagePreviewView), animated: true)
        }
    }
    
    @objc func galleryButtonTapped() {
        present(imagePicker, animated: true)
    }
}

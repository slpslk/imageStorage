//
//  ViewController.swift
//  ImageStorage
//
//  Created by Sofya Avtsinova on 27.11.2024.
//

import UIKit
import Combine

final class ViewController: UIViewController {
    private enum Constants {
        static let padding: CGFloat = 8
        static let number: CGFloat = 2
    }

    private let viewModel = CollectionViewModel()
    private var cancellables = Set<AnyCancellable>()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = Constants.padding
        layout.minimumLineSpacing = Constants.padding
        layout.sectionInset = .init(top: 0, left: Constants.padding, bottom: 0, right: Constants.padding)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    private lazy var addImageButton: UIButton = {
        let button = UIButton()
        button.setTitle("Загрузить", for: .normal)
        button.backgroundColor = .blue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(addImageButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Список изображений"
        
        setupBindings()
        setupUI()
        collectionView.reloadData()
    }
}

extension ViewController: UICollectionViewDelegate, 
                          UICollectionViewDataSource,
                          UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, 
                        numberOfItemsInSection section: Int) -> Int {
        viewModel.imagesViewModels.count
    }

    func collectionView(_ collectionView: UICollectionView, 
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        let imageDownloader = ImageDownloadingManager()
        cell.viewModel = ImageCellViewModel(model: viewModel.imagesViewModels[indexPath.row],
                                            downloader: imageDownloader)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, 
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - Constants.padding * (Constants.number + 1)) / Constants.number
        return .init(width: width, height: width)
    }
}

private extension ViewController {
    func setupBindings() {
        viewModel.$imagesViewModels
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(addImageButton)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addImageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            addImageButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 10),
            addImageButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            addImageButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            addImageButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
        ])
    }
    
    @objc func addImageButtonTapped() {
        let addImageViewModel = AddImageViewModel()
        addImageViewModel.$isClosed
            .sink(receiveValue: { [weak self] state in
                if state {
                    self?.viewModel.loadViewModels()
                }
            })
            .store(in: &cancellables)
        let addImageView = AddImageViewController()
        addImageView.viewModel = addImageViewModel
        navigationController?.pushViewController(addImageView, animated: true)
    }
}

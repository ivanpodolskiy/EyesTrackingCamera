//
//  LastPhotoView.swift
//  EyesTrackingCamera
//
//  Created by user on 21.03.2024.
//

import Foundation
import UIKit

class LastPhotoView: UIView {
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupSubiews()
        
        self.backgroundColor = UIColor.specialGreenV2.withAlphaComponent(0.45)
        self.layer.cornerRadius = 10
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        return imageView
    }()

    private func setupSubiews() {
        addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: topAnchor, constant: 2).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2).isActive = true
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2).isActive = true
    }
    
    func updateImage(_ image: UIImage) {
        imageView.image = image
    }
}

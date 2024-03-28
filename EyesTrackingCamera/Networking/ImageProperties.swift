//
//  ImageProperties.swift
//  EyesTrackingCamera
//
//  Created by user on 23.03.2024.
//

import UIKit

struct ImageProperties {
    let key: String
    let data: Data
    
    init?(withImage image: UIImage,froKey key: String) {
        self.key = key
        guard let data = image.pngData() else { return nil }
        self.data = data
    }
}

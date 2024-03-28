//
//  ActionCameraButton.swift
//  EyesTrackingCamera
//
//  Created by user on 22.03.2024.
//

import UIKit

class ActionCameraButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configuration()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configuration() {
        self.layer.opacity = 0.5
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor =  UIColor.specialLight
        self.layer.cornerRadius = 33
        self.layer.borderWidth = 10
        self.layer.borderColor = UIColor.specialGreen.cgColor
    }

    func updateStatusEnable(_ status: Bool) {
        self.isEnabled = status
        self.layer.opacity = status ? 0.5 : 0.3
    }
}

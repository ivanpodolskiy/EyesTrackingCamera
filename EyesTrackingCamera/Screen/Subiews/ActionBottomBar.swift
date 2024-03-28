//
//  ActionBottomBar.swift
//  EyesTrackingCamera
//
//  Created by user on 21.03.2024.
//
import UIKit

protocol BottomBarDelegate: AnyObject {
    func switchCamera()
    func takePhoto()
}

class ActionBottomBar: UIView {
    weak var delegate: BottomBarDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setSubviews()
        activateLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private lazy var lastSavedPhotoView: LastPhotoView = {
        let view = LastPhotoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var actionCameraButton: ActionCameraButton = {
        let button = ActionCameraButton(type: .custom)
        button.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        return button
    }()
    private lazy var switchCameraButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let symbolConfiguration = UIImage.SymbolConfiguration.init(pointSize: 28)
        
        button.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.circle.fill")?.withConfiguration( symbolConfiguration), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.specialGreenV2.withAlphaComponent(0.5)
        
        button.imageView?.contentMode = .scaleAspectFill
        button.layer.cornerRadius = 22
        button.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        return button
    }()
    private func setSubviews() {
        addSubview(lastSavedPhotoView)
        addSubview(actionCameraButton)
        addSubview(switchCameraButton)
    }
    private func activateLayout() {
        NSLayoutConstraint.activate([
            lastSavedPhotoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            lastSavedPhotoView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 35),
            lastSavedPhotoView.widthAnchor.constraint(equalToConstant: 44),
            lastSavedPhotoView.heightAnchor.constraint(equalToConstant: 44),
            
            actionCameraButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionCameraButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionCameraButton.widthAnchor.constraint(equalToConstant: 66),
            actionCameraButton.heightAnchor.constraint(equalToConstant: 66),
            
            switchCameraButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            switchCameraButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -35),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 44),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    @objc private func takePhoto(_ sender: UIButton) {
        delegate?.takePhoto()
    }
    
    @objc private func switchCamera(_ sender: UIButton) {
        delegate?.switchCamera()
    }
}

extension ActionBottomBar {
    func changeEnabledActionButton(_ status: Bool) {
        actionCameraButton.isEnabled = status
        actionCameraButton.layer.opacity = status ? 1 : 0.45
    }
    func updateLastImage(_ image: UIImage) {
        lastSavedPhotoView.updateImage(image)
    }
    
    func updateStatusEnable(_ status: Bool) {
        actionCameraButton.updateStatusEnable(status)
    }
}

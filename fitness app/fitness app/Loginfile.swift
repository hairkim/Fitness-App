//
//  Login file.swift
//  fitness app
//
//  Created by Ryan Kim on 2/25/24.
//

import Foundation
import UIKit
import SwiftUI

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = UIColor.white
        
        // Logo
        let logoImageView = UIImageView(image: UIImage(named: "dumbbell_icon"))
        logoImageView.contentMode = .scaleAspectFit
        view.addSubview(logoImageView)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 100),
            logoImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = "Workout App"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = UIColor.black
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Login Button
        let loginButton = UIButton(type: .system)
        loginButton.setTitle("Login", for: .normal)
        loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        loginButton.setTitleColor(UIColor.white, for: .normal)
        loginButton.backgroundColor = UIColor.blue
        loginButton.layer.cornerRadius = 8
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        view.addSubview(loginButton)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func loginButtonTapped() {
        // Handle login button tapped
    }
}

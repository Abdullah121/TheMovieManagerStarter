//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginViaWebsiteButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = ""
        passwordTextField.text = ""
        
        
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        setLoggingIn(loggingIn: true)
        TMDBClient.getRequestToken(completion:self.handleGetTokenResponse(success:error:))
    
    }
    
    @IBAction func loginViaWebsiteTapped() {
        setLoggingIn(loggingIn: true)
        TMDBClient.getRequestToken { (success, error) in
            if success {
                UIApplication.shared.open(TMDBClient.Endpoints.webAuth.url, options: [:], completionHandler: nil)
            }
        }
    }
    
    func handleCreateSessionIdResponse(success: Bool, error: Error?){
        setLoggingIn(loggingIn: false)
        if success {
            self.performSegue(withIdentifier: "completeLogin", sender: nil)
        }
    }
    
    func handleLoginResponse(success: Bool, error: Error?){
        if(success){
            TMDBClient.createSession(completion: self.handleCreateSessionIdResponse(success:error:))
        }else{
            setLoggingIn(loggingIn: false)
            showLoginFailure(message: error?.localizedDescription ?? "")
        }
    }
    
    func handleGetTokenResponse(success : Bool , error : Error?){
        if(success){
            TMDBClient.login(username: self.emailTextField.text!, password: self.passwordTextField.text!, completion: self.handleLoginResponse(success:error:))
        }else{
            setLoggingIn(loggingIn: false)
            showLoginFailure(message: error?.localizedDescription ?? "")
        }
    }
    
    func setLoggingIn(loggingIn: Bool){
        if loggingIn {
            activityIndicator.startAnimating()
        }else{
            activityIndicator.stopAnimating()
        }
        
        emailTextField.isEnabled = !loggingIn
        passwordTextField.isEnabled = !loggingIn
        loginButton.isEnabled = !loggingIn
        loginViaWebsiteButton.isEnabled = !loggingIn
    }
    
    func showLoginFailure(message: String){
        let alertVC = UIAlertController(title: "LoginFailed", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: nil)
    }
    
}

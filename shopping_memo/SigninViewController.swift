//
//  SigninViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2020/12/13.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
//import FBSDKCoreKit
//import FBSDKLoginKit
//import FacebookCore
import AuthenticationServices
import CryptoKit

class SigninViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding/*, LoginButtonDelegate*/ {
    
    
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var appIconImage: UIImageView!
    @IBOutlet weak var signInWithGoogle: GIDSignInButton!
//    @IBOutlet weak var signIngWithFacebook: FBLoginButton!
    @IBOutlet weak var signInWithApple: ASAuthorizationAppleIDButton!
    
    let userDefaults: UserDefaults = UserDefaults.standard
    var userId: String!
    var ref: DatabaseReference!
    var connect = false
    var menuBarButtonItem: UIBarButtonItem!
    var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setFB()
        setUpDataAndDelegate()
        UISetUp()
        menu()
        checkAppVer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil { self.performSegue(withIdentifier: "toRVC", sender: nil) }
    }
    
//    func setFB() {
//        let loginButton = FBLoginButton()
//        loginButton.delegate = self
//    }
//    
//    func loginButton(_ loginButton: FBLoginButton!, didCompleteWith result: LoginManagerLoginResult!, error: Error!) {
//        if let error = error {
//            print(error.localizedDescription)
//            return
//        } else {
//            let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
//            Auth.auth().signIn(with: credential) { (result, error) in
//                if let error = error {
//                    return
//                } else {
//                    self.performSegue(withIdentifier: "toRVC", sender: nil)
//                }
//            }
//        }
//    }
    
    func UISetUp() {
        title = "サインイン"
        signInWithGoogle.style = .wide
        appIconImage.layer.cornerRadius = 40.0
        appIconImage.layer.cornerCurve = .continuous
        appIconImage.layer.borderColor = UIColor.clear.cgColor
        signInWithApple.layer.shadowOpacity = 0.3
        signInWithApple.layer.shadowRadius = 1
        signInWithApple.layer.shadowColor = UIColor.label.cgColor
        signInWithApple.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:  "戻る", style:  .plain, target: nil, action: nil)
    }
    
    func setUpDataAndDelegate() {
        ref = Database.database().reference()
//        signIngWithFacebook.delegate = self
        signInWithApple.addTarget(self, action: #selector(signInApple(_:)), for: .touchUpInside)
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {self.connect = true}
            else {self.connect = false}
        })
    }
    
    func checkAppVer() {
        let AppVer = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        appVersionLabel.text = "Version: " + AppVer!
        Task {
            let result = await AppVersionCheck.appVersionCheck()
            if result {
                DispatchQueue.main.async {
                    let url = URL(string: "https://itunes.apple.com/jp/app/apple-store/id6448711012")!
                    let alert: UIAlertController = UIAlertController(title: "古いバージョンです", message: "AppStoreから更新してください。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "更新する", style: .default, handler: { action in
                        UIApplication.shared.open(url, options: [:]) { success in
                            if success {print("成功!")}}}))
                    alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func signInGoogle() {
        googleSignIn()
    }
    
    @IBAction func relay() {
        self.performSegue(withIdentifier: "toRelayVC", sender: nil)
    }
    
    @objc func signInApple(_ sender: ASAuthorizationAppleIDButton) {
        startSignInWithAppleFlow()
    }
    
    func googleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
            if let error = error {
                print("GIDSignInError: \(error.localizedDescription)")
                return
            }
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self.performSegue(withIdentifier: "toRVC", sender: nil)
                }
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            print("appleIDToken:", appleIDToken)
            print("idTokenString:", idTokenString)
            print("credential:", credential)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print("error:", error.localizedDescription)
                } else {
                    self.performSegue(withIdentifier: "toRVC", sender: nil)
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    //    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: Error?) {
//        //loginする
//        if error == nil{ if result?.isCancelled == true{ return } }
//        let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
//        Auth.auth().signIn(with: credential) { (result, error) in
//            if let error = error {
//                return
//            } else {
//                self.performSegue(withIdentifier: "toRVC", sender: nil)
//            }
//        }
//    }
    
//    func signIn() {
//        let email = emailTextField.text!
//        let password = passwordTextField.text!
//        if emailTextField.text == "" {
//            let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default))
//            self.present(alert, animated: true, completion: nil)
//        } else if !connect {
//            GeneralPurpose.notConnectAlert(VC: self)
//        } else {
//            GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "signIn")
//            auth.signIn(withEmail: email, password: password) { (authResult, error) in
//                if error == nil, let result = authResult {
//                    let userId = Auth.auth().currentUser?.uid
////                    self.ref.child("users").child(userId!).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
////                        let verified = (snapshot.childSnapshot(forPath: "verified").value as? Bool) ?? false
////                        if !verified {
////                            self.userDefaults.set(email, forKey: "email")
////                            self.performSegue(withIdentifier: "toMCVC", sender: result.user)
////                        } else {
//                            self.userDefaults.set(email, forKey: "email")
//                            self.userDefaults.set(password, forKey: "password")
//                            GeneralPurpose.AIV(VC: self, view: self.view, status: "stop", session: "signIn")
//                            self.performSegue(withIdentifier: "toRVC", sender: result.user)
//                            self.passwordTextField.text = ""
////                        }
////                    })
//                } else {
//                    print("error: \(error!)")
//                    let errorCode = (error as? NSError)?.code
//                    if errorCode == 17008 {
//                        let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "メールアドレスが正しくありません。", preferredStyle: .alert)
//                        alert.addAction(UIAlertAction(title: "OK", style: .default))
//                        self.present(alert, animated: true, completion: nil)
//                    } else if errorCode == 17009 {
//                        let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "パスワードが正しくありません。", preferredStyle: .alert)
//                        alert.addAction(UIAlertAction(title: "OK", style: .default))
//                        self.present(alert, animated: true, completion: nil)
//                    } else if errorCode == 17011 {
//                        let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "アカウントが存在しません。", preferredStyle: .alert)
//                        alert.addAction(UIAlertAction(title: "OK", style: .default))
//                        self.present(alert, animated: true, completion: nil)
//                    }
//                }
//            }
//        }
//    }
    
    func menu() {
        let Item = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: "ログインしないで使う", image: UIImage(systemName: "list.bullet"), handler: { _ in
                self.performSegue(withIdentifier: "toNSVC", sender: nil)
            })])
        let delete = UIAction(title: "アカウント削除", image: UIImage(systemName: "person.badge.minus"), attributes: .destructive, handler: { _ in
            self.performSegue(withIdentifier: "toRLIVC", sender: nil)
        })
        let menu = UIMenu(title: "", image: UIImage(systemName: "ellipsis.circle"), options: .displayInline, children: [Item, delete])
        menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
        menuBarButtonItem.tintColor = .label
        self.navigationItem.rightBarButtonItem = menuBarButtonItem
    }
    
//    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
//        print("ログアウト")
//    }
}


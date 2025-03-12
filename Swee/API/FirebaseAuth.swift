import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

enum PhoneError: Error {
    case wrongCode
    case incorrectPhone
    case tooManyAttempts
    case numberIsTaken
    case other(Error?)
}

enum SocialSignInResult {
    case token(String)
    case missingPhone
    case cancelled
}

struct Authentication {
    private var appleSignIn = AppleSignIn()
    
    var name: String? {
        Auth.auth().currentUser?.displayName
    }
    
    func verify(phone: String) async -> Result<String, PhoneError> {
        await withCheckedContinuation { continuation in
            PhoneAuthProvider.provider()
                .verifyPhoneNumber(phone, uiDelegate: nil) { verificationID, error in
                    if let error = error {
                        switch error.localizedDescription {
                        case "TOO_SHORT", "TOO_LONG":
                            return continuation.resume(returning: .failure(PhoneError.incorrectPhone))
                        default:
                            return continuation.resume(returning: .failure(PhoneError.other(error)))
                        }
                    } else if let verificationID = verificationID {
                        continuation.resume(returning: .success(verificationID))
                    } else {
                        continuation.resume(returning: .failure(PhoneError.other(LocalError(message: "verificationId not found"))))
                    }
                }
        }
    }
    
    
    func phoneSignIn(verificationID: String, otp: String) async throws -> String {
        
        let credential: PhoneAuthCredential? = PhoneAuthProvider.provider()
            .credential(withVerificationID: verificationID,
                        verificationCode: otp)
        
        guard let credential = credential else {
            throw PhoneError.other(nil)
        }
        
        if let currentUser = Auth.auth().currentUser {
            do {
                try await currentUser.link(with: credential)
                guard let token = try await Auth.auth().currentUser?.getIDToken() else {
                    throw PhoneError.other(nil)
                }
                return token
            } catch {
                throw handlePhoneSignInError(error)
            }
        }
        
        do {
            try await Auth.auth().signIn(with: credential)
            guard let token = try await Auth.auth().currentUser?.getIDToken() else {
                throw PhoneError.other(nil)
            }
            return token
        } catch {
            throw handlePhoneSignInError(error)
        }
    }
    
    func handlePhoneSignInError(_ error: Error) -> PhoneError {
        guard let authError = error as NSError?, let errorCode = AuthErrorCode(rawValue: authError.code) else {
            return PhoneError.other(nil)
        }
        
        if case .invalidVerificationCode = errorCode.code {
            return PhoneError.wrongCode
        } else if case .credentialAlreadyInUse = errorCode.code {
            return PhoneError.numberIsTaken
        } else {
            return PhoneError.other(nil)
        }
    }
    
    @MainActor
    func googleSignIn() async throws -> SocialSignInResult {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("no firbase clientID found")
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        guard let rootViewController = scene?.windows.first?.rootViewController
        else {
            throw LocalError(message: "There is no root view controller!")
        }
        
        var result: GIDSignInResult!
        
        do {
            result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            )

        } catch {
            if let googlError = error as? GIDSignInError, 
                googlError.code == GIDSignInError.canceled {
                return .cancelled
            }
            
            throw error
        }
        
        let user = result.user
        
        guard let idToken = user.idToken?.tokenString else {
            throw LocalError(message: "Unexpected error occurred, please retry")
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken, accessToken: user.accessToken.tokenString
        )
        
        try await Auth.auth().signIn(with: credential)
        let authUser = Auth.auth().currentUser
        
        guard authUser?.phoneNumber != nil else {
            return .missingPhone
        }
        
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw LocalError(message: "Couldn't get token on Google Auth")
        }
        
        return .token(token)
    }
    
    func reauthenticate() async throws -> String {
        do {
            let result = try await Auth.auth().currentUser?.getIDTokenResult(forcingRefresh: true)
            guard let token = result?.token else {
                throw LocalError(message: "Didn't get a new token")
            }
            
            return token
        } catch {
            print("reauthentication failed =====", error )
            throw error
        }
    }
    
    func logout() async throws {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    func deleteUser() async throws {
        do {
            let user = Auth.auth().currentUser
            try await user?.delete()
        } catch {
            print("Error deleting user: %@", error)
        }
    }
    
    func appleSignIn() async throws -> SocialSignInResult {
        return try await withCheckedThrowingContinuation { continuation in
            appleSignIn.callback = { result in
                switch result {
                case .success(let auth):
                    guard let appleIDCredentials = auth.credential as? ASAuthorizationAppleIDCredential else {
                        continuation.resume(throwing: LocalError(message: "AppleAuthorization failed: AppleID credential not available"))
                        return
                    }
                    Task {
                        do {
                            let token = try await Authentication().appleAuth(
                                appleIDCredentials,
                                nonce: appleSignIn.nonce
                            )
                            
                            continuation.resume(returning: token)
                        } catch {
                            continuation.resume(throwing: LocalError(message: "AppleAuthorization failed: \(error)"))
                        }
                    }
                case .failure(let error):
                    switch error {
                    case .canceled:
                        continuation.resume(returning: .cancelled)
                    case .error(let error):
                        continuation.resume(throwing: LocalError(message: "AppleAuthorization failed: \(error)"))
                    }
                    
                }
            }
            
            appleSignIn.performRequests()
        }
    }
    
    fileprivate func appleAuth(
        _ appleIDCredential: ASAuthorizationAppleIDCredential,
        nonce: String?
    ) async throws -> SocialSignInResult {
        guard let nonce = nonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            throw LocalError(message: "Unable to fetch identity token")
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw LocalError(message: "Unable to serialize token string from data: \(appleIDToken.debugDescription)")
        }
        
        // 2.
        let credentials = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                        rawNonce: nonce,
                                                        fullName: appleIDCredential.fullName)
        
        do { // 3.
            try await Auth.auth().signIn(with: credentials)
            
            let authUser = Auth.auth().currentUser
            
            guard authUser?.phoneNumber != nil else {
                return .missingPhone
            }
            
            
            guard let token = try await Auth.auth().currentUser?.getIDToken() else {
                throw LocalError(message: "Couldn't get token on Google Auth")
            }
            
            return .token(token)
        }
        catch {
            print("FirebaseAuthError: appleAuth(appleIDCredential:nonce:) failed. \(error)")
            throw error
        }
    }
}

enum AuthError: Error {
    case canceled
    case error(Error)
    //    case message(String)
}

typealias AppleAuthCallback = (Result<ASAuthorization, AuthError>) -> Void

final class AppleSignIn: NSObject {
    var callback: AppleAuthCallback
    
    fileprivate static var currentNonce: String?
    
    var nonce: String? {
        Self.currentNonce ?? nil
    }
    
    init(callback: @escaping AppleAuthCallback = { _ in }) {
        self.callback = callback
    }
    
    func performRequests() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        Self.currentNonce = randomNonceString()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(Self.currentNonce!)
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

extension AppleSignIn: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.windows.first!
    }
}

extension AppleSignIn: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let err = error as? ASAuthorizationError {
            if err.code == .canceled || err.code == .unknown {
                callback(.failure(.canceled))
            } else {
                callback(.failure(.error(err)))
            }
        } else {
            callback(.failure(.error(error)))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        callback(.success(authorization))
    }
}

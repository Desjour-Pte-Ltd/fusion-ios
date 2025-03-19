import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseAnalytics

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var api: API
    @EnvironmentObject private var appRootManager: AppRootManager
    
    @State private var phone: String = ""
    @State private var code: String = "🇸🇬 +65"
    @FocusState var isPhoneFocused: Bool
    @State private var goToOTP: Bool = false
    @State private var goToLinkPhone: Bool = false
    @State private var verificationID: String = ""
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    private var phoneFieldActive: Bool {
        return phone != "" && isPhoneFocused
    }
    private var codeFieldActive: Bool {
        return phone.count == 8
    }
    
    private var tosText: (String) -> AttributedString =  { text in
        var string = AttributedString(text)
        string.font = .custom("Poppins-Regular", size: 14)
        string.foregroundColor = Color.text.black60
        
        return string
    }
    
    private var tosLink: (String) -> AttributedString =  { text in
        var string = text.underline()
        string.link = URL(string: Strings.tosLink)
        
        return string
    }
    
    private var phoneBorderColor: Color {
        if errorMessage != nil {
            return .red
        }
        
        return phoneFieldActive ? Color.text.black100 : Color(hex: "#E7EAEB")
    }
    
    private func track(_ error: (any Error)?) {
        var params: [String: Any] = [:]
        if let err = error {
            params["error"] = err.localizedDescription
        }
        Analytics.logEvent("AUTH_ERROR", parameters: params)
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    NavigationLink(isActive: $goToOTP) {
                        OtpView(countryCode:"+65", phoneNumber: phone, verificationID: verificationID)
                    } label: { }
                    NavigationLink(isActive: $goToLinkPhone) {
                        PhoneLinkingView()
                    } label: { }
                    Spacer()
                    Text("user_onboarding_phone_input_title")
                        .font(.custom("Poppins-SemiBold", size: 24))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                    Text("user_onboarding_phone_input_description")
                        .font(.custom("Poppins-Regular", size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(Color.text.black60)
                        .padding(.bottom, 32)
                    VStack {
                        Text("user_onboarding_phone_input_subtitle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.custom("Poppins-Medium", size: 16))
                            .foregroundStyle(errorMessage != nil ? .red : Color.text.black100)
                        HStack {
                            TextField("", text: $code) {
                                UIApplication.shared.endEditing()
                            }
                            .padding([.top, .bottom], 17)
                            .padding([.leading, .trailing], 10)
                            .frame(width: 82)
                            .disabled(true)
                            .focused($isPhoneFocused)
                            .font(.custom("Poppins-Regular", size: 14))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(codeFieldActive ? Color.text.black100 : Color(hex: "#E7EAEB"),
                                        lineWidth: 1))
                            TextField("profile_info_phone_number", text: $phone) {
                                UIApplication.shared.endEditing()
                            }
                            .keyboardType(.numberPad)
                            .padding([.top, .bottom], 17)
                            .onChange(of: phone, perform: { newValue in
                                errorMessage = nil
                            })
                            .padding([.leading, .trailing], 14)
                            .focused($isPhoneFocused)
                            .foregroundStyle(errorMessage != nil ? .red : Color.text.black100)
                            .font(.custom("Poppins-Regular", size: 14))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(phoneBorderColor,
                                        lineWidth: 1))
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    HStack {
                                        Spacer()
                                        Button("cta_done") {
                                            isPhoneFocused = false
                                        }
                                        .foregroundStyle(Color.primary.brand)
                                        .font(.custom("Poppins-Bold", size: 16))
                                    }
                                }
                            }
                        }
                        if errorMessage != nil {
                            Text(errorMessage?.i18n ?? "")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundStyle(.red)
                        }
                    }
                    Spacer()
                    Spacer()
                    AsyncButton(progressWidth: .infinity) {
                        try? await Authentication().logout()
                        let result = await Authentication().verify(phone: "+65" + phone)
                        switch result {
                        case .success(let verificationId):
                            UserDefaults.standard.set(verificationId, forKey: Keys.authVerificationID)
                            self.verificationID = verificationId
                            goToOTP = true
                            print("verificationID ====", verificationId)
                        case .failure(let error):
                            if case .incorrectPhone = error {
                                errorMessage = "user_onboarding_verification_otp_user_invalid"
                            } else {
                                 track(error)
                                errorMessage = "error_generic"
                            }
                            print(error.localizedDescription)
                        }
                    } label: {
                        Text("user_onboarding_phone_input_cta")
                            .frame(maxWidth: .infinity)
                            .font(.custom("Roboto-Bold", size: 16))
                        
                    }
                    .disabled(phone.isEmpty)
                    .buttonStyle(PrimaryButton())
                    Spacer()
                    Spacer()
                    HStack {
                        Rectangle()
                            .fill(Color.text.black20)
                            .frame(height: 1)
                        Text("user_onboarding_social_login_divider_message")
                            .foregroundStyle(Color.black.opacity(0.7))
                            .font(.custom("Poppins-Regular", size: 14))
                            .layoutPriority(1)
                        Rectangle()
                            .fill(Color.text.black20)
                            .frame(height: 1)
                    }
                    HStack(spacing: 12) {
                        Button {
                            loading = true
                            Task {
                                do {
                                    let result = try await Authentication().appleSignIn()
                                    
                                    switch result {
                                    case .token(let token):
                                        try await api.signIn(with: token)
                                        await MainActor.run {
                                            loading = false
                                            appRootManager.currentRoot = .main
                                        }
                                    case .missingPhone:
                                        await MainActor.run {
                                            loading = false
                                            goToLinkPhone = true
                                        }
                                    case .cancelled:
                                        await MainActor.run {
                                            loading = false
                                        }
                                        print("User cancelled login")
                                    }
                                    
                                } catch {
                                    await MainActor.run {
                                        loading = false
                                    }
                                    print("AppleAuthorization failed: \(error)")
                                    track(error)
                                    showAlert = true
                                }
                            }
                        } label: {
                            HStack {
                                Image("apple")
                                Text("Apple")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SocialButton())
                        Button {
                            loading = true
                            Task {
                                do {
                                    let result = try await Authentication().googleSignIn()
                                    switch result {
                                    case .token(let token):
                                        try await api.signIn(with: token)
                                        await MainActor.run {
                                            loading = false
                                            appRootManager.currentRoot = .main
                                        }
                                    case .missingPhone:
                                        await MainActor.run {
                                            loading = false
                                            goToLinkPhone = true
                                        }
                                    case .cancelled:
                                        await MainActor.run {
                                            loading = false
                                        }
                                        print("User cancelled login")
                                    }
                                } catch(let error) {
                                    await MainActor.run {
                                        loading = false
                                    }
                                    print("google auth error ====", error)
                                    track(error)
                                    showAlert = true
                                }
                            }
                        } label: {
                            HStack {
                                Image("google")
                                Text("user_onboarding_social_login_cta")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SocialButton())
                    }
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    HStack {
                        Text(tosText("ios_user_onboarding_tnc_1".i18n) + "\n" + tosLink("ios_user_onboarding_tnc_2".i18n))
                    }
                    .multilineTextAlignment(.center)
                    
                }
                .padding()
                .ignoresSafeArea(.keyboard)
                .navigationBarBackButtonHidden(true)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("user_onboarding_social_login_failed_title"),
                          message: Text("user_onboarding_social_login_failed_message"),
                          dismissButton: .default(Text("cta_okay")))
                        }
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
            if loading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.white)
            }
        }
        .animation(.default, value: loading)
    }
}

#Preview {
    AuthView()
        .environmentObject(AppRootManager())
}

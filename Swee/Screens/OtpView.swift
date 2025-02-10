import SwiftUI
import FirebaseAuth

struct LocalError: Error {
    let message: String?
}

let numberOfCharsInOTP = 6

struct OtpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var api: API
    @EnvironmentObject private var appRootManager: AppRootManager
    
    @State var countryCode: String
    @State var phoneNumber: String
    @State var verificationID: String
    
    @State private var otpText: String = ""
    @State private var goToCompleteProfile: Bool = false
    @FocusState private var isKeyboardShowing: Bool
    @State private var timeRemaining = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                NavigationLink(isActive: $goToCompleteProfile) {
                    CompleteProfileView()
                } label: {}
                Spacer()
                Text("user_onboarding_verification_title")
                    .font(.custom("Poppins-SemiBold", size: 24))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                Text("user_onboarding_verification_description".i18n(with: countryCode, phoneNumber))
                    .font(.custom("Poppins-Regular", size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.text.black60)
                    .padding(.bottom, 32)
                VStack {
                    Text("user_onboarding_verification_subtitle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.custom("Poppins-Medium", size: 16))
                    
                    HStack(spacing: 15) {
                        ForEach(0..<numberOfCharsInOTP, id: \.self) { index in
                            OTPTextBox(otpText: $otpText,
                                       showError: $showError,
                                       isKeyboardShowing: $isKeyboardShowing,
                                       index: index)
                        }
                    }
                    .background {
                        TextField("", text: $otpText.limit(numberOfCharsInOTP))
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .frame(width: 1, height: 1)
                            .opacity(0.001)
                            .blendMode(.screen)
                            .focused($isKeyboardShowing)
                            .onChange(of: otpText) { newValue in
                                showError = false
                            }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isKeyboardShowing.toggle()
                    }
                }
                HStack(spacing: 0) {
                    Text(showError ? errorMessage.i18n : "")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(.red)
                        .padding(.leading, 15)
                        .padding(.bottom, 16)
                        .frame(height: 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                AsyncButton(progressWidth: .infinity) {
                    // validate and navigate next
                    //                showError = true
                    isKeyboardShowing = false
                    do {
                        let token = try await Authentication().phoneSignIn(verificationID: verificationID, otp: otpText)
                        
                        print("token ====", token)
//                        UserDefaults.standard.set(token, forKey: Keys.authToken)
                        
                        let result = try await api.signIn(with: token)
                        switch result {
                        case .loggedIn:
                            appRootManager.currentRoot = .main
                        case .withoutName:
                            goToCompleteProfile = true
                        }
                    } catch {
                        defer {
                            showError = true
                        }
                        print("phone auth error ======", error)
                        guard let phoneError = error as? PhoneError else {
                            errorMessage = "error_generic"
                            return
                        }
                        
                        if case .wrongCode = phoneError {
                            errorMessage = "user_onboarding_verification_otp_error_invalid"
                        } else if case .numberIsTaken = phoneError {
                            errorMessage = "This phone number is registered to another account"
                        } else {
                            errorMessage = "error_generic"
                        }
                    }
                } label: {
                    Text("user_onboarding_verification_cta_from_phone_login")
                        .frame(maxWidth: .infinity)
                        .font(.custom("Roboto-Bold", size: 16))
                }
                .disabled(otpText.count != numberOfCharsInOTP)
                .buttonStyle(PrimaryButton())
                Spacer()
                Spacer()
                Spacer()
            }
            .padding()
            .ignoresSafeArea(.keyboard)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("cta_done") {
                            isKeyboardShowing = false
                        }
                        .foregroundStyle(Color.primary.brand)
                        .font(.custom("Poppins-Bold", size: 16))
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image("back_auth", bundle: .main)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if timeRemaining == 0 {
                            Task {
                                let result = await Authentication().verify(phone: countryCode + phoneNumber)
                                switch result {
                                case .success(let verificationId):
                                    UserDefaults.standard.set(verificationId, forKey: Keys.authVerificationID)
                                    self.verificationID = verificationId
                                    print("verificationID ====", verificationId)
                                case .failure(let error):
                                    print(error.localizedDescription)
                                    errorMessage = "error_generic"
                                    showError = true
                                }
                            }
                            timeRemaining = 20
                        }
                    } label: {
                        if timeRemaining == 0 {
                            Text("user_onboarding_verification_menu_item_resend_otp")
                                .frame(maxWidth: .infinity)
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: Color.gradient.primary,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        } else {
                            Text("user_onboarding_verification_menu_item_resend_otp_again".i18n + "user_onboarding_verification_menu_item_resend_otp_timer".i18n(with: timeRemaining))
                                .frame(maxWidth: .infinity)
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundStyle(Color.text.black60)
                                .onReceive(timer, perform: { _ in
                                    if timeRemaining > 0 {
                                        timeRemaining -= 1
                                    }
                                })
                        }
                    }
                    .disabled(timeRemaining > 0)
                }
            }
            .onWillAppear {
                print("received === \(verificationID)")
            }
        }
        .onAppear(perform: {
            isKeyboardShowing = true
        })
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
}

struct OTPTextBox: View {
    @Binding var otpText: String
    @Binding var showError: Bool
    var isKeyboardShowing: FocusState<Bool>.Binding
    @State var index: Int
    @State var boxText: String = ""
    
    var text: String {
        if otpText.count > index {
            let startIndex = otpText.startIndex
            let charIndex = otpText.index(startIndex, offsetBy: index)
            let charToString = String(otpText[charIndex])
            return charToString
        } else {
            return " "
        }
    }
    
    var isActive: Bool {
        return ((isKeyboardShowing.wrappedValue && otpText.count == index) || otpText.count > index)
    }
    
    var borderColor: Color {
        if otpText.count == numberOfCharsInOTP && showError {
            return .red
        }
        return isActive ? Color.text.black100 : .text.black20
    }
    
    var body: some View {
        ZStack {
            TextField("", text: $boxText)
                .foregroundStyle(showError ? Color.red : Color.text.black100)
                .onChange(of: otpText) { newValue in
                    boxText = text
                }
                .allowsHitTesting(false)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: 70)
        .font(.custom("Poppins-SemiBold", size: 24))
        .background {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
                .animation(.easeInOut, value: isActive)
        }
    }
}

extension Binding where Value == String {
    func limit(_ length: Int) -> Self {
        if self.wrappedValue.count > length {
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.prefix(length))
            }
        }
        return self
    }
}

#Preview {
    OtpView(countryCode: "+65", phoneNumber: "86446585", verificationID: "fakeID")
        .environmentObject(AppRootManager())
}

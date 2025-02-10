import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct PhoneLinkingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var api: API
    @EnvironmentObject private var appRootManager: AppRootManager
    
    @State private var phone: String = ""
    @State private var code: String = "🇸🇬 +65"
    @FocusState var isPhoneFocused: Bool
    @State private var goToOTP: Bool = false
    @State private var verificationID: String = ""
    @State private var loading = false
    @State private var errorMessage: String?
    
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
        string.link = URL(string: "https://fusion-core-stg.s3.ap-southeast-1.amazonaws.com/terms_and_condition.pdf")
        
        return string
    }
    
    private var phoneBorderColor: Color {
        if errorMessage != nil {
            return .red
        }
        
        return phoneFieldActive ? Color.text.black100 : Color(hex: "#E7EAEB")
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    NavigationLink(isActive: $goToOTP) {
                        OtpView(countryCode:"+65", phoneNumber: phone, verificationID: verificationID)
                    } label: {
                        
                    }
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
                            TextField("user_onboarding_phone_input_hint", text: $phone) {
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
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button {
                                        Task {
                                            try? await Authentication().logout()
                                        }
                                        dismiss()
                                    } label: {
                                        Image("back_auth", bundle: .main)
                                    }
                                }
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
                    .padding(.bottom, 32)
                    AsyncButton(progressWidth: .infinity) {
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
                                errorMessage = "error_generic"
                            }
                            print(error.localizedDescription)
                        }
                    } label: {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .font(.custom("Roboto-Bold", size: 16))
                        
                    }
                    .disabled(phone.isEmpty)
                    .buttonStyle(PrimaryButton())
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    HStack {
                        Text(tosText("By continuing, you accept Green App's \n") + tosLink("Terms and Condition"))
                    }
                    .multilineTextAlignment(.center)
                    
                }
                .padding()
                .ignoresSafeArea(.keyboard)
                .navigationBarBackButtonHidden(true)
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
    PhoneLinkingView()
        .environmentObject(AppRootManager())
}

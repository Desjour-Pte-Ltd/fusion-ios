import SwiftUI

struct EditPhoneView: View {
    @Environment(\.country) private var country
    @State var phone: String = ""
    private var code: String {
        return "\(country.wrappedValue.flagEmoji) \(country.wrappedValue.phoneCode)"
    }
    @FocusState var isPhoneFocused: Bool
    @State private var goToOTP: Bool = false
    @State private var verificationID: String = ""
    
    private var phoneFieldActive: Bool {
        return phone != "" && isPhoneFocused
    }
    private var codeFieldActive: Bool {
        return phone.count == 8
    }
    
    var body: some View {
        VStack {
            CustomNavLink(isActive: $goToOTP, destination: EditOtpView(verificationID: verificationID), label: {})
            Text("user_onboarding_phone_input_subtitle")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.custom("Poppins-Medium", size: 16))
            HStack {
                Text(code)
                .padding([.top, .bottom], 17)
                .padding([.leading, .trailing], 10)
                .frame(width: 82)
                .font(.custom("Poppins-Regular", size: 14))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(codeFieldActive ? Color.text.black100 : Color(hex: "#E7EAEB"),
                            lineWidth: 1))
                .overlay {
                    selectCountryMenu(size: .init(width: 82, height: 50)) { country in
                        self.country.wrappedValue = country
                    }
                }
                TextField("user_onboarding_phone_input_hint", text: $phone) {
                    UIApplication.shared.endEditing()
                }
                .keyboardType(.numberPad)
                .padding([.top, .bottom], 17)
                .padding([.leading, .trailing], 14)
                .focused($isPhoneFocused)
                .font(.custom("Poppins-Regular", size: 14))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(phoneFieldActive ? Color.text.black100 : Color(hex: "#E7EAEB"),
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
            Spacer()
            AsyncButton(progressWidth: .infinity) {
                let result = await Authentication().verify(phone: country.wrappedValue.phoneCode + phone)
                switch result {
                case .success(let verificationId):
                    UserDefaults.standard.set(verificationId, forKey: Keys.authVerificationID)
                    self.verificationID = verificationId
                    goToOTP = true
                    print("verificationID ====", verificationId)
                case .failure(let error):
                    print(error.localizedDescription)
                    // @todo handle error
                }
            } label: {
                Text("user_onboarding_phone_input_cta")
                    .frame(maxWidth: .infinity)
                    .font(.custom("Roboto-Bold", size: 16))
                
            }
            .disabled(phone.isEmpty)
            .buttonStyle(PrimaryButton())
        }
        .padding()
        .customNavigationTitle("user_onboarding_phone_input_hint")
    }
}

#Preview {
    CustomNavView {
        EditPhoneView(phone: "12345671")
    }
}

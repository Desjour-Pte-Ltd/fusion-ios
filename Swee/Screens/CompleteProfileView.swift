import SwiftUI

struct CompleteProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State var fullName: String = Authentication().name ?? ""
    @State var referralCode: String = ""
    @FocusState private var isKeyboardShowing: Bool
    @FocusState private var isReferralKeyboardShowing: Bool
    @State private var errorMessage: String?
    @State private var referralErrorMessage: String?
    
    @EnvironmentObject private var appRootManager: AppRootManager
    @EnvironmentObject var api: API
    
    private var nameFieldActive: Bool {
        return fullName != "" || isKeyboardShowing
    }
    
    private var referralFieldActive: Bool {
        return referralCode != "" || isReferralKeyboardShowing
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("user_onboarding_full_name_input_title")
                    .font(.custom("Poppins-SemiBold", size: 24))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                Text("user_onboarding_full_name_input_description")
                    .font(.custom("Poppins-Regular", size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.text.black60)
                    .padding(.bottom, 32)
                VStack {
                    Text("user_onboarding_full_name_input_subtitle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.custom("Poppins-Medium", size: 16))
                    TextField("user_onboarding_full_name_input_hint", text: $fullName) {
                        UIApplication.shared.endEditing()
                    }
                    .padding([.top, .bottom], 17)
                    .padding([.leading, .trailing], 14)
                    .focused($isKeyboardShowing)
                    .font(.custom("Poppins-Regular", size: 14))
                    .submitLabel(.done)
                    .onChange(of: fullName, perform: { newValue in
                        errorMessage = nil
                    })
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(nameFieldActive ? Color.primary.brand : Color(hex: "#E7EAEB"),
                                lineWidth: nameFieldActive ? 2 : 1))
                    if errorMessage != nil {
                        Text(errorMessage?.i18n ?? "")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundStyle(.red)
                    }
                    Text("user_onboarding_referral_code_input_subtitle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.custom("Poppins-Medium", size: 16))
                    TextField("user_onboarding_referral_code_input_hint", text: $referralCode) {
                        UIApplication.shared.endEditing()
                    }
                    .padding([.top, .bottom], 17)
                    .padding([.leading, .trailing], 14)
                    .font(.custom("Poppins-Regular", size: 14))
                    .submitLabel(.done)
                    .focused($isReferralKeyboardShowing)
                    .onChange(of: referralCode, perform: { newValue in
                        referralErrorMessage = nil
                    })
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(referralFieldActive ? Color.primary.brand : Color(hex: "#E7EAEB"),
                                lineWidth: referralFieldActive ? 2 : 1))
                    if referralErrorMessage != nil {
                        Text(referralErrorMessage)
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundStyle(.red)
                    }

                }
                .padding([.bottom], 70)
                AsyncButton(progressWidth: .infinity) {
                    errorMessage = nil
                    do {
                        try await api.completeUser(with: fullName.trimmingCharacters(in: .whitespaces), and: referralCode.trimmingCharacters(in: .whitespaces))
                        
                        appRootManager.currentRoot = .main
                    } catch(let error) {
                        print("complete profile error =====", error)
                        if let apiError = error as? APIError {
                            if case .incorrectBody = apiError {
                                referralErrorMessage = "user_onboarding_referral_error"
                            } else {
                                errorMessage = "error_generic"
                            }
                        }
                    }
                } label: {
                    Text("cta_complete")
                        .frame(maxWidth: .infinity)
                        .font(.custom("Roboto-Bold", size: 16))
                }
                .disabled(fullName.trimmingCharacters(in: .whitespaces) == "")
                .buttonStyle(PrimaryButton())
                Spacer()
                Spacer()
                Spacer()
            }
            .padding()
            .ignoresSafeArea(.keyboard)
            .navigationBarBackButtonHidden(true)
        }
        .onAppear(perform: {
            isKeyboardShowing = true
        })
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
}

#Preview {
    CompleteProfileView()
        .environmentObject(AppRootManager())
        .environmentObject(API())
}

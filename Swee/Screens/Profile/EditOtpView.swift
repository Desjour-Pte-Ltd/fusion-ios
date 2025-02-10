import SwiftUI

struct EditOtpView: View {
    @Environment(\.dismiss) private var dismiss
    @State var verificationID: String
    @State private var otpText: String = ""
    @FocusState private var isKeyboardShowing: Bool
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        VStack {
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
            Spacer()
            AsyncButton(progressWidth: .infinity) {
//                // validate and navigate next
//                //                showError = true
//                isKeyboardShowing = false
//                do {
//                    let token = try await Authentication().phoneSignIn(verificationID: verificationID, otp: otpText)
//                    
//                    print("token ====", token)
//                } catch {
//                    defer {
//                        showError = true
//                    }
//                    print("phone auth error ======", error)
//                    guard let phoneError = error as? PhoneError else {
//                        errorMessage = "Something went wrong"
//                        return
//                    }
//                    
//                    if case .wrongCode = phoneError {
//                        errorMessage = "Wrong code, please try again"
//                    } else {
//                        errorMessage = "Something went wrong. Please try again"
//                    }
//                }
            } label: {
                Text("Confirm")
                    .frame(maxWidth: .infinity)
                    .font(.custom("Roboto-Bold", size: 16))
            }
            .disabled(otpText.count != numberOfCharsInOTP)
            .buttonStyle(PrimaryButton())
        }
        .padding()
        .customNavigationTitle("profile_info_verification_title")
    }
}

#Preview {
    CustomNavView {
        EditOtpView(verificationID: "fakeID")
    }
}

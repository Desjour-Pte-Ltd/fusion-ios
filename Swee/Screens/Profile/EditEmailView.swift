import SwiftUI

struct EditEmailView: View {
    @EnvironmentObject private var api: API
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabIsShown) private var tabIsShown
    @State var email: String
    @State private var showError = false
    @FocusState private var isKeyboardShowing: Bool
    private var emailFieldActive: Bool {
        return email != "" || isKeyboardShowing
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("profile_settings_email_id_hint")
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundStyle(Color.text.black80)
            TextField("profile_settings_email_id_hint", text: $email)
                .padding([.top, .bottom], 17)
                .padding([.leading, .trailing], 14)
                .focused($isKeyboardShowing)
                .font(.custom("Poppins-Regular", size: 16))
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(emailFieldActive ? Color.primary.brand : Color(hex: "#E7EAEB"),
                            lineWidth: emailFieldActive ? 2 : 1))
            if showError {
                Text("Check your email format")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundStyle(.red)
            }
            Spacer()
            AsyncButton(progressWidth: .infinity) {
                guard validateEmail(email) else {
                    showError = true
                    return
                }
                
                showError = false
                do {
                    let _ = try await api.update(email: email)
                    dismiss()
                } catch {
                    self.email = api.user?.email ?? email
                }
            } label: {
                Text("Update")
                    .frame(maxWidth: .infinity)
                    .font(.custom("Roboto-Bold", size: 16))
            }
            .disabled(email.trimmingCharacters(in: .whitespaces) == "")
            .buttonStyle(PrimaryButton())
        }
        .onChange(of: email, perform: { newValue in
            showError = false
        })
        .padding()
        .customNavigationTitle("Email ID")
        .onAppear(perform: {
            tabIsShown.wrappedValue = false
        })
    }
    
    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    EditEmailView(email: "darth@vader.com")
}

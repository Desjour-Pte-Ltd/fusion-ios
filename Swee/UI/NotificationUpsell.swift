import SwiftUI

struct NotificationUpsell: View {
    @Binding var hide: Bool
    @EnvironmentObject private var pushNotificationManager: PushNotificationManager
    
    private let bullets = ["notification_permission_dialog_context_1", "notification_permission_dialog_context_2", "notification_permission_dialog_context_3"]
    private func bullet(_ text: String) -> some View {
        return HStack {
            Text("•")
            Text(text.i18n)
        }
        .font(.custom("Poppins-Medium", size: 12))
        .foregroundStyle(Color.text.black60)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var body: some View {
        VStack {
            Image("alert-img")
                .padding(.bottom, 16)
            Text("notification_permission_dialog_title")
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundStyle(Color.text.black100)
                .padding(.bottom, 8)
            Text("notification_permission_dialog_description")
                .font(.custom("Poppins-Medium", size: 12))
                .foregroundStyle(Color.text.black60)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)
            VStack {
                Text("notification_permission_dialog_context_title")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundStyle(Color.text.black80)
                    .padding(.bottom, 16)
                VStack {
                    ForEach(bullets, id: \.self) { text in
                        bullet(text)
                    }
                }
                .padding([.leading, .trailing], 50)
                .padding(.bottom, 38)
            }
            AsyncButton(progressWidth: .infinity) {
                await pushNotificationManager.askForPermission()
                hide.toggle()
            } label: {
                Text("notification_permission_dialog_cta_allow")
                    .frame(maxWidth: .infinity)
                    .font(.custom("Roboto-Bold", size: 16))
                
            }
            .buttonStyle(PrimaryButton())
            Button {
                hide.toggle()
            } label: {
                Text("notification_permission_dialog_cta_later")
                    .frame(maxWidth: .infinity)
                    .font(.custom("Roboto-Bold", size: 16))
                    .foregroundColor(Color.text.black80)
            }
            .padding()
        }
    }
}

import SwiftUI

struct RedemptionCompletedView: View {
    struct Model {
        let header: String
        let title: String
        let description: String
        let actionTitle: String
    }
    var model: Model
    var tint: Color = Color.primary.brand
    var closure: (() -> Void)?
    
    var body: some View {
        VStack {
            Text(model.header.i18n)
                .font(.custom("Poppins-SemiBold", size: 24))
                .foregroundStyle(Color.text.black100)
                .padding(.bottom, 32)
            Image("checkout-success")
                .resizable()
                .scaledToFill()
                .frame(width: 164, height: 136)
            Text(model.title.i18n)
                .font(.custom("Poppins-SemiBold", size: 20))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 39)
                .foregroundStyle(Color.text.black100)
            Text(model.description.i18n)
                .font(.custom("Poppins-SemiBold", size: 16))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 39)
                .foregroundStyle(Color.text.black60)
            Button {
                closure?()
            } label: {
                HStack {
                    Spacer()
                    Text(model.actionTitle.i18n)
                        .font(.custom("Roboto-Bold", size: 16))
                    Spacer()
                }
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .contentShape(Capsule())
            }
            .buttonStyle(OutlineButton(strokeColor: tint))
            .padding(.top, 44)
            .padding(.bottom, 16)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .frame(maxWidth: .infinity)
    }
}

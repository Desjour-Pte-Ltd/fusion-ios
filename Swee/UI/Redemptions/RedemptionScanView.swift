import SwiftUI

struct RedemptionScanView: View {
    struct Model {
        let header: String
        let title: String
        let qr: Image?
        let description: String
        let actionTitle: String
        var showCurrentTime: Bool = false
    }
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var currentTime: String = Date().formatted(date: .omitted, time: .standard)
    var model: Model
    var tint: Color = Color.primary.brand
    var closure: () async throws -> Void
    
    var body: some View {
        VStack {
            Text(model.header.i18n)
                .font(.custom("Poppins-SemiBold", size: 24))
                .foregroundStyle(Color.text.black100)
            if model.showCurrentTime {
                Text(currentTime)
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundStyle(Color.secondary.brand)
                    .padding(.top, 2)
            }
            model.qr
                .padding(.bottom, 8)
            Text(model.title.i18n)
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundStyle(Color.text.black100)
            Text(model.description.i18n)
                .font(.custom("Poppins-Medium", size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.text.black60)
                .padding(.bottom, 37)
            AsyncButton(progressWidth: .infinity, progressTint: tint) {
                try? await closure()
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
            .padding(.bottom, 16)
            .onReceive(timer, perform: { _ in
                currentTime = Date().formatted(date: .omitted, time: .standard)
            })
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

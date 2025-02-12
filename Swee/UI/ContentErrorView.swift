import SwiftUI

struct ContentErrorView: View {
    let retry: () async -> Void
    
    var body: some View {
        VStack {
            Image("refresh")
            Text("api_error_loading_content_failed")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundStyle(Color.text.black80)
            AsyncButton(progressTint: .black) {
                await retry()
            } label: {
                Text("cta_retry")
                    .font(.custom("Poppins-Bold", size: 16))
                    .foregroundStyle(Color.primary.brand)
            }
            .padding(.top, 12)
        }
        .padding(.vertical, 54)
        .frame(maxWidth: .infinity)
        .background(Color.text.black10)
    }
}

#Preview {
    ContentErrorView {}
}

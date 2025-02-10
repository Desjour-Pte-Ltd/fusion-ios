import SwiftUI

struct StateView: View {
    enum Images {
        case success
        case error
        case custom(String)
        
        var image: Image {
            switch self {
            case .success:
                Image("checkout-success")
            case .error:
                Image("error")
            case .custom(let imageName):
                Image(imageName)
            }
        }
    }
    
    let image: Images
    let title: String?
    let description: String?
    let buttonTitle: String
    let buttonAction: () async -> Void
    
    
    var body: some View {
        VStack {
            image.image
            if let title = title {
                Text(title.i18n)
                    .font(.custom("Poppins-Medium", size: 24))
            }
            if let description = description {
                Text(description.i18n)
                    .font(.custom("Poppins-Medium", size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.text.black40)
                    .padding(.bottom, 57)
            }
            AsyncButton(progressWidth: .infinity) {
                await buttonAction()
            } label: {
                HStack {
                    Text(buttonTitle.i18n)
                        .font(.custom("Roboto-Bold", size: 16))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButton())
        }
        .padding(.horizontal, 24)
    }
}

extension StateView {
    static func error(title: String = "error_generic", description: String = "error_generic_home", buttonTitle: String = "error_home_cta", buttonAction: @escaping () async -> Void) -> StateView {
        StateView(image: .error,
                  title: title,
                  description: description,
                  buttonTitle: buttonTitle) {
            await buttonAction()
        }
    }
}

#Preview {
    StateView.error {
        
    }
}

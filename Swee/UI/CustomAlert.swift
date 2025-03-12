import SwiftUI
import ConfettiSwiftUI

struct CustomAlert: View {
    struct Data: Equatable {
        struct Style: Equatable {
            let width: CGFloat
            let titleFont: Font
            let messageFont: Font
            let mainButtonColor: Color
            let cornerRadius: CGFloat
            let image: Image?
            
            static func defaultStyle(width: CGFloat = .infinity,
                                     titleFont: Font = .custom("Poppins-SemiBold", size: 18),
                                     messageFont: Font = .custom("Poppins-Regular", size: 14),
                                     mainButtonColor: Color = .error,
                                     cornerRadius: CGFloat = 4,
                                     image: Image? = nil) -> Self {
                .init(width: width,
                      titleFont: titleFont,
                      messageFont: messageFont,
                      mainButtonColor: mainButtonColor,
                      cornerRadius: cornerRadius,
                      image: image)
            }
        }
        let title: String
        let message: String
        let buttonTitle: String
        var cancelTitle: String? = nil
        var showConfetti: Bool = false
        var style: Style? = nil
        let action: EquatableAsyncVoidClosure
    }
    
    private var dataStyle: Data.Style {
        return data.style ?? .defaultStyle()
    }
    
    @Binding var isActive: Bool
    @State private var confettiTrigger: Int = 0
    var data: Data
    
    var body: some View {
        ZStack {
            if isActive {
                Color(.black)
                    .opacity(0.5)
                    .onTapGesture {
                        close()
                    }
                    .transition(.opacity)
                ZStack(alignment: .top) {
                    VStack {
                        Text(data.title)
                            .font(dataStyle.titleFont)
                            .foregroundStyle(Color.text.black100)
                            .padding()
                        
                        Text(data.message)
                            .font(dataStyle.messageFont)
                            .foregroundStyle(Color.text.black60)
                            .multilineTextAlignment(.center)
                        
                        AsyncButton(progressWidth: .infinity) {
                            try? await data.action.closure()
                            close()
                        } label: {
                            Text(data.buttonTitle)
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .buttonStyle(PrimaryButton(backgroundColor: dataStyle.mainButtonColor))
                        if let cancelTitle = data.cancelTitle {
                            Button {
                                close()
                            } label: {
                                Text(cancelTitle)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundStyle(Color.text.black60)
                            }
                            .padding(.bottom, 24)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                    .padding(.top, dataStyle.image != nil ? 16 : 0)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: dataStyle.cornerRadius))
                    .shadow(radius: 20)
                    .padding(dataStyle.width == .infinity ? 30 : 0)
                    .frame(width: dataStyle.width)
                    .transition(.flipFromBottom.combined(with: .opacity))
                    .onAppear {
                        if data.showConfetti {
                            confettiTrigger += 1
                        }
                    }
                    if let image = dataStyle.image {
                        image
                            .padding(.top, -20)
                    }
                }
            }
        }
        .confettiCannon(trigger: $confettiTrigger, num: 40)
        .animation(.spring(duration: 0.2), value: isActive)
        .ignoresSafeArea()
    }
    
    func close() {
        withAnimation(.spring()) {
            isActive = false
        }
    }
}

struct CustomAlert_Previews: PreviewProvider {
    static var previews: some View {
        CustomAlert(isActive: .constant(false), data: .init(title: "Delete?",
                                message: "This will delete all your data",
                                buttonTitle: "Delete",
                                cancelTitle: "Keep my account",
                                action: .init(closure: {}))
        )
    }
}

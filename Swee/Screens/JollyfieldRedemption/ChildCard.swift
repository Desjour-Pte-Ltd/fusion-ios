import SwiftUI

struct ChildCard: View {
    var child: Child
    var sessionOngoing: Bool
    var alottedTime: TimeInterval
    var isSelected: Bool
    var onButtonTap: (Child) -> Void
    
    var buttonCTAText: String {
        guard isSelected else {
            return "redemption_select_child_cta"
        }
        
        return sessionOngoing ?
        "redemption_time_remaining".i18n(with: alottedTime.toString()) :
        "redemption_time_allotted".i18n(with: alottedTime.toString())
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(child.name)
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundStyle(Color.text.black80)
            Button {
               onButtonTap(child)
            } label: {
                HStack {
                    Spacer()
                    Text(buttonCTAText.i18n)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundStyle(isSelected ? Color.primary.dark : Color.text.black100)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(buttonOutline(isSelected))
            .buttonStyle(EmptyStyle())
        }
        .padding()
        .background(selectedOutline(isSelected))
        .background(.white)
    }
    
    func buttonOutline(_ isSelected: Bool) -> AnyView {
        if isSelected {
            return AnyView(RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(Color.primary.lighter.opacity(0.5))
            )
        } else {
            return AnyView(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 1))
                .foregroundStyle(Color.text.black100)
            )
        }
    }
    
    func selectedOutline(_ isSelected: Bool) -> AnyView {
        if isSelected && !sessionOngoing {
            return AnyView(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style:  StrokeStyle(lineWidth: 1))
                .foregroundStyle(Color.primary.brand))
        } else {
            return AnyView(RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1))
        }
    }
}

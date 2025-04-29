import SwiftUI

enum SelectCountryMenuMode {
    case phoneCode
    case countryName
}

func selectCountryMenu(with mode: SelectCountryMenuMode = .phoneCode, size: CGSize, onSelection: @escaping (Country) -> Void) -> Menu<AnyView, AnyView> {
    
    return Menu {
        ForEach(Country.allCases, id: \.self) { location in
            Button {
                onSelection(location)
            } label: {
                let label = mode == .phoneCode ? "\(location.flagEmoji) \(location.name) \(location.phoneCode)" : "\(location.flagEmoji) \(location.name)"
                Label(label, systemImage: "")
            }
        }
        .anyView
    } label: {
        Label("", systemImage: "")
            .blendMode(.destinationOver)
            .frame(width: size.width, height: size.height)
            .anyView
    }
}

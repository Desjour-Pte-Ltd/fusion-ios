import Foundation
import SwiftUI

struct CustomNavBarTitlePreferenceKey: PreferenceKey {
    static var defaultValue: String = ""
    
    static func reduce(value: inout String, nextValue: () -> String) {
        value = nextValue()
    }
}

struct CustomNavBarBackButtonHiddenPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

struct CustomNavBarHiddenPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

struct CustomNavLeadingItemPreferenceKey: PreferenceKey {
    static var defaultValue: EquatableViewContainer = EquatableViewContainer(view: AnyView(Text("")))
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

struct CustomNavTrailingItemPreferenceKey: PreferenceKey {
    static var defaultValue: EquatableViewContainer = EquatableViewContainer(view: AnyView(Text("")))
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

struct CustomNavBottomSheetData: PreferenceKey {
    static var defaultValue: BottomSheetData = .init(view: Text("").equatable, hidden: .constant(true))
    
    static func reduce(value: inout BottomSheetData, nextValue: () -> BottomSheetData) {
        value = nextValue()
    }
}

struct CustomAlertData: PreferenceKey, Equatable {
    @Binding var isActive: Bool
    let title: String
    let message: String
    let buttonTitle: String
    let cancelTitle: String?
    let showConfetti: Bool
    let style: CustomAlert.Data.Style?
    let action: EquatableAsyncVoidClosure
    
    static var defaultValue: CustomAlertData = .init(isActive: .constant(false),
                                                     title: "",
                                                     message: "",
                                                     buttonTitle: "",
                                                     cancelTitle: "",
                                                     showConfetti: false,
                                                     style: .defaultStyle(),
                                                     action: .init(closure: {}))
    
    static func reduce(value: inout CustomAlertData, nextValue: () -> CustomAlertData) {
        value = nextValue()
    }
}

extension View {
    func customNavigationTitle(_ title: String) -> some View {
        preference(key: CustomNavBarTitlePreferenceKey.self, value: title)
    }
    
    func customNavigationBackButtonHidden(_ hidden: Bool) -> some View {
        preference(key: CustomNavBarBackButtonHiddenPreferenceKey.self, value: hidden)
    }
    
    func customNavBarHidden(_ hidden: Bool) -> some View {
        preference(key: CustomNavBarHiddenPreferenceKey.self, value: hidden)
    }
    
    func customNavLeadingItem(@ViewBuilder _ content: () -> some View) -> some View {
        preference(key: CustomNavLeadingItemPreferenceKey.self, value: EquatableViewContainer(view: AnyView(content())))
    }
    
    func customNavTrailingItem(@ViewBuilder _ content: () -> some View) -> some View {
        preference(key: CustomNavTrailingItemPreferenceKey.self, value: EquatableViewContainer(view: AnyView(content())))
    }
    
    func customBottomSheet(hidden: Binding<Bool>, @ViewBuilder _ content: () -> some View) -> some View {
        preference(key: CustomNavBottomSheetData.self, value: BottomSheetData(view: content().equatable, hidden: hidden))
    }
        
    func customAlert(isActive: Binding<Bool>, data: CustomAlert.Data) -> some View {
        return preference(key: CustomAlertData.self, value: .init(isActive: isActive,
                                                                  title: data.title,
                                                                  message: data.message,
                                                                  buttonTitle: data.buttonTitle,
                                                                  cancelTitle: data.cancelTitle,
                                                                  showConfetti: data.showConfetti,
                                                                  style: data.style,
                                                                  action: data.action))
    }
}


struct EquatableViewContainer: Equatable {
    let id = UUID().uuidString
    let view: AnyView
    
    static func == (lhs: EquatableViewContainer, rhs: EquatableViewContainer) -> Bool {
        return lhs.id == rhs.id
    }
}

struct EquatableAsyncVoidClosure: Equatable {
    let id = UUID().uuidString
    let closure: () async throws -> Void
    
    static func == (lhs: EquatableAsyncVoidClosure, rhs: EquatableAsyncVoidClosure) -> Bool {
        return lhs.id == rhs.id
    }
}

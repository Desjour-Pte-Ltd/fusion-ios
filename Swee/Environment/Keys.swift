import SwiftUI

private struct CurrentTabKey: EnvironmentKey {
    static let defaultValue: Binding<Tabs> = .constant(.home)
}

private struct CurrentCountryKey: EnvironmentKey {
    static let defaultValue: Binding<Country> = .constant(.Singapore)
}

struct BottomSheetData: Equatable {
    var view: EquatableViewContainer
    var hidden: Binding<Bool> = .constant(true)
}

struct BottomSheetContentKey: EnvironmentKey {
    static let defaultValue: Binding<BottomSheetData> = .constant(.init(view: EquatableViewContainer(view: AnyView(Text("")))))
}

private struct SessionActiveKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(true)
}

private struct TabVisibilityKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(true)
}

private struct NavViewKey: EnvironmentKey {
    static let defaultValue: Binding<UINavigationController?> = .constant(nil)
}

private struct RouteKey: EnvironmentKey {
    static let defaultValue: Binding<Route?> = .constant(nil)
}

private struct DeeplinkKey: EnvironmentKey {
    static let defaultValue: Binding<String?> = .constant(nil)
}

private struct FCMTokenKey: EnvironmentKey {
    static let defaultValue: Binding<String?> = .constant(nil)
}

extension EnvironmentValues {
    var currentTab: Binding<Tabs> {
        get { self[CurrentTabKey.self] }
        set { self[CurrentTabKey.self] = newValue }
    }
    
    var tabIsShown: Binding<Bool> {
        get { self[TabVisibilityKey.self] }
        set { self[TabVisibilityKey.self] = newValue }
    }
    
    var goToActiveSession: Binding<Bool> {
        get { self[SessionActiveKey.self] }
        set { self[SessionActiveKey.self] = newValue }
    }
    
    var bottomSheetData: Binding<BottomSheetData> {
        get { self[BottomSheetContentKey.self] }
        set { self[BottomSheetContentKey.self] = newValue }
    }
    
    var navView: Binding<UINavigationController?> {
        get { self[NavViewKey.self] }
        set { self[NavViewKey.self] = newValue }
    }
    
    var route: Binding<Route?> {
        get { self[RouteKey.self] }
        set { self[RouteKey.self] = newValue }
    }
    
    var deeplink: Binding<String?> {
        get { self[DeeplinkKey.self] }
        set { self[DeeplinkKey.self] = newValue }
    }
    
    var country: Binding<Country> {
        get { self[CurrentCountryKey.self] }
        set { self[CurrentCountryKey.self] = newValue }
    }
    
    var fcmToken: Binding<String?> {
        get { self[FCMTokenKey.self] }
        set { self[FCMTokenKey.self] = newValue }
    }
}

extension Binding: Equatable where Value: Equatable {
    public static func == (lhs: Binding<Value>, rhs: Binding<Value>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

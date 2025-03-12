import SwiftUI
import UniformTypeIdentifiers
import SDWebImageSwiftUI

struct ProfileView: View {
    struct RowData {
        enum Description {
            typealias Request = () async throws -> String
            case text(String)
            case request(Request)
        }
        let title: String
        let description: Description?
        let leadingIcon: Image?
        let trailingIcon: Image?
        let action: () -> Void
        let tint: Color?

        init(title: String, description: Description? = nil, leadingIcon: Image? = nil, trailingIcon: Image = Image("forward"), tint: Color? = nil, action: @escaping () -> Void) {
            self.title = title
            self.description = description
            self.leadingIcon = leadingIcon
            self.trailingIcon = trailingIcon
            self.tint = tint
            self.action = action
        }
    }
    
    @EnvironmentObject private var api: API
    @EnvironmentObject private var appRootManager: AppRootManager
    @Environment(\.tabIsShown) private var tabIsShown
    @Environment(\.fcmToken) private var fcmToken
    @Environment(\.openURL) var openURL
    @EnvironmentObject private var activeSession: ActiveSession

    
    @State private var profileProgress: Double = 0.6
    @State private var sections: [[RowData]] = []
    @State private var showDeleteProfileAlert = false
    @State private var showAlert = false
    @State private var showCompleteProfileBanner: Bool = false
    @State private var alertData: CustomAlert.Data = .init(title: "",
                                                           message: "",
                                                           buttonTitle: "",
                                                           cancelTitle: "",
                                                           action: .init(closure: {}))
    @State private var goToChildren: Bool = false
    @State private var goToEmail: Bool = false
    @State private var goToDOB: Bool = false
    @State private var goToGender: Bool = false
    
    func setupSections() {
        sections = [
            [
                .init(title: "Email ID", description: .text(api.user?.email ?? "Add email ID"), leadingIcon: Image("mail")) {
                    goToEmail = true
                },
                .init(title: "Date of birth", description: .text(api.user?.birthDayString ?? "Add date"), leadingIcon: Image("calendar")) {
                    goToDOB = true
                },
                .init(title: "Gender", description: .text(api.user?.gender.toString ?? "Add gender"), leadingIcon: Image("gender")) {
                    goToGender = true
                },
            ],
            [
                .init(title: "Child", description: .request({
                    let children = try await api.children()
                    return children.isEmpty ? "No info added" : children.map { $0.name }.joined(separator: ", ")
                }), leadingIcon: Image("person-add")) {
                    goToChildren = true
                },
            ],
            [
                .init(title: "Help Center", leadingIcon: Image("help")) {
                    openURL(URL(string: Strings.helpLink)!)
                },
                .init(title: "Terms & Conditions", leadingIcon: Image("receipt")) {
                    openURL(URL(string: Strings.tosLink)!)
                },
                .init(title: "Rate our app", leadingIcon: Image("raiting")) {
                    openURL(URL(string: Strings.rateAppLink)!)
                },
            ],
            [
                .init(title: "Logout", trailingIcon: Image("logout")) {
                    showAlert = true
                    alertData = .init(title: "Logout?",
                                      message: "Do you want to log out from the app, you ll have to sign in again",
                                      buttonTitle: "Log out", 
                                      cancelTitle: "Stay In",
                                      action: .init(closure: {
                        await api.signOut()
                        appRootManager.currentRoot = .authentication
                    }))
                },
            ],
            [
                .init(title: "Delete profile", trailingIcon: Image("delete"), tint: .red) {
                    showAlert = true
                    alertData = .init(title: "Delete?",
                                      message: "All your data will be deleted including your purchases",
                                      buttonTitle: "Delete",
                                      cancelTitle: "Keep the data",
                                      action: .init(closure: {
                        do {
                            try await api.DEBUGdeleteAccount()
                            appRootManager.currentRoot = .authentication
                        } catch {
                            print("Error deleting user: \(error)")
                        }
                    }))
                }
            ]
            
        ]
#if BETA
        if let token = fcmToken.wrappedValue {
            sections.append(
                [
                    .init(title: "Copy push token", trailingIcon: Image("forward")) {
                        UIPasteboard.general.setValue(token,
                                                      forPasteboardType: UTType.plainText.identifier)
                    },
                ]
            )
        }
#endif
        
    }
    
    var body: some View {
        CustomNavView {
            ZStack(alignment: .top) {
                CustomNavLink(isActive: $goToChildren, destination: AddChildView(editingMode: false))
                CustomNavLink(isActive: $goToEmail, destination: EditEmailView(email: api.user?.email ?? ""))
                CustomNavLink(isActive: $goToDOB, destination: EditDOBView(dob: api.user?.dob))
                CustomNavLink(isActive: $goToGender, destination: EditGenderView(gender: api.user?.gender))
                VStack {
                    LinearGradient(colors: [Color.secondary.brand, Color.white, Color.white], startPoint: .init(x: 0.5, y: 0), endPoint: .bottomLeading)
                        .frame(maxWidth: .infinity, maxHeight: 500)
                    Spacer()
                }
                .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            if let image = api.user?.uploadingImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 82, height: 82)
                                    .clipShape(Circle())
                                    .blinking()
                            } else if let photoURL = api.user?.photoURL {
                                WebImage(url: URL(string: photoURL)) { image in
                                    image.resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color.white
                                        .skeleton(with: true, shape: .circle)
                                        .frame(width: 82, height: 82)
                                }
                                .clipShape(.circle)
                                .frame(width: 82, height: 82)
                            } else {
                                Image("avatar")
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(api.user?.name ?? "")
                                    .font(.custom("Poppins-SemiBold", size: 18))
                                    .foregroundStyle(Color.text.black100)
                                if let phone = api.user?.phone, !phone.isEmpty {
                                    Text(phone)
                                        .font(.custom("Poppins-Medium", size: 14))
                                        .foregroundStyle(Color.text.black60)
                                }
                                CustomNavLink(destination: EditBasicInfoView()) {
                                    HStack(alignment: .center, spacing: 3) {
                                        Text("Edit basic info")
                                            .font(.custom("Poppins-Medium", size: 14))
                                        Image("back")
                                            .resizable()
                                            .frame(width: 18, height: 18)
                                            .rotationEffect(.degrees(180))
                                            .padding(.top, 1)
                                    }
                                    .foregroundStyle(Color.primary.brand)
                                }
                            }
                            Spacer()
                        }
                        .padding(.bottom, 34)
                        if showCompleteProfileBanner {
                            CompleteProfileBanner(profileProgress: $profileProgress) {
                                showCompleteProfileBanner = false
                            }
                        }
                        ForEach(sections.indices, id: \.self) { sectionIndex in
                            let section = sections[sectionIndex]
                            VStack(spacing: 0) {
                                ForEach(section.indices, id: \.self) { index in
                                    let row = section[index]
                                    Row(row: row, hideDivider: index == 0)
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 12)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                            )
                        }
#if BETA
                        VStack {
                            Text("Beta build \(Bundle.main.releaseVersionNumber) #\(Bundle.main.buildVersionNumber)")
                                .font(.custom("Poppins-Regular", size: 16))
                        }
#endif
                    }
                    .padding()
                    .padding(.bottom, activeSession.sessionIsActive ? 120 : 60)
                    .customNavBarHidden(true)
                    .customAlert(isActive: $showAlert, data: alertData)
                }
            }
            .animation(.default, value: showCompleteProfileBanner)
            .onChange(of: showAlert, perform: { newValue in
                tabIsShown.wrappedValue = !showAlert
            })
            .onAppear(perform: {
                setupSections()
                tabIsShown.wrappedValue = true
                if let progress = api.user?.profileCompleteness {
                    profileProgress = Double(progress) / 100
                    showCompleteProfileBanner = profileProgress != 1
                }
//                testShowAlert = true
            })
            
        }
    }
    
    struct Row: View {
        var row: RowData
        var hideDivider: Bool = false
        @EnvironmentObject private var api: API
        @State private var loading = false
        @State private var loadedDescription: String = ""
        
        var body: some View {
            VStack(spacing: 0) {
                if !hideDivider {
                    Divider()
                        .background(row.tint != nil ? row.tint! : Color.text.black10)
                        .padding(.horizontal, 16)
                }
                HStack(spacing: 0) {
                    if let leadingIcon = row.leadingIcon {
                        leadingIcon
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(row.tint != nil ? row.tint! : Color.text.black60)
                            .padding(.trailing, 10)
                    }
                    VStack(alignment: .leading) {
                        Text(row.title)
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundStyle(row.tint != nil ? row.tint! : Color.text.black80)
                        if let description = row.description {
                            switch description {
                            case .text(let string):
                                Text(string)
                                    .font(.custom("Poppins-Medium", size: 12))
                                    .foregroundStyle(row.tint != nil ? row.tint! : Color.text.black40)
                            case .request(_):
                                if loading {
                                    Text("")
                                        .skeleton(with: true, shape: .rounded(.radius(6, style: .circular)))
                                        .frame(width: 100, height: 10)
                                        .padding(.top, -4)
                                } else {
                                    Text(loadedDescription)
                                        .font(.custom("Poppins-Medium", size: 12))
                                        .foregroundStyle(row.tint != nil ? row.tint! : Color.text.black40)
                                }
                            }
                        }
                    }
                    Spacer()
                    if let trailingIcon = row.trailingIcon {
                        trailingIcon
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(row.tint != nil ? row.tint! : Color.text.black40)
                    }
                    
                }
                .task {
                    guard let description = row.description else {
                        return
                    }
                    if case let .request(request) = description {
                        loading = true
                        do {
                            let loadedDescription = try await request()
                            await MainActor.run {
                                self.loadedDescription = loadedDescription
                            }
                        } catch {
                            self.loadedDescription = ""
                        }
                        
                        loading = false
                    }
                }
                .padding()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                row.action()
            }
        }
    }
}

struct CompleteProfileBanner: View {
    @Binding var profileProgress: Double
    var onClose: () -> Void
    
    var body: some View {
        HStack {
            if profileProgress == 1 {
                Image("checkmark-circle")
                    .foregroundStyle(.white)
            } else {
                CircularProgressView(progress: $profileProgress)
                    .frame(width: 40, height: 40)
            }
            Spacer()
            VStack(alignment: .leading) {
                Text(profileProgress == 1 ? "Congratulations!" : "Complete your profile")
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundStyle(.white)
                Text(profileProgress == 1 ? "You have successfully completed your profile" : "Fill up a few missing steps to win exciting rewards")
                    .font(.custom("Poppins-Medium", size: 12))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
//            if profileProgress == 1 {
//                Text("Close")
//                    .font(.custom("Poppins-Medium", size: 14))
//                    .foregroundStyle(.white)
//                    .padding(.vertical, 4)
//                    .padding(.horizontal, 12)
//                    .background {
//                        Capsule()
//                            .fill(.white.opacity(0.1))
//                            .clipShape(RoundedRectangle(cornerRadius: 8))
//                    }
//                    .onTapGesture {
//                        onClose()
//                    }
//            } else {
//                Image("arrow-right")
//                    .padding(4)
//                    .background {
//                        Circle()
//                            .fill(.white.opacity(0.1))
//                            .clipShape(RoundedRectangle(cornerRadius: 8))
//                    }
//                    .foregroundStyle(.white)
//            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(LinearGradient(colors: Color.gradient.secondary, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CircularProgressView: View {
    @Binding var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    .white.opacity(0.1),
                    lineWidth: 4
                )
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    .white,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppRootManager())
        .environmentObject(API())
        .environmentObject(ActiveSession())
}

extension Bundle {
    var releaseVersionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    var buildVersionNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}

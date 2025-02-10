import SwiftUI
import SDWebImageSwiftUI

struct EditBasicInfoView: View {
    @EnvironmentObject private var api: API
    @Environment(\.tabIsShown) var tabIsShown
    @State private var showSheet = false
    @State private var showSelectionSheet = false
    @State private var image: UIImage?
    @State private var uploadingImage = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var goToEditName = false
//    @State private var goToEditPhone = false
//    private var phone: String {
//        guard var number = api.user?.phone, !number.isEmpty else {
//            return ""
//        }
//        
//        number.removeFirst(3)
//        return number
//    }
//    
    func row<Content: View>(title: String, showEdit: Bool = true, @ViewBuilder content: () -> Content, editAction: @escaping () -> Void = {}) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title.i18n)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundStyle(Color.text.black80)
                Spacer()
                if showEdit {
                    Button {
                        editAction()
                    } label: {
                        Text("profile_info_edit_cta")
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundStyle(Color.primary.brand)
                    }
                }
            }
            content()
            Divider()
                .background(Color.text.black10)
        }
    }
    
    var body: some View {
        ScrollView {
            CustomNavLink(isActive: $goToEditName, destination: EditNameView(name: api.user?.name ?? "")) {}
//            CustomNavLink(isActive: $goToEditPhone, destination: EditPhoneView(phone: phone)) {}
            VStack(alignment: .leading) {
                row(title: "profile_add_photo_cta") {
                    if let image = image {
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
                                .frame(height: 82)
                        }
                        .clipShape(.circle)
                        .frame(width: 82, height: 82)
                    } else {
                        Image("avatar")
                    }
                } editAction: {
                    showSelectionSheet = true
                }
                .onTapGesture {
                    showSelectionSheet = true
                }
                
                row(title: "profile_info_your_name") {
                    Text(api.user?.name ?? "")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundStyle(Color.text.black80)
                } editAction: {
                    goToEditName = true
                }
                row(title: "user_onboarding_phone_input_hint", showEdit: false) {
                    Text(api.user?.phone)
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundStyle(Color.text.black80)
                }
            }
            .padding()
        }
        .confirmationDialog("", isPresented: $showSelectionSheet, titleVisibility: .hidden) {
            Button("Photo Album") {
                sourceType = .photoLibrary
                showSheet = true
            }
            
            Button("Camera") {
                sourceType = .camera
                showSheet = true
            }
        }
        .onChange(of: image, perform: { newValue in
            guard let image = newValue else {
                return
            }
            uploadingImage = true
            Task {
                do {
                    await MainActor.run {
                        api.user?.uploadingImage = newValue
                    }
                    try await api.uploadUserAvatar(image: image)
                    try await api.refreshUser()
                    await MainActor.run {
                        api.user?.uploadingImage = nil
                        uploadingImage = false
                    }
                } catch {
                    api.user?.uploadingImage = nil
                }
            }
        })
        .sheet(isPresented: $showSheet) {
            ImagePicker(sourceType: sourceType, selectedImage: self.$image)
        }
        .customNavigationTitle("profile_info_title")
        .onAppear(perform: {
            if image == nil {
                image = api.user?.uploadingImage
            }
            tabIsShown.wrappedValue = false
        })
    }
}

#Preview {
    let api = API()
    api.user = .init(id: "id",
                     name: "Test Testesteron",
                     preferredLanguage: "English",
                     phone: "+6544444444",
                     gender: .male,
                     email: nil,
                     photoURL: nil,
                     profileCompleteness: 0)
    return CustomNavView {
        EditBasicInfoView()
            .environmentObject(api)
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
    }
}

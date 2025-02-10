import SwiftUI

struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabIsShown) private var tabIsShown
    @EnvironmentObject private var api: API
    
    @State var children: [Child]
    @State private var childrenToEdit: [Child] = []
    @StateObject private var viewModel = AddChildViewModel()
    var editingMode: Bool = true
    private(set) var onSave: (_ children: [Child]) -> Void
    
    init(children: [Child] = [], editingMode: Bool = true, onSave: @escaping (_: [Child]) -> Void = { _ in }) {
        self.editingMode = editingMode
        self.onSave = onSave
        self.children = editingMode ? [.init(name: "")] + children : children
    }
    
    var allDataFilled: Bool {
        viewModel.children.reduce(true) { valid, model in
            if !valid {
                return valid
            }
            return model.isValid
        }
    }
    
    var body: some View {
        ZStack {
            if viewModel.showError {
                StateView.error {
                    try? await viewModel.fetch()
                }
            } else if !viewModel.loadedData {
                ScrollView {
                    ChildDetailsCard.skeleton.equatable.view
                    ChildDetailsCard.skeleton.equatable.view
                    ChildDetailsCard.skeleton.equatable.view
                }
                .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        VStack(spacing: 10) {
                            ForEach(viewModel.children.indices, id: \.self) { index in
                                var child = viewModel.children[index]
                                if editingMode || child.id == nil || childrenToEdit.contains(where: { $0.id == child.id }) {
                                    EditChildDetailsCard(child: child, index: index) { name, date in
                                        child.name = name
                                        child.dob = date
                                        viewModel.children[index] = child
                                    }
                                } else {
                                    ChildDetailsCard(child: child, index: index) { child in
//                                        viewModel.children.remove(at: index)
                                        childrenToEdit.append(child)
                                    }
                                }
                            }
                            Button {
                                viewModel.children.append(.init(name: ""))
                            } label: {
                                Text("Add another child")
                                    .font(.custom("Roboto-Bold", size: 16))
                                    .foregroundStyle(LinearGradient(colors: Color.gradient.primary, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 16)
                            .buttonStyle(OutlineButton(strokeColor: Color.primary.brand, cornerRadius: 30))

                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.api = api
            viewModel.editingMode = editingMode
            viewModel.children = children
            Task {
                try? await viewModel.fetch()
            }
            tabIsShown.wrappedValue = false
        }
        .customNavigationTitle("profile_add_child_title")
        .customNavTrailingItem {
            AsyncButton(progressTint: Color.primary.brand) {
                let children = await viewModel.save(children: viewModel.children)
                onSave(children)
                dismiss()
            } label: {
                Text("cta_save")
                    .font(.custom("Poppins-Medium", size: 16))
            }
            .disabled(!allDataFilled)
            .tint(Color.primary.brand)
        }
    }
}

struct ChildDetailsCard: View {
    var child: Child
    var index: Int
    var onEdit: (Child) -> Void
    @EnvironmentObject private var api: API
    
    var body: some View {
        VStack {
            if index > 0 {
                Rectangle()
                    .fill(Color.text.black10)
                    .frame(height: 1)
                    .padding(.bottom, 16)
                    .padding(.top, 8)
            }
            HStack {
                Text("profile_child_count".i18n(with: (index + 1).toString))
                    .font(.custom("Poppins-Medium", size: 12))
                    .foregroundStyle(Color.text.black40)
                Spacer()
                AsyncButton(progressTint: .red) {
                    onEdit(child)
                } label: {
                    Image("edit")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color.red)
                }
                .frame(width: 44, height: 20)
//                AsyncButton(progressTint: .red) {
//                    guard let id = child.id else { return }
//                    do {
//                        try await api.deleteChild(with: id)
//                        await MainActor.run {
//                            onDelete(child)
//                        }
//                    } catch {
//                        // fail silently
//                    }
//                } label: {
//                    Image("delete")
//                        .resizable()
//                        .frame(width: 17, height: 17)
//                        .foregroundStyle(Color.red)
//                }
//                .frame(width: 44, height: 20)

            }
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("profile_add_child_name")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundStyle(Color.text.black40)
                    Text(child.name)
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundStyle(Color.text.black100)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("profile_child_age")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundStyle(Color.text.black40)
                    Text("\(child.dob?.yearsBetween() ?? 0)")
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundStyle(Color.text.black100)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            )
        }
    }
}

extension ChildDetailsCard: Skeletonable {
    static var skeleton: any View {
        VStack {
            HStack {
                Text("")
                    .skeleton(with: true, shape: .rounded(.radius(6, style: .circular)))
                    .frame(width: 70, height: 10)
                Spacer()
                Text("")
                    .skeleton(with: true, shape: .rounded(.radius(6, style: .circular)))
                    .frame(width: 20, height: 20)
            }
            Color.white
                .skeleton(with: true, shape: .rounded(.radius(6, style: .circular)))
                .frame(maxWidth: .infinity)
                .frame(height: 100)
        }
    }
}

#Preview {
    ChildDetailsCard(child: .init(name: "Sergey K"), index: 1) { _ in }
}

struct EditChildDetailsCard: View {
    var child: Child
    var index: Int
    var onEdit: (_ name: String, _ dob: Date?) -> Void
    @State var name: String
    @State var dob: Date = .now
    @FocusState private var isKeyboardShowing: Bool
    
    init(child: Child, index: Int, onEdit: @escaping (_: String, _: Date?) -> Void) {
        self.child = child
        self.index = index
        self.onEdit = onEdit
        self.name = child.name
        self.dob = child.dob ?? .now
        self.isKeyboardShowing = isKeyboardShowing
    }
    
    var body: some View {
        VStack {
            HStack {
                Rectangle()
                    .fill(Color.text.black10)
                    .frame(height: 1)
                Text("profile_child_count".i18n(with: (index + 1).toString))
                    .font(.custom("Poppins-Medium", size: 12))
                    .foregroundStyle(Color.text.black40)
                Rectangle()
                    .fill(Color.text.black10)
                    .frame(height: 1)
            }
            VStack(alignment: .leading) {
                Text("profile_add_child_name")
                    .font(.custom("Poppins-Regular", size: 14))
                TextField("", text: $name, prompt: Text("profile_add_child_name_hint")
                    .font(.custom("Poppins-SemiBold", size: 18))
                )
                .font(.custom("Poppins-Medium", size: 18))
                .submitLabel(.done)
                .foregroundStyle(Color.text.black80)
                .onChange(of: name, perform: { newValue in
                    onEdit(newValue, Calendar.current.isDateInToday(dob) ? child.dob : dob)
                })
                //            .onSubmit {
                //                onEdit(name, Calendar.current.isDateInToday(dob) ? child.dob : dob)
                //            }
                Rectangle()
                    .fill(Color.text.black10)
                    .frame(height: 1)
                VStack(alignment: .leading) {
                    Text("profile_settings_date_of_birth")
                        .font(.custom("Poppins-Regular", size: 14))
                    HStack {
                        Text(child.dob != nil ? "\(child.dob!.formatted(date: .numeric, time: .omitted))" : "profile_settings_date_of_birth_hint")
                            .font(.custom("Poppins-Medium", size: child.dob != nil ? 16 : 14))
                            .foregroundStyle(child.dob != nil ? Color.text.black80 : Color.text.black60)
                            .overlay {
                                HStack {
                                    // NOTE: this weirdness is due to the fact that you can't layout a datepicker to take a wider area, nor can you trigger the datepicker programmatically (as of the time of this commit)
                                    DatePicker(
                                        "",
                                        selection: $dob,
                                        in: ...Date(),
                                        displayedComponents: [.date]
                                    )
                                    .blendMode(.destinationOver)
                                    .onChange(of: dob, perform: { value in
                                        onEdit(child.name, dob)
                                    })
                                    DatePicker(
                                        "",
                                        selection: $dob,
                                        in: ...Date(),
                                        displayedComponents: [.date]
                                    )
                                    .blendMode(.destinationOver)
                                    .onChange(of: dob, perform: { value in
                                        onEdit(child.name, dob)
                                    })
                                    DatePicker(
                                        "",
                                        selection: $dob,
                                        in: ...Date(),
                                        displayedComponents: [.date]
                                    )
                                    .blendMode(.destinationOver)
                                    .onChange(of: dob, perform: { value in
                                        onEdit(child.name, dob)
                                    })
                                    DatePicker(
                                        "",
                                        selection: $dob,
                                        in: ...Date(),
                                        displayedComponents: [.date]
                                    )
                                    .blendMode(.destinationOver)
                                    .onChange(of: dob, perform: { value in
                                        onEdit(child.name, dob)
                                    })
                                }
                            }
                        Spacer()
                        Image("chevron-down")
                    }
                    .padding(.vertical, 15)
                    .padding(.leading, 20)
                    .padding(.trailing, 12)
                    .background(RoundedRectangle(cornerRadius: 8)
                        .stroke(style: .init(lineWidth: 1))
                        .foregroundStyle(Color(hex: "#C8C8C8"))
                    )
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            )
        }
    }
}

#Preview {
    CustomNavView {
        AddChildView(children: []) { _ in
            
        }
    }
}

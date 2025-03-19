import SwiftUI

struct EditDOBView: View {
    @EnvironmentObject private var api: API
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabIsShown) private var tabIsShown
    @State var dob: Date?
    @State private var editedDOB: Date = .now
    
    private var latestDOB: Date {
        let currentDate = Date()
        var dateComponent = DateComponents()
        dateComponent.year = -18
        return Calendar.current.date(byAdding: dateComponent, to: currentDate) ?? Date()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("profile_settings_date_of_birth")
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundStyle(Color.text.black80)
            HStack {
                Text(dob != nil ? "\(dob!.formatted(date: .numeric, time: .omitted))" : "profile_settings_date_of_birth_hint")
                    .font(.custom("Poppins-Medium", size: dob != nil ? 16 : 14))
                    .foregroundStyle(dob != nil ? Color.text.black80 : Color.text.black60)
                    .overlay {
                        DatePicker(
                            "",
                            selection: $editedDOB,
                            in: ...latestDOB,
                            displayedComponents: [.date]
                        )
                        .blendMode(.destinationOver)
                    }
                Spacer()
                Image("calendar-empty")
                    .foregroundStyle(Color.text.black60)
            }
            .padding(.vertical, 15)
            .padding(.leading, 20)
            .padding(.trailing, 12)
            .background(RoundedRectangle(cornerRadius: 8)
                .stroke(style: .init(lineWidth: 1))
                .foregroundStyle(Color(hex: "#C8C8C8"))
            )
            .onChange(of: editedDOB, perform: { newValue in
                dob = editedDOB
            })
            Spacer()
            AsyncButton(progressWidth: .infinity) {
                do {
                    let _ = try await api.update(dob: dob)
                    dismiss()
                } catch {
                    self.dob = api.user?.dob ?? dob
                }
            } label: {
                Text("Update")
                    .frame(maxWidth: .infinity)
                    .font(.custom("Roboto-Bold", size: 16))
            }
            .disabled(dob == nil)
            .buttonStyle(PrimaryButton())
        }
        .padding()
        .customNavigationTitle("profile_settings_date_of_birth")
        .onAppear(perform: {
            tabIsShown.wrappedValue = false
        })
    }
}

#Preview {
    EditDOBView(dob: .now)
}

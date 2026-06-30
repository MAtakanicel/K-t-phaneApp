import SwiftUI

struct MemberFormView: View {
    @Bindable var vm: MemberFormViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                Form {
                    // MARK: Kimlik
                    Section {
                        FormTextField(label: "Ad Soyad", text: $vm.fullName,
                                      placeholder: "Ad ve soyad")
                        // D5: memberNumber manuel girilir, otomatik üretilmez
                        FormTextField(label: "Üye No", text: $vm.memberNumber,
                                      placeholder: "Öğrenci / üye numarası")
                    } footer: {
                        Text("Üye numarası kart okutma işlemlerinde kullanılır.")
                            .font(.caption)
                            .foregroundStyle(Color.appTertiary)
                    }

                    // MARK: İletişim
                    Section {
                        FormTextField(label: "E-posta", text: $vm.email,
                                      placeholder: "ornek@uni.edu.tr")
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        FormTextField(label: "Telefon", text: $vm.phone,
                                      placeholder: "0532 000 00 00")
                            .keyboardType(.phonePad)
                    }

                    // MARK: Bölüm
                    Section {
                        FormTextField(label: "Bölüm", text: $vm.department,
                                      placeholder: "Bilgisayar Müh., Matematik…")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(vm.isEditing ? "Üyeyi Düzenle" : "Üye Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") {
                        Task {
                            do {
                                try await vm.save()
                                dismiss()
                            } catch {
                                vm.errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!vm.canSave || vm.isSaving)
                }
            }
            .alert("Hata", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("Tamam") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview("Yeni üye") {
    MemberFormView(vm: MemberFormViewModel(memberRepo: MockMemberRepository()))
}

#Preview("Düzenle") {
    MemberFormView(
        vm: MemberFormViewModel(editingMember: MockData.members[0],
                                memberRepo: MockMemberRepository())
    )
}

#Preview("Karanlık") {
    MemberFormView(vm: MemberFormViewModel(memberRepo: MockMemberRepository()))
        .preferredColorScheme(.dark)
}

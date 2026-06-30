import SwiftUI

// §5.4 — Grouped form satırları.
// Sol etiket (sabit genişlik ~90px) + sağda değer veya TextField.

// Okunur bilgi satırı
struct FormRow: View {
    let label: String
    let value: String
    var placeholder: String = "—"

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(label)
                .font(.listRowSubtitle)
                .foregroundStyle(Color.appSecondary)
                .frame(width: 90, alignment: .leading)
            Text(value.isEmpty ? placeholder : value)
                .font(.bodyValue)
                .foregroundStyle(value.isEmpty ? Color.appTertiary : Color.appLabel)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 44)
    }
}

// Düzenlenebilir TextField satırı
struct FormTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var trailingIcon: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(label)
                .font(.listRowSubtitle)
                .foregroundStyle(Color.appSecondary)
                .frame(width: 90, alignment: .leading)
            TextField(placeholder, text: $text)
                .font(.bodyValue)
                .foregroundStyle(Color.appLabel)
            if let icon = trailingIcon {
                Button {
                    trailingAction?()
                } label: {
                    Image(systemName: icon)
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .frame(minHeight: 46)
    }
}

#Preview {
    Form {
        Section {
            FormRow(label: "Başlık", value: "Suç ve Ceza")
            FormRow(label: "Yazar", value: "Dostoyevski")
            FormRow(label: "ISBN", value: "")
        }
        Section {
            FormTextField(label: "Başlık", text: .constant(""), placeholder: "Kitap adı")
            FormTextField(label: "ISBN", text: .constant("9789750719387"),
                          placeholder: "ISBN", trailingIcon: "barcode.viewfinder") { }
        }
    }
    .scrollContentBackground(.hidden)
    .background(Color.appBg)
}

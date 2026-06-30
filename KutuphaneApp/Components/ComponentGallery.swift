import SwiftUI

// Faz 2 kabul kriteri: tüm bileşenler tek preview'da light + dark görünür.
struct ComponentGallery: View {
    @State private var segSel = 0
    @State private var sheetOpen = false
    @State private var textField = ""

    var body: some View {
        NavigationStack {
            List {
                // MARK: StatusBadge
                Section {
                    HStack(spacing: 8) {
                        StatusBadge(status: .available)
                        StatusBadge(status: .borrowed)
                        StatusBadge(status: .overdue(days: 7))
                    }
                    .padding(.vertical, 4)
                } header: { Text("StatusBadge").sectionHeaderStyle() }

                // MARK: FillIndicator
                Section {
                    HStack(spacing: 8) {
                        FillIndicator(count: 0)
                        FillIndicator(count: 1)
                        FillIndicator(count: 2)
                        FillIndicator(count: 3)
                    }
                    .padding(.vertical, 4)
                } header: { Text("FillIndicator").sectionHeaderStyle() }

                // MARK: CoverPlaceholder + Avatar
                Section {
                    HStack(spacing: 12) {
                        CoverPlaceholder(title: "Suç ve Ceza")
                        CoverPlaceholder(title: "Dune")
                        CoverPlaceholder(title: "Şeker Portakalı")
                        CoverPlaceholder.compact(title: "1984")
                        Spacer()
                        Avatar(name: "Ahmet Yılmaz")
                        Avatar(name: "Zeynep Kaya", size: 48)
                    }
                    .padding(.vertical, 4)
                } header: { Text("Cover & Avatar").sectionHeaderStyle() }

                // MARK: ListRow — Kitap
                Section {
                    BookListRow(book: MockData.books[0])
                    BookListRow(book: MockData.books[1], overdueDays: 3)
                } header: { Text("BookListRow").sectionHeaderStyle() }

                // MARK: ListRow — Üye
                Section {
                    MemberListRow(member: MockData.members[0], loanCount: 1)
                    MemberListRow(member: MockData.members[1], loanCount: 3)
                } header: { Text("MemberListRow").sectionHeaderStyle() }

                // MARK: PrimaryButton
                Section {
                    PrimaryButton(title: "Ödünç Ver") { }
                    PrimaryButton(title: "Onayla (pasif)", isEnabled: false) { }
                } header: { Text("PrimaryButton").sectionHeaderStyle() }

                // MARK: AppSegmentedControl
                Section {
                    AppSegmentedControl(
                        options: ["Hepsi", "Rafta", "Ödünçte"],
                        selection: $segSel
                    )
                    .padding(.vertical, 4)
                } header: { Text("SegmentedControl").sectionHeaderStyle() }

                // MARK: FormRow
                Section {
                    FormRow(label: "Başlık", value: "Suç ve Ceza")
                    FormRow(label: "ISBN", value: "")
                    FormTextField(label: "Üye no", text: $textField,
                                  placeholder: "2024001",
                                  trailingIcon: "barcode.viewfinder") { }
                } header: { Text("FormRow").sectionHeaderStyle() }

                // MARK: EmptyStateView
                Section {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "Henüz kitap eklenmedi",
                        description: "İlk kitabı eklemek için + butonuna dokun.",
                        actionTitle: "Kitap Ekle"
                    ) { }
                } header: { Text("EmptyStateView").sectionHeaderStyle() }

                // MARK: LoadingView / ErrorView
                Section {
                    LoadingView()
                        .frame(height: 80)
                    ErrorView(message: "Bağlantı kurulamadı.") { }
                        .frame(height: 120)
                } header: { Text("Loading & Error (D4)").sectionHeaderStyle() }

                // MARK: ConfirmSheet
                Section {
                    Button("ConfirmSheet'i aç") { sheetOpen = true }
                        .foregroundStyle(Color.appAccent)
                } header: { Text("ConfirmSheet").sectionHeaderStyle() }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBg)
            .navigationTitle("Bileşenler")
        }
        .sheet(isPresented: $sheetOpen) {
            ConfirmSheet(title: "Örnek Sheet", isPresented: $sheetOpen) {
                SheetCard {
                    VStack(alignment: .leading, spacing: 0) {
                        FormRow(label: "Kitap", value: "Suç ve Ceza").padding()
                        Divider()
                        FormRow(label: "Üye", value: "Ahmet Yılmaz").padding()
                    }
                }
                PrimaryButton(title: "Onayla") { sheetOpen = false }
            }
        }
    }
}

#Preview("Light") { ComponentGallery() }
#Preview("Dark")  { ComponentGallery().preferredColorScheme(.dark) }

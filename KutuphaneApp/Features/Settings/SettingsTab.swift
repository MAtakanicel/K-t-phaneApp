import SwiftUI

// MARK: - Üretim entry point

struct SettingsTab: View {
    let store: SettingsStore

    var body: some View {
        SettingsScreen(store: store)
    }
}

// MARK: - Previewlanabilir ekran

struct SettingsScreen: View {
    @Bindable var store: SettingsStore
    @State private var draft: LendingSettings = .default
    @State private var savingTask: Task<Void, Never>? = nil

    private let limitOptions = [1, 2, 3, 4, 5]
    private let durationOptions = [7, 10, 14, 15, 21, 30]

    var body: some View {
        NavigationStack {
            Form {
                librarySection
                lendingRulesSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBg)
            .navigationTitle("Ayarlar")
            .alert("Hata", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("Tamam") { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
        .tint(Color.appAccent)
        .onAppear { draft = store.settings }
        .onChange(of: store.settings) { _, new in draft = new }
    }

    // MARK: - Kütüphane

    private var librarySection: some View {
        Section {
            TextField("Kütüphane adı", text: Binding(
                get: { draft.libraryName },
                set: { draft.libraryName = $0; scheduleSave() }
            ))
            .textInputAutocapitalization(.words)

            TextField("Görevli", text: Binding(
                get: { draft.staffName },
                set: { draft.staffName = $0; scheduleSave() }
            ))
            .textInputAutocapitalization(.words)
        } header: {
            Text("Kütüphane").sectionHeaderStyle()
        }
    }

    // MARK: - Ödünç Kuralları

    private var lendingRulesSection: some View {
        Section {
            Picker(selection: Binding(
                get: { draft.loanLimit },
                set: { draft.loanLimit = $0; scheduleSave() }
            )) {
                ForEach(limitOptions, id: \.self) { n in
                    Text("\(n) kitap").tag(n)
                }
            } label: {
                Text("Üye başına limit")
                    .foregroundStyle(Color.appLabel)
            }

            Picker(selection: Binding(
                get: { draft.loanDurationDays },
                set: { draft.loanDurationDays = $0; scheduleSave() }
            )) {
                ForEach(durationOptions, id: \.self) { n in
                    Text("\(n) gün").tag(n)
                }
            } label: {
                Text("Ödünç süresi")
                    .foregroundStyle(Color.appLabel)
            }

            Toggle(isOn: Binding(
                get: { draft.overdueAlertsEnabled },
                set: { draft.overdueAlertsEnabled = $0; scheduleSave() }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gecikme uyarısı")
                        .foregroundStyle(Color.appLabel)
                    Text("Gecikmiş kitaplar kırmızı rozetle gösterilir.")
                        .font(.listRowSubtitle)
                        .foregroundStyle(Color.appSecondary)
                }
            }
            .tint(Color.appAccent)
        } header: {
            Text("Ödünç Kuralları").sectionHeaderStyle()
        } footer: {
            Text("İade tarihi alma tarihinden \(draft.loanDurationDays) gün sonra hesaplanır.")
                .font(.listRowSubtitle)
                .foregroundStyle(Color.appSecondary)
        }
    }

    // MARK: - Hakkında

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Sürüm")
                    .foregroundStyle(Color.appLabel)
                Spacer()
                Text(appVersion)
                    .foregroundStyle(Color.appSecondary)
            }
        } header: {
            Text("Hakkında").sectionHeaderStyle()
        }
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    // MARK: - Otomatik kaydetme
    // Değişiklikler debounce'lu olarak repo'ya yazılır; ayar değişince
    // LendingSettings.current güncellenir → tüm ekranlar (sayaç, rozet, lending) anında uyum sağlar.

    private func scheduleSave() {
        savingTask?.cancel()
        let snapshot = draft
        savingTask = Task { [store] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            if Task.isCancelled { return }
            await store.update(snapshot)
        }
    }
}

// MARK: - Preview

#Preview("Boş") {
    let store = SettingsStore(repo: MockSettingsRepository())
    store.isLoading = false
    return SettingsScreen(store: store)
}

#Preview("Dolu") {
    let store = SettingsStore(repo: MockSettingsRepository(settings: LendingSettings(
        libraryName: "Yeditepe Üniversitesi Kütüphanesi",
        staffName: "Atakan İçel",
        loanLimit: 3,
        loanDurationDays: 15,
        overdueAlertsEnabled: true
    )))
    store.settings = LendingSettings(
        libraryName: "Yeditepe Üniversitesi Kütüphanesi",
        staffName: "Atakan İçel",
        loanLimit: 3,
        loanDurationDays: 15,
        overdueAlertsEnabled: true
    )
    store.isLoading = false
    return SettingsScreen(store: store)
}

#Preview("Karanlık") {
    let store = SettingsStore(repo: MockSettingsRepository())
    store.isLoading = false
    return SettingsScreen(store: store).preferredColorScheme(.dark)
}

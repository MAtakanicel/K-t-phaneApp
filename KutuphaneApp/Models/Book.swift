import Foundation
import FirebaseFirestore

// D6: borrower, overdueDays gibi türetilmiş alanlar burada YOK — ViewModel hesaplar.
struct Book: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var author: String
    var isbn: String?
    var category: String?
    var shelfLocation: String?
    var coverImageURL: String?

    var status: BookStatus
    var currentBorrowerId: String?   // Aktif ödünçteki üyenin ID'si
    var currentLoanId: String?       // Aktif loan dökümanına referans
    var borrowedDate: Date?

    var createdAt: Date?
    var updatedAt: Date?

    // Hashable: yalnızca id üzerinden — tüm alanların Hashable olmasına gerek yok.
    static func == (lhs: Book, rhs: Book) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

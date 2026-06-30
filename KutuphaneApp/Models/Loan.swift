import Foundation
import FirebaseFirestore

struct Loan: Identifiable, Codable {
    @DocumentID var id: String?
    var bookId: String
    var memberId: String
    var borrowDate: Date
    var dueDate: Date?      // borrowDate + 15 gün → gecikme hesabı için
    var returnDate: Date?   // nil → hâlâ aktif

    // Kitap/üye silinse bile geçmiş okunabilir kalır
    var bookTitleSnapshot: String?
    var memberNameSnapshot: String?
}

extension Loan {
    var isActive: Bool { returnDate == nil }

    var isOverdue: Bool {
        guard isActive, let due = dueDate else { return false }
        return due < Date()
    }
}

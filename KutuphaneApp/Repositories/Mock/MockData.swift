import Foundation

// nonisolated(unsafe): sabit örnek veri, yalnızca okuma amaçlı → tüm context'ten güvenli erişim.
// @MainActor izolasyonu YOK; default isolation'dan bağımsız Sendable sabitler.
enum MockData {
    nonisolated(unsafe) static let books: [Book] = {
        var b1 = Book(title: "Suç ve Ceza", author: "Fyodor Dostoyevski",
                      isbn: "9789750719387", category: "Roman", shelfLocation: "A-12",
                      status: .available, createdAt: Date())
        b1.id = "book-1"

        var b2 = Book(title: "Şeker Portakalı", author: "José Mauro de Vasconcelos",
                      isbn: "9789750719371", category: "Roman", shelfLocation: "B-03",
                      status: .borrowed, currentBorrowerId: "member-1",
                      borrowedDate: Date().addingTimeInterval(-10 * 86400), createdAt: Date())
        b2.id = "book-2"

        var b3 = Book(title: "Dune", author: "Frank Herbert",
                      isbn: "9780441172719", category: "Bilim Kurgu", shelfLocation: "C-07",
                      status: .available, createdAt: Date())
        b3.id = "book-3"

        return [b1, b2, b3]
    }()

    nonisolated(unsafe) static let members: [Member] = {
        var m1 = Member(fullName: "Ahmet Yılmaz", memberNumber: "2024001",
                        email: "ahmet@uni.edu.tr", phone: "0532 111 22 33",
                        department: "Bilgisayar Müh.", createdAt: Date())
        m1.id = "member-1"

        var m2 = Member(fullName: "Zeynep Kaya", memberNumber: "2024002",
                        email: "zeynep@uni.edu.tr",
                        department: "Matematik", createdAt: Date())
        m2.id = "member-2"

        return [m1, m2]
    }()

    nonisolated(unsafe) static let loans: [Loan] = {
        var l1 = Loan(bookId: "book-2", memberId: "member-1",
                      borrowDate: Date().addingTimeInterval(-10 * 86400),
                      dueDate: Date().addingTimeInterval(-3 * 86400),
                      bookTitleSnapshot: "Şeker Portakalı",
                      memberNameSnapshot: "Ahmet Yılmaz")
        l1.id = "loan-1"
        return [l1]
    }()
}

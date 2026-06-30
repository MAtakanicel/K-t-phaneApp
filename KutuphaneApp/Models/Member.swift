import Foundation
import FirebaseFirestore

struct Member: Identifiable, Codable {
    @DocumentID var id: String?
    var fullName: String
    var memberNumber: String   // D5: manuel girilir, otomatik üretilmez
    var email: String?
    var phone: String?
    var department: String?
    var createdAt: Date?
}

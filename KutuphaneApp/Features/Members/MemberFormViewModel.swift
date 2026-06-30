import Foundation

@MainActor
@Observable
final class MemberFormViewModel {
    var fullName: String = ""
    var memberNumber: String = ""   // D5: manuel giriş, otomatik üretilmez
    var email: String = ""
    var phone: String = ""
    var department: String = ""
    var isSaving: Bool = false
    var errorMessage: String? = nil

    let editingMember: Member?
    let memberRepo: any MemberRepository

    init(editingMember: Member? = nil, memberRepo: any MemberRepository) {
        self.editingMember = editingMember
        self.memberRepo = memberRepo
        if let m = editingMember {
            fullName     = m.fullName
            memberNumber = m.memberNumber
            email        = m.email ?? ""
            phone        = m.phone ?? ""
            department   = m.department ?? ""
        }
    }

    var isEditing: Bool { editingMember != nil }
    var canSave: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !memberNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func save() async throws {
        isSaving = true
        defer { isSaving = false }
        if let existing = editingMember {
            var updated = existing
            updated.fullName     = fullName
            updated.memberNumber = memberNumber
            updated.email        = email.isEmpty ? nil : email
            updated.phone        = phone.isEmpty ? nil : phone
            updated.department   = department.isEmpty ? nil : department
            try await memberRepo.updateMember(updated)
        } else {
            let newMember = Member(
                fullName: fullName,
                memberNumber: memberNumber,
                email: email.isEmpty ? nil : email,
                phone: phone.isEmpty ? nil : phone,
                department: department.isEmpty ? nil : department,
                createdAt: Date()
            )
            try await memberRepo.addMember(newMember)
        }
    }
}

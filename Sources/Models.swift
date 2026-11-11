import Foundation
import SwiftData

/// One saved find in the journal: either a species ID or a stump age.
@Model
final class Entry {
    var kind: String        // "species" or "age"
    var title: String
    var subtitle: String
    var detail: String
    var date: Date
    @Attribute(.externalStorage) var photo: Data?

    init(kind: String, title: String, subtitle: String, detail: String, photo: Data?) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.date = Date()
        self.photo = photo
    }
}

import CloudflareKit

enum R2Entry: Hashable, Identifiable {
    case object(R2Object)
    case folder(String)

    var id: String {
        switch self {
        case .object(let object): object.key
        case .folder(let prefix): prefix
        }
    }

    var name: String { id.r2Name }
}

extension String {
    private var r2TrimmedKey: Substring {
        hasSuffix("/") ? dropLast() : self[...]
    }

    var r2Name: String {
        let trimmed = r2TrimmedKey
        guard let slash = trimmed.lastIndex(of: "/") else { return String(trimmed) }
        return String(trimmed[trimmed.index(after: slash)...])
    }

    var r2ParentPrefix: String {
        let trimmed = r2TrimmedKey
        guard let slash = trimmed.lastIndex(of: "/") else { return "" }
        return String(trimmed[...slash])
    }
}

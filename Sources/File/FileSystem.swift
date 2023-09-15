import Foundation

/// Can use the functions of the file system as a key feature of PLFile.
public protocol FileSystem: Equatable, CustomStringConvertible {
    /// Specifies whether it is a function for File or Folder.
    static var type: PLFileType { get }
    /// Store values set within the file system are available.
    var store: Store<Self> { get }
    /// Initializes the Store value.
    init(store: Store<Self>)
}

public extension FileSystem {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.description == rhs.description
    }
    /// FileSystem Description
    var description: String {
        return "(name: \(name), path: \(store.path.rawValue))"
    }
    /// FileSystem URL
    var url: URL {
        return URL(fileURLWithPath: store.path.rawValue)
    }
    /// FileSystem Name
    var name: String {
        return url.pathComponents.last!
    }
    /// File Extension in File System
    var `extension`: String? {
        let components = name.split(separator: ".")
        guard components.count > 1 else { return nil }
        return String(components.last!)
    }
    /// The date when the item at this FileSystem was created
    var creationDate: Date? {
        return store.attributes[.creationDate] as? Date
    }
    /// The date when the item at this FileSystem was last modified
    var modificationDate: Date? {
        return store.attributes[.modificationDate] as? Date
    }
    /// Initalizer path inside FileSystem
    init(path: Path) throws {
        try self.init(store: Store(
            path: path,
            fileManager: .default
        ))
    }
}

public extension FileSystem {
    /// Rename this FileSystem, keeping its exist `extension`
    func rename(to newName: String, keepExtensions: Bool = true) throws {
        var newName = newName
        if keepExtensions {
            `extension`.map {
                newName = newName.appendSafeSuffix(".\($0)")
            }
        }
        try store.move(to: store.path.parents.rawValue)
    }
    /// Move this File System to a new parents Folder
    func move(to newParent: Folder) throws {
        try store.move(to: newParent.store.path.rawValue + name)
    }
    /// Copy the content of this File System to a given folder
    func copy(to folder: Folder) throws -> Self {
        let path = folder.store.path.rawValue + name
        try store.copy(to: path)
        return try Self(path: Path(path))
    }
    /// Delete this FileSystem.
    func delete() throws {
        try store.delete()
    }
    /// FileSystem `FileManager` Setting
    func managedBy(_ manager: FileManager) throws -> Self {
        return try Self(store: Store(
            path: store.path,
            fileManager: manager
        ))
    }
}

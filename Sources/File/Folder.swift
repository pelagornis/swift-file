import Foundation
import Logging

private let logger = Logger(label: "Folder")

/// Folder functionality in PLFile
public struct Folder: FileSystem {
    public var store: Store<Folder>

    public init(store: Store<Folder>) {
        self.store = store
    }
}

extension Folder {
    /// PLFile Folder Type
    public static var type: FileType {
        return .folder
    }

    /// sequence contain all of this folder subfolder
    var subfolders: ChildSequence<Folder> {
        return store.makeChildSequence()
    }
    
    /// sequence contain all of this folder file
    var files: ChildSequence<File> {
        return store.makeChildSequence()
    }
}

extension Folder {

    /// return subfolder at a given path
    public func subfolder(at path: Path) throws -> Folder {
        return try store.subfolder(at: path)
    }

    /// create a new subfolder at a given path
    public func createSubfolder(at path: Path) throws -> Folder {
        return try store.createSubfolder(at: path)
    }

    /// create a new subfolder at a given path if need
    public func createSubfolderIfNeeded(at path: Path) throws -> Folder {
        return try (try? subfolder(at: path)) ?? createSubfolder(at: path)
    }

    /// return a file at a given path with
    public func file(at path: Path) throws -> File {
        return try store.file(at: path)
    }

    /// create a new file at a given path
    public func createFile(at path: Path, contents: Data? = nil) throws -> File {
        return try store.createFile(at: path, contents: contents)
    }

    /// create a new file at a given path if need
    public func createFileIfNeeded(at path: Path, contents: Data? = nil) throws -> File {
        return try (try? file(at: path)) ?? createFile(at: path, contents: contents)
    }

    /// Move the contents of this folder to a new parent
    public func moveContents(to folder: Folder, includeStatus: Bool = false) throws {
        var files = self.files
        var subfolders = subfolders
        files.includeStatus = includeStatus
        subfolders.includeStatus = includeStatus
        try files.move(to: folder)
        try subfolders.move(to: folder)
    }

    /// Empty folder, delete all of Contents
    public func empty(includingStatus: Bool = false) throws {
        var files = self.files
        var subfolders = self.subfolders
        files.includeStatus = includingStatus
        subfolders.includeStatus = includingStatus
        try files.delete()
        try subfolders.delete()
    }
}

// MARK: - Existence
public extension Folder {
    /// Checks if the folder actually exists in the file system.
    func exists() -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: store.path.rawValue, isDirectory: &isDir)
        return exists && isDir.boolValue
    }
}

// MARK: - All Files/Folders
public extension Folder {
    /// Returns all files in the folder (supports recursive search).
    func allFiles(recursive: Bool = false) -> [File] {
        var result: [File] = []
        let sequence = recursive ? self.files.recursiveStatus : self.files
        for file in sequence {
            result.append(file)
        }
        return result
    }

    /// Returns all subfolders in the folder (supports recursive search).
    func allFolders(recursive: Bool = false) -> [Folder] {
        var result: [Folder] = []
        let sequence = recursive ? self.subfolders.recursiveStatus : self.subfolders
        for folder in sequence {
            result.append(folder)
        }
        return result
    }
}
